-- Lead sources master data + CRUD RPC (org-defined — no system defaults)
-- Docs: LEAD-SOURCE-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

CREATE TABLE IF NOT EXISTS public.lead_sources (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  source_code text NOT NULL,
  name text NOT NULL,
  description text,
  sort_order integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'active',
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT lead_sources_status_check CHECK (status IN ('active', 'inactive')),
  CONSTRAINT lead_sources_sort_order_check CHECK (sort_order >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS lead_sources_unique_code_active_idx
  ON public.lead_sources (org_id, lower(trim(source_code)))
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_lead_sources_org_status
  ON public.lead_sources (org_id, status)
  WHERE deleted_at IS NULL;

ALTER TABLE public.lead_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY lead_sources_select ON public.lead_sources FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
  );

CREATE POLICY lead_sources_insert ON public.lead_sources FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

CREATE POLICY lead_sources_update ON public.lead_sources FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

CREATE OR REPLACE FUNCTION public.lead_source_log_snapshot(p_lead_source_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', ls.id,
    'source_code', ls.source_code,
    'name', ls.name,
    'description', ls.description,
    'sort_order', ls.sort_order,
    'status', ls.status,
    'notes', ls.notes
  )
  FROM public.lead_sources ls
  WHERE ls.id = p_lead_source_id
    AND ls.org_id = public.current_org_id()
    AND ls.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.lead_source_deleted_snapshot(p_lead_source_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', ls.id,
    'source_code', ls.source_code,
    'name', ls.name,
    'description', ls.description,
    'sort_order', ls.sort_order,
    'status', ls.status,
    'notes', ls.notes,
    'deleted_at', ls.deleted_at
  )
  FROM public.lead_sources ls
  WHERE ls.id = p_lead_source_id
    AND ls.org_id = public.current_org_id()
    AND ls.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_lead_source(p_payload jsonb)
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

  v_code := trim(p_payload->>'source_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Lead source code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Lead source name required';
  END IF;

  INSERT INTO public.lead_sources (
    org_id,
    source_code,
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

  v_new_data := public.lead_source_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'lead_sources',
    v_id,
    'Created lead source',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_lead_source')
  );

  RETURN v_id;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate lead source code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_lead_source(
  p_lead_source_id uuid,
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

  v_code := trim(p_payload->>'source_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Lead source code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Lead source name required';
  END IF;

  v_old_data := public.lead_source_log_snapshot(p_lead_source_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Lead source not found';
  END IF;

  UPDATE public.lead_sources
  SET
    source_code = v_code,
    name = trim(p_payload->>'name'),
    description = nullif(trim(p_payload->>'description'), ''),
    sort_order = coalesce((p_payload->>'sort_order')::integer, 0),
    status = coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    notes = nullif(trim(p_payload->>'notes'), ''),
    updated_at = now()
  WHERE id = p_lead_source_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Lead source not found';
  END IF;

  v_new_data := public.lead_source_log_snapshot(p_lead_source_id);

  PERFORM public.write_data_change_log(
    'update',
    'lead_sources',
    p_lead_source_id,
    'Updated lead source',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_lead_source')
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate lead source code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.soft_delete_lead_source(p_lead_source_id uuid)
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

  v_old_data := public.lead_source_log_snapshot(p_lead_source_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Lead source not found';
  END IF;

  UPDATE public.lead_sources
  SET
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_lead_source_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Lead source not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'lead_sources',
    p_lead_source_id,
    'Soft deleted lead source',
    v_old_data,
    jsonb_build_object('deleted_at', now()),
    jsonb_build_object('source', 'soft_delete_lead_source', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.restore_lead_source(p_lead_source_id uuid)
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

  v_old_data := public.lead_source_deleted_snapshot(p_lead_source_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Lead source not found or not deleted';
  END IF;

  UPDATE public.lead_sources
  SET
    deleted_at = NULL,
    updated_at = now()
  WHERE id = p_lead_source_id
    AND org_id = v_org_id
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Lead source not found or not deleted';
  END IF;

  v_new_data := public.lead_source_log_snapshot(p_lead_source_id);

  PERFORM public.write_data_change_log(
    'update',
    'lead_sources',
    p_lead_source_id,
    'Restored lead source',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'restore_lead_source', 'restore', true)
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate lead source code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.create_lead_source(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_lead_source(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_lead_source(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.restore_lead_source(uuid) TO authenticated;

NOTIFY pgrst, 'reload schema';
