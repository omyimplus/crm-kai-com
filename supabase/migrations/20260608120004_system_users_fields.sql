-- System users — username + create/update with email & password
-- Fields: full_name, email, username, password, role, status (is_active)

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS username text;

CREATE UNIQUE INDEX IF NOT EXISTS profiles_org_username_unique
  ON public.profiles (org_id, lower(username))
  WHERE username IS NOT NULL AND btrim(username) <> '';

DROP FUNCTION IF EXISTS public.list_org_users();
DROP FUNCTION IF EXISTS public.admin_update_profile(uuid, text, boolean, text);

CREATE OR REPLACE FUNCTION public.list_org_users()
RETURNS TABLE (
  id uuid,
  org_id uuid,
  full_name text,
  username text,
  avatar_url text,
  role text,
  is_active boolean,
  created_at timestamptz,
  updated_at timestamptz,
  email text
) AS $$
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.org_id,
    p.full_name,
    p.username,
    p.avatar_url,
    p.role,
    p.is_active,
    p.created_at,
    p.updated_at,
    u.email::text
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE p.org_id = public.current_org_id()
  ORDER BY p.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, auth;

CREATE OR REPLACE FUNCTION public.admin_create_org_user(
  p_email text,
  p_username text,
  p_password text,
  p_full_name text,
  p_role text DEFAULT 'sales',
  p_is_active boolean DEFAULT true
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

  IF p_role NOT IN ('owner', 'admin', 'sales', 'readonly') THEN
    RAISE EXCEPTION 'Invalid role';
  END IF;

  IF p_role = 'owner' AND public.current_user_role() <> 'owner' THEN
    RAISE EXCEPTION 'Only owner can assign owner role';
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

  INSERT INTO public.profiles (id, org_id, full_name, username, role, is_active)
  VALUES (
    v_user_id,
    v_org_id,
    NULLIF(btrim(p_full_name), ''),
    v_username,
    p_role,
    COALESCE(p_is_active, true)
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
  p_is_active boolean DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_target public.profiles%ROWTYPE;
  v_org_id uuid := public.current_org_id();
  v_email text;
  v_username text;
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

  IF public.current_user_role() = 'admin' AND v_target.role = 'owner' AND p_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Cannot modify owner';
  END IF;

  IF p_role = 'owner' AND public.current_user_role() <> 'owner' THEN
    RAISE EXCEPTION 'Only owner can assign owner role';
  END IF;

  IF p_role IS NOT NULL AND p_role NOT IN ('owner', 'admin', 'sales', 'readonly') THEN
    RAISE EXCEPTION 'Invalid role';
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
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth, extensions;

GRANT EXECUTE ON FUNCTION public.list_org_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_create_org_user(text, text, text, text, text, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_org_user(uuid, text, text, text, text, text, boolean) TO authenticated;
