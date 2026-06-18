-- Employee positions master data + CRUD RPC (org-defined — no system defaults)
-- Docs: EMPLOYEE-POSITION-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

CREATE TABLE IF NOT EXISTS public.employee_positions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  position_code text NOT NULL,
  name text NOT NULL,
  description text,
  sort_order integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'active',
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT employee_positions_status_check CHECK (status IN ('active', 'inactive')),
  CONSTRAINT employee_positions_sort_order_check CHECK (sort_order >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS employee_positions_unique_code_active_idx
  ON public.employee_positions (org_id, lower(trim(position_code)))
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_employee_positions_org_status
  ON public.employee_positions (org_id, status)
  WHERE deleted_at IS NULL;

ALTER TABLE public.employee_positions ENABLE ROW LEVEL SECURITY;

CREATE POLICY employee_positions_select ON public.employee_positions FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
  );

CREATE POLICY employee_positions_insert ON public.employee_positions FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

CREATE POLICY employee_positions_update ON public.employee_positions FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

CREATE OR REPLACE FUNCTION public.employee_position_log_snapshot(p_employee_position_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', ls.id,
    'position_code', ls.position_code,
    'name', ls.name,
    'description', ls.description,
    'sort_order', ls.sort_order,
    'status', ls.status,
    'notes', ls.notes
  )
  FROM public.employee_positions ls
  WHERE ls.id = p_employee_position_id
    AND ls.org_id = public.current_org_id()
    AND ls.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.employee_position_deleted_snapshot(p_employee_position_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', ls.id,
    'position_code', ls.position_code,
    'name', ls.name,
    'description', ls.description,
    'sort_order', ls.sort_order,
    'status', ls.status,
    'notes', ls.notes,
    'deleted_at', ls.deleted_at
  )
  FROM public.employee_positions ls
  WHERE ls.id = p_employee_position_id
    AND ls.org_id = public.current_org_id()
    AND ls.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_employee_position(p_payload jsonb)
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

  v_code := trim(p_payload->>'position_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Employee position code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Employee position name required';
  END IF;

  INSERT INTO public.employee_positions (
    org_id,
    position_code,
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

  v_new_data := public.employee_position_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'employee_positions',
    v_id,
    'Created employee position',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_employee_position')
  );

  RETURN v_id;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate employee position code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_employee_position(
  p_employee_position_id uuid,
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

  v_code := trim(p_payload->>'position_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Employee position code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Employee position name required';
  END IF;

  v_old_data := public.employee_position_log_snapshot(p_employee_position_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Employee position not found';
  END IF;

  UPDATE public.employee_positions
  SET
    position_code = v_code,
    name = trim(p_payload->>'name'),
    description = nullif(trim(p_payload->>'description'), ''),
    sort_order = coalesce((p_payload->>'sort_order')::integer, 0),
    status = coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    notes = nullif(trim(p_payload->>'notes'), ''),
    updated_at = now()
  WHERE id = p_employee_position_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Employee position not found';
  END IF;

  v_new_data := public.employee_position_log_snapshot(p_employee_position_id);

  PERFORM public.write_data_change_log(
    'update',
    'employee_positions',
    p_employee_position_id,
    'Updated employee position',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_employee_position')
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate employee position code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.soft_delete_employee_position(p_employee_position_id uuid)
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

  v_old_data := public.employee_position_log_snapshot(p_employee_position_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Employee position not found';
  END IF;

  UPDATE public.employee_positions
  SET
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_employee_position_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Employee position not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'employee_positions',
    p_employee_position_id,
    'Soft deleted employee position',
    v_old_data,
    jsonb_build_object('deleted_at', now()),
    jsonb_build_object('source', 'soft_delete_employee_position', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.restore_employee_position(p_employee_position_id uuid)
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

  v_old_data := public.employee_position_deleted_snapshot(p_employee_position_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Employee position not found or not deleted';
  END IF;

  UPDATE public.employee_positions
  SET
    deleted_at = NULL,
    updated_at = now()
  WHERE id = p_employee_position_id
    AND org_id = v_org_id
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Employee position not found or not deleted';
  END IF;

  v_new_data := public.employee_position_log_snapshot(p_employee_position_id);

  PERFORM public.write_data_change_log(
    'update',
    'employee_positions',
    p_employee_position_id,
    'Restored employee position',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'restore_employee_position', 'restore', true)
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate employee position code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.create_employee_position(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_employee_position(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_employee_position(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.restore_employee_position(uuid) TO authenticated;

NOTIFY pgrst, 'reload schema';
