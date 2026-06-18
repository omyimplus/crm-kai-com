-- Module statuses master data + CRUD RPC (org-defined statuses per module)
-- Docs: MODULE-STATUS-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

CREATE TABLE IF NOT EXISTS public.module_statuses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  module_key text NOT NULL,
  status_code text NOT NULL,
  name text NOT NULL,
  description text,
  color text,
  sort_order integer NOT NULL DEFAULT 0,
  is_default boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'active',
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT module_statuses_module_key_check CHECK (
    module_key IN (
      'customer', 'contact', 'lead', 'opportunity', 'pipeline',
      'quotations', 'salesOrder', 'invoices', 'projects',
      'contractAgreements', 'service'
    )
  ),
  CONSTRAINT module_statuses_record_status_check CHECK (status IN ('active', 'inactive')),
  CONSTRAINT module_statuses_sort_order_check CHECK (sort_order >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS module_statuses_unique_code_active_idx
  ON public.module_statuses (org_id, module_key, lower(trim(status_code)))
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_module_statuses_org_module
  ON public.module_statuses (org_id, module_key, sort_order)
  WHERE deleted_at IS NULL;

ALTER TABLE public.module_statuses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS module_statuses_select ON public.module_statuses;
CREATE POLICY module_statuses_select ON public.module_statuses FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
  );

DROP POLICY IF EXISTS module_statuses_insert ON public.module_statuses;
CREATE POLICY module_statuses_insert ON public.module_statuses FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

DROP POLICY IF EXISTS module_statuses_update ON public.module_statuses;
CREATE POLICY module_statuses_update ON public.module_statuses FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

CREATE OR REPLACE FUNCTION public.clear_module_status_default(
  p_module_key text,
  p_exclude_id uuid DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  UPDATE public.module_statuses
  SET
    is_default = false,
    updated_at = now()
  WHERE org_id = public.current_org_id()
    AND module_key = p_module_key
    AND deleted_at IS NULL
    AND (p_exclude_id IS NULL OR id <> p_exclude_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.module_status_log_snapshot(p_module_status_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', ms.id,
    'module_key', ms.module_key,
    'status_code', ms.status_code,
    'name', ms.name,
    'description', ms.description,
    'color', ms.color,
    'sort_order', ms.sort_order,
    'is_default', ms.is_default,
    'status', ms.status,
    'notes', ms.notes
  )
  FROM public.module_statuses ms
  WHERE ms.id = p_module_status_id
    AND ms.org_id = public.current_org_id()
    AND ms.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.module_status_deleted_snapshot(p_module_status_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', ms.id,
    'module_key', ms.module_key,
    'status_code', ms.status_code,
    'name', ms.name,
    'description', ms.description,
    'color', ms.color,
    'sort_order', ms.sort_order,
    'is_default', ms.is_default,
    'status', ms.status,
    'notes', ms.notes,
    'deleted_at', ms.deleted_at
  )
  FROM public.module_statuses ms
  WHERE ms.id = p_module_status_id
    AND ms.org_id = public.current_org_id()
    AND ms.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_module_status(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_id uuid;
  v_new_data jsonb;
  v_code text;
  v_module_key text;
  v_is_default boolean;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_module_key := nullif(trim(p_payload->>'module_key'), '');
  IF v_module_key IS NULL THEN
    RAISE EXCEPTION 'Module required';
  END IF;

  v_code := trim(p_payload->>'status_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Status code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Status name required';
  END IF;

  v_is_default := coalesce((p_payload->>'is_default')::boolean, false);

  INSERT INTO public.module_statuses (
    org_id,
    module_key,
    status_code,
    name,
    description,
    color,
    sort_order,
    is_default,
    status,
    notes,
    created_by
  ) VALUES (
    v_org_id,
    v_module_key,
    v_code,
    trim(p_payload->>'name'),
    nullif(trim(p_payload->>'description'), ''),
    nullif(trim(p_payload->>'color'), ''),
    coalesce((p_payload->>'sort_order')::integer, 0),
    v_is_default,
    coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    nullif(trim(p_payload->>'notes'), ''),
    auth.uid()
  )
  RETURNING id INTO v_id;

  IF v_is_default THEN
    PERFORM public.clear_module_status_default(v_module_key, v_id);
    UPDATE public.module_statuses
    SET is_default = true
    WHERE id = v_id;
  END IF;

  v_new_data := public.module_status_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'module_statuses',
    v_id,
    'Created module status',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_module_status')
  );

  RETURN v_id;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate status code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_module_status(
  p_module_status_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_code text;
  v_module_key text;
  v_is_default boolean;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.module_status_log_snapshot(p_module_status_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Module status not found';
  END IF;

  v_module_key := nullif(trim(p_payload->>'module_key'), '');
  IF v_module_key IS NULL THEN
    RAISE EXCEPTION 'Module required';
  END IF;

  v_code := trim(p_payload->>'status_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Status code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Status name required';
  END IF;

  v_is_default := coalesce((p_payload->>'is_default')::boolean, false);

  UPDATE public.module_statuses
  SET
    module_key = v_module_key,
    status_code = v_code,
    name = trim(p_payload->>'name'),
    description = nullif(trim(p_payload->>'description'), ''),
    color = nullif(trim(p_payload->>'color'), ''),
    sort_order = coalesce((p_payload->>'sort_order')::integer, 0),
    is_default = v_is_default,
    status = coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    notes = nullif(trim(p_payload->>'notes'), ''),
    updated_at = now()
  WHERE id = p_module_status_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Module status not found';
  END IF;

  IF v_is_default THEN
    PERFORM public.clear_module_status_default(v_module_key, p_module_status_id);
    UPDATE public.module_statuses
    SET is_default = true
    WHERE id = p_module_status_id;
  END IF;

  v_new_data := public.module_status_log_snapshot(p_module_status_id);

  PERFORM public.write_data_change_log(
    'update',
    'module_statuses',
    p_module_status_id,
    'Updated module status',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_module_status')
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate status code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.soft_delete_module_status(p_module_status_id uuid)
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

  v_old_data := public.module_status_log_snapshot(p_module_status_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Module status not found';
  END IF;

  UPDATE public.module_statuses
  SET
    is_default = false,
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_module_status_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Module status not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'module_statuses',
    p_module_status_id,
    'Soft deleted module status',
    v_old_data,
    jsonb_build_object('deleted_at', now()),
    jsonb_build_object('source', 'soft_delete_module_status', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.restore_module_status(p_module_status_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_row public.module_statuses%ROWTYPE;
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

  v_old_data := public.module_status_deleted_snapshot(p_module_status_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Module status not found or not deleted';
  END IF;

  UPDATE public.module_statuses
  SET
    deleted_at = NULL,
    updated_at = now()
  WHERE id = p_module_status_id
    AND org_id = v_org_id
    AND deleted_at IS NOT NULL
  RETURNING * INTO v_row;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Module status not found or not deleted';
  END IF;

  IF v_row.is_default THEN
    PERFORM public.clear_module_status_default(v_row.module_key, v_row.id);
    UPDATE public.module_statuses
    SET is_default = true
    WHERE id = v_row.id;
  END IF;

  v_new_data := public.module_status_log_snapshot(p_module_status_id);

  PERFORM public.write_data_change_log(
    'update',
    'module_statuses',
    p_module_status_id,
    'Restored module status',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'restore_module_status', 'restore', true)
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate status code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.create_module_status(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_module_status(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_module_status(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.restore_module_status(uuid) TO authenticated;

NOTIFY pgrst, 'reload schema';
