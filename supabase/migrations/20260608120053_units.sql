-- Units of measure master data + CRUD RPC + data_change_logs
-- Docs: UNIT-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

CREATE TABLE IF NOT EXISTS public.units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  unit_code text NOT NULL,
  name text NOT NULL,
  description text,
  sort_order integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'active',
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT units_status_check CHECK (status IN ('active', 'inactive')),
  CONSTRAINT units_sort_order_check CHECK (sort_order >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS units_unique_code_active_idx
  ON public.units (org_id, lower(trim(unit_code)))
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_units_org_status
  ON public.units (org_id, status)
  WHERE deleted_at IS NULL;

ALTER TABLE public.units ENABLE ROW LEVEL SECURITY;

CREATE POLICY units_select ON public.units FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
  );

CREATE POLICY units_insert ON public.units FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

CREATE POLICY units_update ON public.units FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

CREATE OR REPLACE FUNCTION public.unit_log_snapshot(p_unit_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', u.id,
    'unit_code', u.unit_code,
    'name', u.name,
    'description', u.description,
    'sort_order', u.sort_order,
    'status', u.status,
    'notes', u.notes
  )
  FROM public.units u
  WHERE u.id = p_unit_id
    AND u.org_id = public.current_org_id()
    AND u.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.unit_deleted_snapshot(p_unit_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', u.id,
    'unit_code', u.unit_code,
    'name', u.name,
    'description', u.description,
    'sort_order', u.sort_order,
    'status', u.status,
    'notes', u.notes,
    'deleted_at', u.deleted_at
  )
  FROM public.units u
  WHERE u.id = p_unit_id
    AND u.org_id = public.current_org_id()
    AND u.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_unit(p_payload jsonb)
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

  v_code := trim(p_payload->>'unit_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Unit code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Unit name required';
  END IF;

  INSERT INTO public.units (
    org_id,
    unit_code,
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

  v_new_data := public.unit_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'units',
    v_id,
    'Created unit',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_unit')
  );

  RETURN v_id;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate unit code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_unit(
  p_unit_id uuid,
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

  v_code := trim(p_payload->>'unit_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Unit code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Unit name required';
  END IF;

  v_old_data := public.unit_log_snapshot(p_unit_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Unit not found';
  END IF;

  UPDATE public.units
  SET
    unit_code = v_code,
    name = trim(p_payload->>'name'),
    description = nullif(trim(p_payload->>'description'), ''),
    sort_order = coalesce((p_payload->>'sort_order')::integer, 0),
    status = coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    notes = nullif(trim(p_payload->>'notes'), ''),
    updated_at = now()
  WHERE id = p_unit_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unit not found';
  END IF;

  v_new_data := public.unit_log_snapshot(p_unit_id);

  PERFORM public.write_data_change_log(
    'update',
    'units',
    p_unit_id,
    'Updated unit',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_unit')
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate unit code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.soft_delete_unit(p_unit_id uuid)
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

  v_old_data := public.unit_log_snapshot(p_unit_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Unit not found';
  END IF;

  UPDATE public.units
  SET
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_unit_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unit not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'units',
    p_unit_id,
    'Soft deleted unit',
    v_old_data,
    jsonb_build_object('deleted_at', now()),
    jsonb_build_object('source', 'soft_delete_unit', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.restore_unit(p_unit_id uuid)
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

  v_old_data := public.unit_deleted_snapshot(p_unit_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Unit not found or not deleted';
  END IF;

  UPDATE public.units
  SET
    deleted_at = NULL,
    updated_at = now()
  WHERE id = p_unit_id
    AND org_id = v_org_id
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Unit not found or not deleted';
  END IF;

  v_new_data := public.unit_log_snapshot(p_unit_id);

  PERFORM public.write_data_change_log(
    'update',
    'units',
    p_unit_id,
    'Restored unit',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'restore_unit', 'restore', true)
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate unit code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

NOTIFY pgrst, 'reload schema';
