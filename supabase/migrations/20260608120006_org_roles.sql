-- Organization roles — custom roles assignable to users (Master Data → กำหนด Role)
-- Docs: docs/06-crm-schema/DATA-CHANGE-LOG.md, docs/05-frontend/MASTER-DATA-MENU.md

CREATE TABLE public.org_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  code text NOT NULL,
  label text NOT NULL,
  description text,
  permissions jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_system boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT org_roles_code_format CHECK (code ~ '^[a-z][a-z0-9_]{1,48}$')
);

CREATE UNIQUE INDEX org_roles_org_code_unique
  ON public.org_roles (org_id, code);

CREATE INDEX idx_org_roles_org_active
  ON public.org_roles (org_id, is_active);

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS org_role_id uuid REFERENCES public.org_roles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_org_role_id
  ON public.profiles (org_role_id)
  WHERE org_role_id IS NOT NULL;

ALTER TABLE public.org_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY org_roles_select ON public.org_roles FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND (is_active = true OR public.is_admin_or_owner())
  );

CREATE OR REPLACE FUNCTION public.org_role_log_snapshot(p_role_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'code', r.code,
    'label', r.label,
    'description', r.description,
    'permissions', r.permissions,
    'is_system', r.is_system,
    'is_active', r.is_active
  )
  FROM public.org_roles r
  WHERE r.id = p_role_id;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.list_org_roles()
RETURNS TABLE (
  id uuid,
  org_id uuid,
  code text,
  label text,
  description text,
  permissions jsonb,
  is_system boolean,
  is_active boolean,
  user_count bigint,
  created_at timestamptz,
  updated_at timestamptz
) AS $$
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  RETURN QUERY
  SELECT
    r.id,
    r.org_id,
    r.code,
    r.label,
    r.description,
    r.permissions,
    r.is_system,
    r.is_active,
    COUNT(p.id) AS user_count,
    r.created_at,
    r.updated_at
  FROM public.org_roles r
  LEFT JOIN public.profiles p ON p.org_role_id = r.id
  WHERE r.org_id = public.current_org_id()
  GROUP BY r.id
  ORDER BY r.is_system DESC, r.label ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_org_role(
  p_code text,
  p_label text,
  p_description text DEFAULT NULL,
  p_permissions jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_code text := lower(btrim(p_code));
  v_role_id uuid;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF v_code IS NULL OR v_code = '' THEN
    RAISE EXCEPTION 'Code is required';
  END IF;

  IF v_code !~ '^[a-z][a-z0-9_]{1,48}$' THEN
    RAISE EXCEPTION 'Invalid code format';
  END IF;

  IF NULLIF(btrim(p_label), '') IS NULL THEN
    RAISE EXCEPTION 'Label is required';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.org_roles
    WHERE org_id = v_org_id AND code = v_code
  ) THEN
    RAISE EXCEPTION 'Role code already exists';
  END IF;

  INSERT INTO public.org_roles (org_id, code, label, description, permissions)
  VALUES (
    v_org_id,
    v_code,
    btrim(p_label),
    NULLIF(btrim(p_description), ''),
    COALESCE(p_permissions, '{}'::jsonb)
  )
  RETURNING id INTO v_role_id;

  PERFORM public.write_data_change_log(
    'create',
    'org_roles',
    v_role_id,
    'Created org role',
    NULL,
    public.org_role_log_snapshot(v_role_id),
    jsonb_build_object('source', 'create_org_role')
  );

  RETURN v_role_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_org_role(
  p_role_id uuid,
  p_label text DEFAULT NULL,
  p_description text DEFAULT NULL,
  p_permissions jsonb DEFAULT NULL,
  p_is_active boolean DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.org_roles
    WHERE id = p_role_id AND org_id = v_org_id
  ) THEN
    RAISE EXCEPTION 'Role not found';
  END IF;

  v_old_data := public.org_role_log_snapshot(p_role_id);

  UPDATE public.org_roles
  SET
    label = COALESCE(NULLIF(btrim(p_label), ''), label),
    description = CASE
      WHEN p_description IS NULL THEN description
      ELSE NULLIF(btrim(p_description), '')
    END,
    permissions = COALESCE(p_permissions, permissions),
    is_active = COALESCE(p_is_active, is_active),
    updated_at = now()
  WHERE id = p_role_id AND org_id = v_org_id;

  v_new_data := public.org_role_log_snapshot(p_role_id);

  PERFORM public.write_data_change_log(
    'update',
    'org_roles',
    p_role_id,
    'Updated org role',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_org_role')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Extend profile snapshot + system user RPCs with org_role_id

CREATE OR REPLACE FUNCTION public.profile_log_snapshot(p_user_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'full_name', p.full_name,
    'username', p.username,
    'role', p.role,
    'org_role_id', p.org_role_id,
    'org_role_label', r.label,
    'is_active', p.is_active,
    'email', u.email::text
  )
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  LEFT JOIN public.org_roles r ON r.id = p.org_role_id
  WHERE p.id = p_user_id;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, auth;

DROP FUNCTION IF EXISTS public.list_org_users();

CREATE OR REPLACE FUNCTION public.list_org_users()
RETURNS TABLE (
  id uuid,
  org_id uuid,
  full_name text,
  username text,
  avatar_url text,
  role text,
  org_role_id uuid,
  org_role_label text,
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
    p.org_role_id,
    r.label AS org_role_label,
    p.is_active,
    p.created_at,
    p.updated_at,
    u.email::text
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  LEFT JOIN public.org_roles r ON r.id = p.org_role_id
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

  IF p_role NOT IN ('owner', 'admin', 'sales', 'readonly') THEN
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

  IF p_role IS NOT NULL AND p_role NOT IN ('owner', 'admin', 'sales', 'readonly') THEN
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

GRANT EXECUTE ON FUNCTION public.org_role_log_snapshot(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_org_roles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_org_role(text, text, text, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_org_role(uuid, text, text, jsonb, boolean) TO authenticated;
