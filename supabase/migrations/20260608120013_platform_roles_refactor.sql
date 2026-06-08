-- Platform roles: owner | admin | user | employee (CRM menus via org_roles only)
-- Replaces: owner | admin | sales | readonly

-- 1. Migrate existing data before constraint change
UPDATE public.profiles SET role = 'employee', updated_at = now() WHERE role = 'sales';
UPDATE public.profiles SET role = 'user', updated_at = now() WHERE role = 'readonly';

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

ALTER TABLE public.profiles
  ALTER COLUMN role SET DEFAULT 'employee';

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('owner', 'admin', 'user', 'employee'));

-- 2. CRM write access — org_role permissions (owner/admin always write)
CREATE OR REPLACE FUNCTION public.is_valid_platform_role(p_role text)
RETURNS boolean AS $$
  SELECT p_role IN ('owner', 'admin', 'user', 'employee')
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.can_write_crm()
RETURNS boolean AS $$
DECLARE
  v_role text;
  v_perms jsonb;
  v_actions jsonb;
BEGIN
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

CREATE OR REPLACE FUNCTION public.is_readonly()
RETURNS boolean AS $$
  SELECT NOT public.can_write_crm()
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.is_valid_platform_role(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_write_crm() TO authenticated;

-- 3. Signup — first user owner, others employee
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
      ELSE 'employee'
    END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. Admin user RPCs — platform role validation
CREATE OR REPLACE FUNCTION public.admin_create_org_user(
  p_email text,
  p_username text,
  p_password text,
  p_full_name text,
  p_role text DEFAULT 'employee',
  p_is_active boolean DEFAULT true,
  p_org_role_id uuid DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  v_user_id uuid := gen_random_uuid();
  v_org_id uuid := public.current_org_id();
  v_email text := lower(btrim(p_email));
  v_username text := lower(btrim(p_username));
  v_encrypted_pw text;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF v_email IS NULL OR v_email = '' THEN
    RAISE EXCEPTION 'Email is required';
  END IF;

  IF v_username IS NULL OR v_username = '' THEN
    RAISE EXCEPTION 'Username is required';
  END IF;

  IF p_password IS NULL OR length(p_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters';
  END IF;

  IF NOT public.is_valid_platform_role(p_role) THEN
    RAISE EXCEPTION 'Invalid role';
  END IF;

  IF p_role = 'owner' AND public.current_user_role() <> 'owner' THEN
    RAISE EXCEPTION 'Only owner can assign owner role';
  END IF;

  IF p_org_role_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.org_roles
    WHERE id = p_org_role_id
      AND org_id = v_org_id
      AND is_active = true
  ) THEN
    RAISE EXCEPTION 'Invalid org role';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.profiles
    WHERE org_id = v_org_id AND lower(username) = v_username
  ) THEN
    RAISE EXCEPTION 'Username already exists';
  END IF;

  IF EXISTS (SELECT 1 FROM auth.users WHERE lower(email) = v_email) THEN
    RAISE EXCEPTION 'Email already exists';
  END IF;

  v_encrypted_pw := extensions.crypt(p_password, extensions.gen_salt('bf'));

  INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token
  ) VALUES (
    '00000000-0000-0000-0000-000000000000',
    v_user_id,
    'authenticated',
    'authenticated',
    v_email,
    v_encrypted_pw,
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    jsonb_build_object('full_name', p_full_name),
    now(),
    now(),
    ''
  );

  INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
  ) VALUES (
    gen_random_uuid(),
    v_user_id,
    jsonb_build_object('sub', v_user_id::text, 'email', v_email),
    'email',
    v_email,
    now(),
    now(),
    now()
  );

  INSERT INTO public.profiles (id, org_id, full_name, username, role, org_role_id, is_active)
  VALUES (
    v_user_id,
    v_org_id,
    NULLIF(btrim(p_full_name), ''),
    v_username,
    p_role,
    p_org_role_id,
    COALESCE(p_is_active, true)
  );

  PERFORM public.write_data_change_log(
    'create',
    'profiles',
    v_user_id,
    'Created system user',
    NULL,
    public.profile_log_snapshot(v_user_id),
    jsonb_build_object('source', 'admin_create_org_user')
  );

  RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth, extensions;

