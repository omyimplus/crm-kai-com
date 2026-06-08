-- RLS helpers and policies — Phase 1
-- Source: docs/06-crm-schema/permissions.md

CREATE OR REPLACE FUNCTION public.current_org_id()
RETURNS uuid AS $$
  SELECT org_id FROM public.profiles WHERE id = auth.uid()
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS text AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid()
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_readonly()
RETURNS boolean AS $$
  SELECT COALESCE(public.current_user_role(), '') = 'readonly'
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- Signup: attach profile to demo org (Phase 1)
CREATE OR REPLACE FUNCTION public.signup_profile(p_full_name text)
RETURNS void AS $$
DECLARE
  v_org_id uuid;
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
  INSERT INTO public.profiles (id, org_id, full_name, role)
  VALUES (
    auth.uid(),
    v_org_id,
    p_full_name,
    CASE
      WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE org_id = v_org_id) THEN 'owner'
      ELSE 'sales'
    END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.signup_profile(text) TO authenticated;

-- Enable RLS
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pipelines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pipeline_stages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.deal_stage_history ENABLE ROW LEVEL SECURITY;

-- organizations
CREATE POLICY org_select ON public.organizations FOR SELECT
  USING (id = public.current_org_id());

CREATE POLICY org_update ON public.organizations FOR UPDATE
  USING (id = public.current_org_id() AND NOT public.is_readonly())
  WITH CHECK (id = public.current_org_id());

-- profiles
CREATE POLICY profiles_select ON public.profiles FOR SELECT
  USING (org_id = public.current_org_id());

CREATE POLICY profiles_update_own ON public.profiles FOR UPDATE
  USING (id = auth.uid() AND org_id = public.current_org_id() AND NOT public.is_readonly())
  WITH CHECK (id = auth.uid() AND org_id = public.current_org_id());

-- companies
CREATE POLICY companies_select ON public.companies FOR SELECT
  USING (org_id = public.current_org_id() AND deleted_at IS NULL);

CREATE POLICY companies_insert ON public.companies FOR INSERT
  WITH CHECK (org_id = public.current_org_id() AND NOT public.is_readonly());

CREATE POLICY companies_update ON public.companies FOR UPDATE
  USING (org_id = public.current_org_id() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

CREATE POLICY companies_delete ON public.companies FOR UPDATE
  USING (org_id = public.current_org_id() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

-- contacts
CREATE POLICY contacts_select ON public.contacts FOR SELECT
  USING (org_id = public.current_org_id() AND deleted_at IS NULL);

CREATE POLICY contacts_insert ON public.contacts FOR INSERT
  WITH CHECK (org_id = public.current_org_id() AND NOT public.is_readonly());

CREATE POLICY contacts_update ON public.contacts FOR UPDATE
  USING (org_id = public.current_org_id() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

-- pipelines & stages (read all in org; write if not readonly)
CREATE POLICY pipelines_select ON public.pipelines FOR SELECT
  USING (org_id = public.current_org_id());

CREATE POLICY pipelines_write ON public.pipelines FOR ALL
  USING (org_id = public.current_org_id() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

CREATE POLICY stages_select ON public.pipeline_stages FOR SELECT
  USING (org_id = public.current_org_id());

CREATE POLICY stages_write ON public.pipeline_stages FOR ALL
  USING (org_id = public.current_org_id() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

-- deals
CREATE POLICY deals_select ON public.deals FOR SELECT
  USING (org_id = public.current_org_id() AND deleted_at IS NULL);

CREATE POLICY deals_insert ON public.deals FOR INSERT
  WITH CHECK (org_id = public.current_org_id() AND NOT public.is_readonly());

CREATE POLICY deals_update ON public.deals FOR UPDATE
  USING (org_id = public.current_org_id() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

-- activities
CREATE POLICY activities_select ON public.activities FOR SELECT
  USING (org_id = public.current_org_id());

CREATE POLICY activities_write ON public.activities FOR ALL
  USING (org_id = public.current_org_id() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

-- deal_stage_history (read + insert via trigger)
CREATE POLICY history_select ON public.deal_stage_history FOR SELECT
  USING (org_id = public.current_org_id());

CREATE POLICY history_insert ON public.deal_stage_history FOR INSERT
  WITH CHECK (org_id = public.current_org_id());
