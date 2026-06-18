-- Fix lead_sources: drop channel + seed (org defines sources only)
-- Run only if 20260608120056 was applied with channel/seed variant

DROP FUNCTION IF EXISTS public.seed_default_lead_sources(uuid);

ALTER TABLE public.lead_sources DROP CONSTRAINT IF EXISTS lead_sources_channel_check;
ALTER TABLE public.lead_sources DROP COLUMN IF EXISTS channel;

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

NOTIFY pgrst, 'reload schema';
