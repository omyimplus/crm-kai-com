-- Self-signup: pending user until admin approves + assigns org role
-- First org member stays owner (bootstrap)

CREATE OR REPLACE FUNCTION public.is_active_user()
RETURNS boolean AS $$
  SELECT COALESCE(
    (SELECT is_active FROM public.profiles WHERE id = auth.uid()),
    false
  )
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.can_write_crm()
RETURNS boolean AS $$
DECLARE
  v_role text;
  v_perms jsonb;
  v_actions jsonb;
BEGIN
  IF NOT public.is_active_user() THEN
    RETURN false;
  END IF;

  v_role := public.current_user_role();

  IF v_role IN ('owner', 'admin') THEN
    RETURN true;
  END IF;

  IF v_role NOT IN ('user', 'employee') THEN
    RETURN false;
  END IF;

  SELECT public.normalize_org_role_permissions(r.permissions)
  INTO v_perms
  FROM public.profiles p
  JOIN public.org_roles r ON r.id = p.org_role_id
  WHERE p.id = auth.uid()
    AND r.is_active = true;

  IF v_perms IS NULL THEN
    RETURN false;
  END IF;

  FOR v_actions IN SELECT value FROM jsonb_each(v_perms)
  LOOP
    IF v_actions ?| ARRAY['create', 'edit', 'delete'] THEN
      RETURN true;
    END IF;
  END LOOP;

  RETURN false;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.signup_profile(p_full_name text)
RETURNS void AS $$
DECLARE
  v_org_id uuid;
  v_is_first boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid()) THEN
    RAISE EXCEPTION 'Profile already exists';
  END IF;

  SELECT id INTO v_org_id FROM public.organizations WHERE slug = 'demo' LIMIT 1;
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Demo organization not found. Run seed.';
  END IF;

  SELECT NOT EXISTS (SELECT 1 FROM public.profiles WHERE org_id = v_org_id)
  INTO v_is_first;

  INSERT INTO public.profiles (id, org_id, full_name, role, is_active)
  VALUES (
    auth.uid(),
    v_org_id,
    NULLIF(btrim(p_full_name), ''),
    CASE WHEN v_is_first THEN 'owner' ELSE 'user' END,
    v_is_first
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.is_active_user() TO authenticated;

-- CRM data: inactive users cannot read/write (own profile excepted below)
DROP POLICY IF EXISTS org_update ON public.organizations;
CREATE POLICY org_update ON public.organizations FOR UPDATE
  USING (id = public.current_org_id() AND public.is_active_user() AND NOT public.is_readonly())
  WITH CHECK (id = public.current_org_id());

DROP POLICY IF EXISTS profiles_select ON public.profiles;
CREATE POLICY profiles_select ON public.profiles FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND (public.is_active_user() OR id = auth.uid())
  );

DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own ON public.profiles FOR UPDATE
  USING (id = auth.uid() AND org_id = public.current_org_id())
  WITH CHECK (id = auth.uid() AND org_id = public.current_org_id());

DROP POLICY IF EXISTS companies_select ON public.companies;
CREATE POLICY companies_select ON public.companies FOR SELECT
  USING (org_id = public.current_org_id() AND deleted_at IS NULL AND public.is_active_user());

DROP POLICY IF EXISTS companies_insert ON public.companies;
CREATE POLICY companies_insert ON public.companies FOR INSERT
  WITH CHECK (org_id = public.current_org_id() AND public.is_active_user() AND NOT public.is_readonly());

DROP POLICY IF EXISTS companies_update ON public.companies;
CREATE POLICY companies_update ON public.companies FOR UPDATE
  USING (org_id = public.current_org_id() AND public.is_active_user() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

DROP POLICY IF EXISTS companies_delete ON public.companies;
CREATE POLICY companies_delete ON public.companies FOR UPDATE
  USING (org_id = public.current_org_id() AND public.is_active_user() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

DROP POLICY IF EXISTS contacts_select ON public.contacts;
CREATE POLICY contacts_select ON public.contacts FOR SELECT
  USING (org_id = public.current_org_id() AND deleted_at IS NULL AND public.is_active_user());

DROP POLICY IF EXISTS contacts_insert ON public.contacts;
CREATE POLICY contacts_insert ON public.contacts FOR INSERT
  WITH CHECK (org_id = public.current_org_id() AND public.is_active_user() AND NOT public.is_readonly());

DROP POLICY IF EXISTS contacts_update ON public.contacts;
CREATE POLICY contacts_update ON public.contacts FOR UPDATE
  USING (org_id = public.current_org_id() AND public.is_active_user() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

DROP POLICY IF EXISTS pipelines_select ON public.pipelines;
CREATE POLICY pipelines_select ON public.pipelines FOR SELECT
  USING (org_id = public.current_org_id() AND public.is_active_user());

DROP POLICY IF EXISTS pipelines_write ON public.pipelines;
CREATE POLICY pipelines_write ON public.pipelines FOR ALL
  USING (org_id = public.current_org_id() AND public.is_active_user() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

DROP POLICY IF EXISTS stages_select ON public.pipeline_stages;
CREATE POLICY stages_select ON public.pipeline_stages FOR SELECT
  USING (org_id = public.current_org_id() AND public.is_active_user());

DROP POLICY IF EXISTS stages_write ON public.pipeline_stages;
CREATE POLICY stages_write ON public.pipeline_stages FOR ALL
  USING (org_id = public.current_org_id() AND public.is_active_user() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

DROP POLICY IF EXISTS deals_select ON public.deals;
CREATE POLICY deals_select ON public.deals FOR SELECT
  USING (org_id = public.current_org_id() AND deleted_at IS NULL AND public.is_active_user());

DROP POLICY IF EXISTS deals_insert ON public.deals;
CREATE POLICY deals_insert ON public.deals FOR INSERT
  WITH CHECK (org_id = public.current_org_id() AND public.is_active_user() AND NOT public.is_readonly());

DROP POLICY IF EXISTS deals_update ON public.deals;
CREATE POLICY deals_update ON public.deals FOR UPDATE
  USING (org_id = public.current_org_id() AND public.is_active_user() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

DROP POLICY IF EXISTS activities_select ON public.activities;
CREATE POLICY activities_select ON public.activities FOR SELECT
  USING (org_id = public.current_org_id() AND public.is_active_user());

DROP POLICY IF EXISTS activities_write ON public.activities;
CREATE POLICY activities_write ON public.activities FOR ALL
  USING (org_id = public.current_org_id() AND public.is_active_user() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

DROP POLICY IF EXISTS history_select ON public.deal_stage_history;
CREATE POLICY history_select ON public.deal_stage_history FOR SELECT
  USING (org_id = public.current_org_id() AND public.is_active_user());

DROP POLICY IF EXISTS history_insert ON public.deal_stage_history;
CREATE POLICY history_insert ON public.deal_stage_history FOR INSERT
  WITH CHECK (org_id = public.current_org_id() AND public.is_active_user());
