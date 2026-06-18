-- Partner master data + CRUD RPC + data_change_logs
-- Docs: PARTNER-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

CREATE TABLE IF NOT EXISTS public.partners (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  partner_code text NOT NULL,
  name text NOT NULL,
  description text,
  sort_order integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'active',
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT partners_status_check CHECK (status IN ('active', 'inactive')),
  CONSTRAINT partners_sort_order_check CHECK (sort_order >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS partners_unique_code_active_idx
  ON public.partners (org_id, lower(trim(partner_code)))
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_partners_org_status
  ON public.partners (org_id, status)
  WHERE deleted_at IS NULL;

ALTER TABLE public.partners ENABLE ROW LEVEL SECURITY;

CREATE POLICY partners_select ON public.partners FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
  );

CREATE POLICY partners_insert ON public.partners FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

CREATE POLICY partners_update ON public.partners FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

CREATE OR REPLACE FUNCTION public.partner_log_snapshot(p_partner_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', u.id,
    'partner_code', u.partner_code,
    'name', u.name,
    'description', u.description,
    'sort_order', u.sort_order,
    'status', u.status,
    'notes', u.notes
  )
  FROM public.partners u
  WHERE u.id = p_partner_id
    AND u.org_id = public.current_org_id()
    AND u.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.partner_deleted_snapshot(p_partner_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', u.id,
    'partner_code', u.partner_code,
    'name', u.name,
    'description', u.description,
    'sort_order', u.sort_order,
    'status', u.status,
    'notes', u.notes,
    'deleted_at', u.deleted_at
  )
  FROM public.partners u
  WHERE u.id = p_partner_id
    AND u.org_id = public.current_org_id()
    AND u.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_partner(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_id uuid;
  v_new_data jsonb;
  v_code text;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_code := trim(p_payload->>'partner_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Partner code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Partner name required';
  END IF;

  INSERT INTO public.partners (
    org_id,
    partner_code,
    name,
    description,
    sort_order,
    status,
    notes,
    created_by
  ) VALUES (
    v_org_id,
    v_code,
    trim(p_payload->>'name'),
    nullif(trim(p_payload->>'description'), ''),
    coalesce((p_payload->>'sort_order')::integer, 0),
    coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    nullif(trim(p_payload->>'notes'), ''),
    auth.uid()
  )
  RETURNING id INTO v_id;

  v_new_data := public.partner_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'partners',
    v_id,
    'Created partner',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_partner')
  );

  RETURN v_id;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate partner code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_partner(
  p_partner_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_code text;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_code := trim(p_payload->>'partner_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Partner code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Partner name required';
  END IF;

  v_old_data := public.partner_log_snapshot(p_partner_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Partner not found';
  END IF;

  UPDATE public.partners
  SET
    partner_code = v_code,
    name = trim(p_payload->>'name'),
    description = nullif(trim(p_payload->>'description'), ''),
    sort_order = coalesce((p_payload->>'sort_order')::integer, 0),
    status = coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    notes = nullif(trim(p_payload->>'notes'), ''),
    updated_at = now()
  WHERE id = p_partner_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Partner not found';
  END IF;

  v_new_data := public.partner_log_snapshot(p_partner_id);

  PERFORM public.write_data_change_log(
    'update',
    'partners',
    p_partner_id,
    'Updated partner',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_partner')
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate partner code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.soft_delete_partner(p_partner_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.partner_log_snapshot(p_partner_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Partner not found';
  END IF;

  UPDATE public.partners
  SET
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_partner_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Partner not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'partners',
    p_partner_id,
    'Soft deleted partner',
    v_old_data,
    jsonb_build_object('deleted_at', now()),
    jsonb_build_object('source', 'soft_delete_partner', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.restore_partner(p_partner_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.partner_deleted_snapshot(p_partner_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Partner not found or not deleted';
  END IF;

  UPDATE public.partners
  SET
    deleted_at = NULL,
    updated_at = now()
  WHERE id = p_partner_id
    AND org_id = v_org_id
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Partner not found or not deleted';
  END IF;

  v_new_data := public.partner_log_snapshot(p_partner_id);

  PERFORM public.write_data_change_log(
    'update',
    'partners',
    p_partner_id,
    'Restored partner',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'restore_partner', 'restore', true)
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate partner code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

NOTIFY pgrst, 'reload schema';
