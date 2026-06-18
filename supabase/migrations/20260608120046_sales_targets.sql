-- Sales targets master data + CRUD RPC + actual from won deals
-- Docs: SALES-TARGET-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

CREATE TABLE IF NOT EXISTS public.sales_targets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  period_type text NOT NULL,
  period_year integer NOT NULL,
  period_month integer,
  period_quarter integer,
  target_amount numeric(15, 2) NOT NULL DEFAULT 0,
  currency text NOT NULL DEFAULT 'THB',
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT sales_targets_period_type_check CHECK (
    period_type IN ('month', 'quarter', 'year')
  ),
  CONSTRAINT sales_targets_period_year_check CHECK (
    period_year >= 2000 AND period_year <= 2100
  ),
  CONSTRAINT sales_targets_period_month_check CHECK (
    period_month IS NULL OR (period_month >= 1 AND period_month <= 12)
  ),
  CONSTRAINT sales_targets_period_quarter_check CHECK (
    period_quarter IS NULL OR (period_quarter >= 1 AND period_quarter <= 4)
  ),
  CONSTRAINT sales_targets_target_amount_check CHECK (target_amount >= 0),
  CONSTRAINT sales_targets_period_shape_check CHECK (
    (period_type = 'month' AND period_month IS NOT NULL AND period_quarter IS NULL)
    OR (period_type = 'quarter' AND period_quarter IS NOT NULL AND period_month IS NULL)
    OR (period_type = 'year' AND period_month IS NULL AND period_quarter IS NULL)
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS sales_targets_unique_active_period_idx
  ON public.sales_targets (
    org_id,
    profile_id,
    period_type,
    period_year,
    coalesce(period_month, 0),
    coalesce(period_quarter, 0)
  )
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_sales_targets_org_profile
  ON public.sales_targets (org_id, profile_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.sales_targets ENABLE ROW LEVEL SECURITY;

CREATE POLICY sales_targets_select ON public.sales_targets FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
    AND (
      public.is_admin_or_owner()
      OR profile_id = auth.uid()
    )
  );

CREATE POLICY sales_targets_insert ON public.sales_targets FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
    AND public.is_admin_or_owner()
  );

CREATE POLICY sales_targets_update ON public.sales_targets FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
    AND public.is_admin_or_owner()
  )
  WITH CHECK (org_id = public.current_org_id());

CREATE POLICY sales_targets_delete ON public.sales_targets FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
    AND public.is_admin_or_owner()
  )
  WITH CHECK (org_id = public.current_org_id());

CREATE OR REPLACE FUNCTION public.sales_target_period_bounds(
  p_period_type text,
  p_period_year integer,
  p_period_month integer,
  p_period_quarter integer
)
RETURNS TABLE (start_date date, end_date date) AS $$
BEGIN
  IF p_period_type = 'month' THEN
    start_date := make_date(p_period_year, p_period_month, 1);
    end_date := (start_date + interval '1 month' - interval '1 day')::date;
  ELSIF p_period_type = 'quarter' THEN
    start_date := make_date(p_period_year, (p_period_quarter - 1) * 3 + 1, 1);
    end_date := (start_date + interval '3 months' - interval '1 day')::date;
  ELSIF p_period_type = 'year' THEN
    start_date := make_date(p_period_year, 1, 1);
    end_date := make_date(p_period_year, 12, 31);
  ELSE
    RAISE EXCEPTION 'Invalid period type';
  END IF;

  RETURN NEXT;
END;
$$ LANGUAGE plpgsql IMMUTABLE SET search_path = public;

CREATE OR REPLACE FUNCTION public.sales_target_actual_amount(
  p_profile_id uuid,
  p_period_type text,
  p_period_year integer,
  p_period_month integer,
  p_period_quarter integer,
  p_currency text DEFAULT 'THB'
)
RETURNS numeric AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_start date;
  v_end date;