CREATE OR REPLACE FUNCTION public.admin_update_org_user(
  p_user_id uuid,
  p_full_name text DEFAULT NULL,
  p_username text DEFAULT NULL,
  p_email text DEFAULT NULL,
  p_password text DEFAULT NULL,
  p_role text DEFAULT NULL,
  p_is_active boolean DEFAULT NULL,
  p_org_role_id uuid DEFAULT NULL,
  p_set_org_role boolean DEFAULT false
)
RETURNS void AS $$
DECLARE
  v_target public.profiles%ROWTYPE;
  v_org_id uuid := public.current_org_id();
  v_email text;
  v_username text;
  v_old_data jsonb;
  v_new_data jsonb;
  v_password_changed boolean := false;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT * INTO v_target
  FROM public.profiles
  WHERE id = p_user_id AND org_id = v_org_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  v_old_data := public.profile_log_snapshot(p_user_id);

  IF public.current_user_role() = 'admin' AND v_target.role = 'owner' AND p_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Cannot modify owner';
  END IF;

  IF p_role = 'owner' AND public.current_user_role() <> 'owner' THEN
    RAISE EXCEPTION 'Only owner can assign owner role';
  END IF;

  IF p_role IS NOT NULL AND NOT public.is_valid_platform_role(p_role) THEN
    RAISE EXCEPTION 'Invalid role';
  END IF;

  IF p_set_org_role AND p_org_role_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.org_roles
    WHERE id = p_org_role_id
      AND org_id = v_org_id
      AND is_active = true
  ) THEN
    RAISE EXCEPTION 'Invalid org role';
  END IF;

  IF p_user_id = auth.uid() AND p_is_active = false THEN
    RAISE EXCEPTION 'Cannot deactivate own account';
  END IF;

  IF p_username IS NOT NULL THEN
    v_username := lower(btrim(p_username));
    IF v_username = '' THEN
      RAISE EXCEPTION 'Username is required';
    END IF;
    IF EXISTS (
      SELECT 1 FROM public.profiles
      WHERE org_id = v_org_id
        AND lower(username) = v_username
        AND id <> p_user_id
    ) THEN
      RAISE EXCEPTION 'Username already exists';
    END IF;
  END IF;

  IF p_email IS NOT NULL THEN
    v_email := lower(btrim(p_email));
    IF v_email = '' THEN
      RAISE EXCEPTION 'Email is required';
    END IF;
    IF EXISTS (
      SELECT 1 FROM auth.users
      WHERE lower(email) = v_email AND id <> p_user_id
    ) THEN
      RAISE EXCEPTION 'Email already exists';
    END IF;
  END IF;

  UPDATE public.profiles
  SET
    full_name = COALESCE(NULLIF(btrim(p_full_name), ''), full_name),
    username = COALESCE(v_username, username),
    role = COALESCE(p_role, role),
    org_role_id = CASE
      WHEN p_set_org_role THEN p_org_role_id
      ELSE org_role_id
    END,
    is_active = COALESCE(p_is_active, is_active),
    updated_at = now()
  WHERE id = p_user_id AND org_id = v_org_id;

  IF v_email IS NOT NULL THEN
    UPDATE auth.users
    SET email = v_email, updated_at = now()
    WHERE id = p_user_id;

    UPDATE auth.identities
    SET
      provider_id = v_email,
      identity_data = jsonb_build_object('sub', p_user_id::text, 'email', v_email),
      updated_at = now()
    WHERE user_id = p_user_id AND provider = 'email';
  END IF;

  IF p_password IS NOT NULL AND btrim(p_password) <> '' THEN
    IF length(p_password) < 6 THEN
      RAISE EXCEPTION 'Password must be at least 6 characters';
    END IF;
    UPDATE auth.users
    SET
      encrypted_password = extensions.crypt(p_password, extensions.gen_salt('bf')),
      updated_at = now()
    WHERE id = p_user_id;
    v_password_changed := true;
  END IF;

  v_new_data := public.profile_log_snapshot(p_user_id);
  IF v_password_changed THEN
    v_new_data := v_new_data || jsonb_build_object('password_changed', true);
    v_old_data := v_old_data || jsonb_build_object('password_changed', false);
  END IF;

  PERFORM public.write_data_change_log(
    'update',
    'profiles',
    p_user_id,
    'Updated system user',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'admin_update_org_user')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth, extensions;
