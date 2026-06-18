-- เป้ายอดขาย: เก็บยอดปัจจุบันในตาราง (ยังไม่ผูกดีล Won — Phase ถัดไป)
-- Docs: SALES-TARGET-MASTER-FIELDS.md

ALTER TABLE public.sales_targets
  ADD COLUMN IF NOT EXISTS current_amount numeric(15, 2) NOT NULL DEFAULT 0;

ALTER TABLE public.sales_targets
  DROP CONSTRAINT IF EXISTS sales_targets_current_amount_check;

ALTER TABLE public.sales_targets
  ADD CONSTRAINT sales_targets_current_amount_check CHECK (current_amount >= 0);

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
    'current_amount', st.current_amount,
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
    'current_amount', st.current_amount,
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
  v_current_amount numeric(15, 2);
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

  v_current_amount := coalesce((p_payload->>'current_amount')::numeric, 0);
  IF v_current_amount < 0 THEN
    RAISE EXCEPTION 'Current amount must be >= 0';
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
    current_amount,
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
    v_current_amount,
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
  v_current_amount numeric(15, 2);
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

  v_current_amount := coalesce((p_payload->>'current_amount')::numeric, 0);
  IF v_current_amount < 0 THEN
    RAISE EXCEPTION 'Current amount must be >= 0';
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
    current_amount = v_current_amount,
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