BEGIN
  IF v_org_id IS NULL THEN
    RETURN 0;
  END IF;

  SELECT b.start_date, b.end_date
  INTO v_start, v_end
  FROM public.sales_target_period_bounds(
    p_period_type,
    p_period_year,
    p_period_month,
    p_period_quarter
  ) b;

  RETURN coalesce((
    SELECT sum(d.amount)
    FROM public.deals d
    WHERE d.org_id = v_org_id
      AND d.owner_id = p_profile_id
      AND d.status = 'won'
      AND d.deleted_at IS NULL
      AND d.currency = coalesce(nullif(trim(p_currency), ''), 'THB')
      AND d.closed_at IS NOT NULL
      AND d.closed_at::date >= v_start
      AND d.closed_at::date <= v_end
  ), 0);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.compute_sales_target_actuals(p_target_ids uuid[])
RETURNS TABLE (target_id uuid, actual_amount numeric) AS $$
BEGIN
  IF p_target_ids IS NULL OR array_length(p_target_ids, 1) IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    st.id,
    public.sales_target_actual_amount(
      st.profile_id,
      st.period_type,
      st.period_year,
      st.period_month,
      st.period_quarter,
      st.currency
    )
  FROM public.sales_targets st
  WHERE st.id = ANY(p_target_ids)
    AND st.org_id = public.current_org_id();
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.sales_target_log_snapshot(p_target_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', st.id,
    'profile_id', st.profile_id,
    'period_type', st.period_type,
    'period_year', st.period_year,
    'period_month', st.period_month,
    'period_quarter', st.period_quarter,
    'target_amount', st.target_amount,
    'currency', st.currency,
    'notes', st.notes
  )
  FROM public.sales_targets st
  WHERE st.id = p_target_id
    AND st.org_id = public.current_org_id()
    AND st.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.sales_target_deleted_snapshot(p_target_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', st.id,
    'profile_id', st.profile_id,
    'period_type', st.period_type,
    'period_year', st.period_year,
    'period_month', st.period_month,
    'period_quarter', st.period_quarter,
    'target_amount', st.target_amount,
    'currency', st.currency,
    'notes', st.notes,
    'deleted_at', st.deleted_at
  )
  FROM public.sales_targets st
  WHERE st.id = p_target_id
    AND st.org_id = public.current_org_id()
    AND st.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_sales_target(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_profile_id uuid;
  v_period_type text;
  v_period_year integer;
  v_period_month integer;
  v_period_quarter integer;
  v_target_amount numeric(15, 2);
  v_currency text;
  v_id uuid;
  v_new_data jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() OR NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_profile_id := NULLIF(trim(p_payload->>'profile_id'), '')::uuid;
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Assignee required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = v_profile_id
      AND p.org_id = v_org_id
      AND p.is_active = true
  ) THEN
    RAISE EXCEPTION 'Assignee not found';
  END IF;

  v_period_type := nullif(trim(p_payload->>'period_type'), '');
  IF v_period_type NOT IN ('month', 'quarter', 'year') THEN
    RAISE EXCEPTION 'Invalid period type';
  END IF;

  v_period_year := (p_payload->>'period_year')::integer;
  IF v_period_year IS NULL OR v_period_year < 2000 OR v_period_year > 2100 THEN
    RAISE EXCEPTION 'Invalid period year';
  END IF;

  v_period_month := NULLIF(trim(p_payload->>'period_month'), '')::integer;
  v_period_quarter := NULLIF(trim(p_payload->>'period_quarter'), '')::integer;

  IF v_period_type = 'month' AND v_period_month IS NULL THEN
    RAISE EXCEPTION 'Month required';
  ELSIF v_period_type = 'quarter' AND v_period_quarter IS NULL THEN
    RAISE EXCEPTION 'Quarter required';
  ELSIF v_period_type = 'year' THEN
    v_period_month := NULL;
    v_period_quarter := NULL;
  END IF;

  v_target_amount := coalesce((p_payload->>'target_amount')::numeric, 0);
  IF v_target_amount < 0 THEN
    RAISE EXCEPTION 'Target amount must be >= 0';
  END IF;

  v_currency := coalesce(nullif(trim(p_payload->>'currency'), ''), 'THB');

  INSERT INTO public.sales_targets (
    org_id,
    profile_id,
    period_type,
    period_year,
    period_month,
    period_quarter,
    target_amount,
    currency,
    notes,
    created_by
  ) VALUES (
    v_org_id,
    v_profile_id,
    v_period_type,
    v_period_year,
    v_period_month,
    v_period_quarter,
    v_target_amount,
    v_currency,
    nullif(trim(p_payload->>'notes'), ''),
    auth.uid()
  )
  RETURNING id INTO v_id;

  v_new_data := public.sales_target_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'sales_targets',
    v_id,
    'Created sales target',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_sales_target')
  );

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_sales_target(
  p_target_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_profile_id uuid;
  v_period_type text;
  v_period_year integer;
  v_period_month integer;
  v_period_quarter integer;
  v_target_amount numeric(15, 2);
  v_currency text;
  v_old_data jsonb;
  v_new_data jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() OR NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.sales_target_log_snapshot(p_target_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Sales target not found';
  END IF;

  v_profile_id := NULLIF(trim(p_payload->>'profile_id'), '')::uuid;
  IF v_profile_id IS NULL THEN
    RAISE EXCEPTION 'Assignee required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = v_profile_id
      AND p.org_id = v_org_id
      AND p.is_active = true
  ) THEN
    RAISE EXCEPTION 'Assignee not found';
  END IF;

  v_period_type := nullif(trim(p_payload->>'period_type'), '');
  IF v_period_type NOT IN ('month', 'quarter', 'year') THEN
    RAISE EXCEPTION 'Invalid period type';
  END IF;

  v_period_year := (p_payload->>'period_year')::integer;
  IF v_period_year IS NULL OR v_period_year < 2000 OR v_period_year > 2100 THEN
    RAISE EXCEPTION 'Invalid period year';
  END IF;

  v_period_month := NULLIF(trim(p_payload->>'period_month'), '')::integer;
  v_period_quarter := NULLIF(trim(p_payload->>'period_quarter'), '')::integer;

  IF v_period_type = 'month' AND v_period_month IS NULL THEN
    RAISE EXCEPTION 'Month required';
  ELSIF v_period_type = 'quarter' AND v_period_quarter IS NULL THEN
    RAISE EXCEPTION 'Quarter required';
  ELSIF v_period_type = 'year' THEN
    v_period_month := NULL;
    v_period_quarter := NULL;
  END IF;

  v_target_amount := coalesce((p_payload->>'target_amount')::numeric, 0);
  IF v_target_amount < 0 THEN
    RAISE EXCEPTION 'Target amount must be >= 0';
  END IF;

  v_currency := coalesce(nullif(trim(p_payload->>'currency'), ''), 'THB');

  UPDATE public.sales_targets
  SET
    profile_id = v_profile_id,
    period_type = v_period_type,
    period_year = v_period_year,
    period_month = v_period_month,
    period_quarter = v_period_quarter,
    target_amount = v_target_amount,
    currency = v_currency,
    notes = nullif(trim(p_payload->>'notes'), ''),
    updated_at = now()
  WHERE id = p_target_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sales target not found';
  END IF;

  v_new_data := public.sales_target_log_snapshot(p_target_id);

  PERFORM public.write_data_change_log(
    'update',
    'sales_targets',
    p_target_id,
    'Updated sales target',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_sales_target')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.soft_delete_sales_target(p_target_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() OR NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.sales_target_log_snapshot(p_target_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Sales target not found';
  END IF;

  UPDATE public.sales_targets
  SET
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_target_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sales target not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'sales_targets',
    p_target_id,
    'Soft-deleted sales target',
    v_old_data,
    NULL,
    jsonb_build_object('source', 'soft_delete_sales_target', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.restore_sales_target(p_target_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() OR NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.sales_target_deleted_snapshot(p_target_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Sales target not found or not deleted';
  END IF;

  UPDATE public.sales_targets
  SET
    deleted_at = NULL,
    updated_at = now()
  WHERE id = p_target_id
    AND org_id = v_org_id
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sales target not found or not deleted';
  END IF;

  v_new_data := public.sales_target_log_snapshot(p_target_id);

  PERFORM public.write_data_change_log(
    'update',
    'sales_targets',
    p_target_id,
    'Restored sales target',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'restore_sales_target', 'restore', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT SELECT, INSERT, UPDATE ON public.sales_targets TO authenticated;
GRANT EXECUTE ON FUNCTION public.sales_target_period_bounds(text, integer, integer, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sales_target_actual_amount(uuid, text, integer, integer, integer, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.compute_sales_target_actuals(uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sales_target_log_snapshot(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.sales_target_deleted_snapshot(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_sales_target(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_sales_target(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_sales_target(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.restore_sales_target(uuid) TO authenticated;
