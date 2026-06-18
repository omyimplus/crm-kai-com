-- Sales teams master data + members (system users) + CRUD RPC
-- Docs: SALES-TEAM-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

CREATE TABLE IF NOT EXISTS public.sales_teams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  team_code text NOT NULL,
  name text NOT NULL,
  description text,
  team_lead_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  sort_order integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'active',
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT sales_teams_status_check CHECK (status IN ('active', 'inactive')),
  CONSTRAINT sales_teams_sort_order_check CHECK (sort_order >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS sales_teams_unique_code_active_idx
  ON public.sales_teams (org_id, lower(trim(team_code)))
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_sales_teams_org_status
  ON public.sales_teams (org_id, status)
  WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS public.sales_team_members (
  sales_team_id uuid NOT NULL REFERENCES public.sales_teams(id) ON DELETE CASCADE,
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (sales_team_id, profile_id)
);

CREATE INDEX IF NOT EXISTS idx_sales_team_members_profile
  ON public.sales_team_members (profile_id);

ALTER TABLE public.sales_teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_team_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY sales_teams_select ON public.sales_teams FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
  );

CREATE POLICY sales_teams_insert ON public.sales_teams FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

CREATE POLICY sales_teams_update ON public.sales_teams FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

CREATE POLICY sales_team_members_select ON public.sales_team_members FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.sales_teams st
      WHERE st.id = sales_team_id
        AND st.org_id = public.current_org_id()
        AND public.is_active_user()
        AND (
          st.deleted_at IS NULL
          OR public.is_admin_or_owner()
        )
    )
  );

