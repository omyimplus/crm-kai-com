-- Fix "Database error querying schema" on login for admin-created users
-- GoTrue requires auth.users token columns to be '' not NULL
-- https://github.com/supabase/auth/issues/1940

UPDATE auth.users
SET
  confirmation_token = COALESCE(confirmation_token, ''),
  recovery_token = COALESCE(recovery_token, ''),
  email_change_token_new = COALESCE(email_change_token_new, ''),
  email_change = COALESCE(email_change, '')
WHERE confirmation_token IS NULL
   OR recovery_token IS NULL
   OR email_change_token_new IS NULL
   OR email_change IS NULL;

CREATE OR REPLACE FUNCTION public.resolve_login_email(p_identifier text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_id text := lower(btrim(p_identifier));
  v_email text;
  v_count bigint;
BEGIN
  IF v_id IS NULL OR v_id = '' THEN
    RETURN NULL;
  END IF;

  IF position('@' in v_id) > 0 THEN
    SELECT u.email::text
    INTO v_email
    FROM auth.users u
    WHERE lower(u.email::text) = v_id
    LIMIT 1;

    RETURN v_email;
  END IF;

  SELECT count(*), min(u.email::text)
  INTO v_count, v_email
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE lower(p.username) = v_id
    AND p.username IS NOT NULL
    AND btrim(p.username) <> '';

  IF v_count = 1 THEN
    RETURN v_email;
  END IF;

  RETURN NULL;
END;
$$;

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
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change
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
    '',
    '',
    '',
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

REVOKE ALL ON FUNCTION public.resolve_login_email(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_login_email(text) TO anon, authenticated;
