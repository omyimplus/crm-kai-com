-- Platform roles: owner | admin | employee only (CRM via org_role)
-- Drops: user — pending signup uses employee + is_active=false

UPDATE public.profiles
SET role = 'employee', updated_at = now()
WHERE role = 'user';

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('owner', 'admin', 'employee'));

CREATE OR REPLACE FUNCTION public.is_valid_platform_role(p_role text)
RETURNS boolean AS $$
  SELECT p_role IN ('owner', 'admin', 'employee')
$$ LANGUAGE sql IMMUTABLE;

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

  IF v_role <> 'employee' THEN
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
    CASE WHEN v_is_first THEN 'owner' ELSE 'employee' END,
    v_is_first
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