CREATE OR REPLACE FUNCTION public.validate_org_active_profiles(p_profile_ids uuid[])
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_profile_id uuid;
  v_unique_ids uuid[];
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  SELECT coalesce(array_agg(DISTINCT rid), '{}'::uuid[])
  INTO v_unique_ids
  FROM unnest(coalesce(p_profile_ids, '{}'::uuid[])) AS rid;

  FOREACH v_profile_id IN ARRAY v_unique_ids
  LOOP
    IF NOT EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = v_profile_id
        AND p.org_id = v_org_id
        AND p.is_active = true
    ) THEN
      RAISE EXCEPTION 'Invalid team member';
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.set_sales_team_members(
  p_team_id uuid,
  p_profile_ids uuid[]
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_unique_ids uuid[];
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.sales_teams st
    WHERE st.id = p_team_id
      AND st.org_id = v_org_id
      AND st.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Sales team not found';
  END IF;

  SELECT coalesce(array_agg(DISTINCT rid), '{}'::uuid[])
  INTO v_unique_ids
  FROM unnest(coalesce(p_profile_ids, '{}'::uuid[])) AS rid;

  PERFORM public.validate_org_active_profiles(v_unique_ids);

  DELETE FROM public.sales_team_members
  WHERE sales_team_id = p_team_id;

  INSERT INTO public.sales_team_members (sales_team_id, profile_id)
  SELECT p_team_id, rid
  FROM unnest(v_unique_ids) AS rid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.sales_team_member_ids(p_team_id uuid)
RETURNS uuid[] AS $$
  SELECT coalesce(array_agg(stm.profile_id ORDER BY stm.created_at), '{}'::uuid[])
  FROM public.sales_team_members stm
  JOIN public.sales_teams st ON st.id = stm.sales_team_id
  WHERE stm.sales_team_id = p_team_id
    AND st.org_id = public.current_org_id();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.sales_team_log_snapshot(p_team_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', st.id,
    'team_code', st.team_code,
    'name', st.name,
    'description', st.description,
    'team_lead_id', st.team_lead_id,
    'sort_order', st.sort_order,
    'status', st.status,
    'notes', st.notes,
    'member_profile_ids', to_jsonb(public.sales_team_member_ids(p_team_id))
  )
  FROM public.sales_teams st
  WHERE st.id = p_team_id
    AND st.org_id = public.current_org_id()
    AND st.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.sales_team_deleted_snapshot(p_team_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', st.id,
    'team_code', st.team_code,
    'name', st.name,
    'description', st.description,
    'team_lead_id', st.team_lead_id,
    'sort_order', st.sort_order,
    'status', st.status,
    'notes', st.notes,
    'member_profile_ids', to_jsonb(public.sales_team_member_ids(p_team_id)),
    'deleted_at', st.deleted_at
  )
  FROM public.sales_teams st
  WHERE st.id = p_team_id
    AND st.org_id = public.current_org_id()
    AND st.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.parse_uuid_array_from_jsonb(p_value jsonb)
RETURNS uuid[] AS $$
  SELECT coalesce(array_agg(elem::uuid), '{}'::uuid[])
  FROM jsonb_array_elements_text(coalesce(p_value, '[]'::jsonb)) AS elem
  WHERE nullif(trim(elem), '') IS NOT NULL;
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.create_sales_team(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_id uuid;
  v_new_data jsonb;
  v_code text;
  v_team_lead_id uuid;
  v_member_ids uuid[];
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_code := trim(p_payload->>'team_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Team code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Team name required';
  END IF;

  v_member_ids := public.parse_uuid_array_from_jsonb(p_payload->'member_profile_ids');
  IF array_length(v_member_ids, 1) IS NULL OR array_length(v_member_ids, 1) < 1 THEN
    RAISE EXCEPTION 'At least one team member required';
  END IF;

  v_team_lead_id := NULLIF(trim(p_payload->>'team_lead_id'), '')::uuid;
  IF v_team_lead_id IS NOT NULL THEN
    PERFORM public.validate_org_active_profiles(ARRAY[v_team_lead_id]);
    IF NOT v_team_lead_id = ANY(v_member_ids) THEN
      v_member_ids := array_append(v_member_ids, v_team_lead_id);
    END IF;
  END IF;

  PERFORM public.validate_org_active_profiles(v_member_ids);

  INSERT INTO public.sales_teams (
    org_id,
    team_code,
    name,
    description,
    team_lead_id,
    sort_order,
    status,
    notes,
    created_by
  ) VALUES (
    v_org_id,
    v_code,
    trim(p_payload->>'name'),
    nullif(trim(p_payload->>'description'), ''),
    v_team_lead_id,
    coalesce((p_payload->>'sort_order')::integer, 0),
    coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    nullif(trim(p_payload->>'notes'), ''),
    auth.uid()
  )
  RETURNING id INTO v_id;

  PERFORM public.set_sales_team_members(v_id, v_member_ids);

  v_new_data := public.sales_team_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'sales_teams',
    v_id,
    'Created sales team',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_sales_team')
  );

  RETURN v_id;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate team code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_sales_team(
  p_team_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_code text;
  v_team_lead_id uuid;
  v_member_ids uuid[];
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.sales_team_log_snapshot(p_team_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Sales team not found';
  END IF;

  v_code := trim(p_payload->>'team_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Team code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Team name required';
  END IF;

  v_member_ids := public.parse_uuid_array_from_jsonb(p_payload->'member_profile_ids');
  IF array_length(v_member_ids, 1) IS NULL OR array_length(v_member_ids, 1) < 1 THEN
    RAISE EXCEPTION 'At least one team member required';
  END IF;

  v_team_lead_id := NULLIF(trim(p_payload->>'team_lead_id'), '')::uuid;
  IF v_team_lead_id IS NOT NULL THEN
    PERFORM public.validate_org_active_profiles(ARRAY[v_team_lead_id]);
    IF NOT v_team_lead_id = ANY(v_member_ids) THEN
      v_member_ids := array_append(v_member_ids, v_team_lead_id);
    END IF;
  END IF;

  PERFORM public.validate_org_active_profiles(v_member_ids);

  UPDATE public.sales_teams
  SET
    team_code = v_code,
    name = trim(p_payload->>'name'),
    description = nullif(trim(p_payload->>'description'), ''),
    team_lead_id = v_team_lead_id,
    sort_order = coalesce((p_payload->>'sort_order')::integer, 0),
    status = coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    notes = nullif(trim(p_payload->>'notes'), ''),
    updated_at = now()
  WHERE id = p_team_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sales team not found';
  END IF;

  PERFORM public.set_sales_team_members(p_team_id, v_member_ids);

  v_new_data := public.sales_team_log_snapshot(p_team_id);

  PERFORM public.write_data_change_log(
    'update',
    'sales_teams',
    p_team_id,
    'Updated sales team',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_sales_team')
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate team code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.soft_delete_sales_team(p_team_id uuid)
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

  v_old_data := public.sales_team_log_snapshot(p_team_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Sales team not found';
  END IF;

  UPDATE public.sales_teams
  SET
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_team_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sales team not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'sales_teams',
    p_team_id,
    'Soft deleted sales team',
    v_old_data,
    jsonb_build_object('deleted_at', now()),
    jsonb_build_object('source', 'soft_delete_sales_team', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.restore_sales_team(p_team_id uuid)
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

  v_old_data := public.sales_team_deleted_snapshot(p_team_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Sales team not found or not deleted';
  END IF;

  UPDATE public.sales_teams
  SET
    deleted_at = NULL,
    updated_at = now()
  WHERE id = p_team_id
    AND org_id = v_org_id
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Sales team not found or not deleted';
  END IF;

  v_new_data := public.sales_team_log_snapshot(p_team_id);

  PERFORM public.write_data_change_log(
    'update',
    'sales_teams',
    p_team_id,
    'Restored sales team',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'restore_sales_team', 'restore', true)
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate team code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.create_sales_team(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_sales_team(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_sales_team(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.restore_sales_team(uuid) TO authenticated;

NOTIFY pgrst, 'reload schema';
