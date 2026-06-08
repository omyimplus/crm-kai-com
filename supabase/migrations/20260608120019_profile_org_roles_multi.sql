-- Multiple team roles (org_roles) per user via profile_org_roles junction
-- Permissions merge: union of actions per module across all assigned roles

CREATE TABLE IF NOT EXISTS public.profile_org_roles (
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  org_role_id uuid NOT NULL REFERENCES public.org_roles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (profile_id, org_role_id)
);

CREATE INDEX IF NOT EXISTS idx_profile_org_roles_org_role_id
  ON public.profile_org_roles (org_role_id);

INSERT INTO public.profile_org_roles (profile_id, org_role_id)
SELECT p.id, p.org_role_id
FROM public.profiles p
WHERE p.org_role_id IS NOT NULL
ON CONFLICT DO NOTHING;

ALTER TABLE public.profile_org_roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profile_org_roles_select ON public.profile_org_roles;

CREATE POLICY profile_org_roles_select ON public.profile_org_roles FOR SELECT
  USING (
    profile_id = auth.uid()
    OR public.is_admin_or_owner()
  );

CREATE OR REPLACE FUNCTION public.merge_org_role_permissions(p_permissions jsonb[])
RETURNS jsonb AS $$
DECLARE
  v_result jsonb := '{}'::jsonb;
  v_perm jsonb;
  v_key text;
  v_actions jsonb;
  v_existing jsonb;
  v_combined jsonb;
BEGIN
  IF p_permissions IS NULL OR array_length(p_permissions, 1) IS NULL THEN
    RETURN NULL;
  END IF;

  FOREACH v_perm IN ARRAY p_permissions
  LOOP
    IF v_perm IS NULL THEN
      CONTINUE;
    END IF;

    v_perm := public.normalize_org_role_permissions(v_perm);

    FOR v_key, v_actions IN SELECT * FROM jsonb_each(v_perm)
    LOOP
      v_existing := COALESCE(v_result -> v_key, '[]'::jsonb);

      SELECT COALESCE(jsonb_agg(DISTINCT val ORDER BY val), '[]'::jsonb)
      INTO v_combined
      FROM (
        SELECT jsonb_array_elements_text(v_existing) AS val
        UNION
        SELECT jsonb_array_elements_text(v_actions) AS val
      ) merged;

      v_result := jsonb_set(v_result, ARRAY[v_key], v_combined, true);
    END LOOP;
  END LOOP;

  IF v_result = '{}'::jsonb THEN
    RETURN NULL;
  END IF;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.set_profile_org_roles(
  p_profile_id uuid,
  p_org_role_ids uuid[]
)
RETURNS void AS $$
DECLARE
  v_org_id uuid;
  v_role_id uuid;
  v_unique_ids uuid[];
BEGIN
  SELECT org_id INTO v_org_id
  FROM public.profiles
  WHERE id = p_profile_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Profile not found';
  END IF;

  SELECT COALESCE(array_agg(DISTINCT rid), '{}'::uuid[])
  INTO v_unique_ids
  FROM unnest(COALESCE(p_org_role_ids, '{}'::uuid[])) AS rid;

  FOREACH v_role_id IN ARRAY v_unique_ids
  LOOP
    IF NOT EXISTS (
      SELECT 1 FROM public.org_roles
      WHERE id = v_role_id
        AND org_id = v_org_id
        AND is_active = true
    ) THEN
      RAISE EXCEPTION 'Invalid org role';
    END IF;
  END LOOP;

  DELETE FROM public.profile_org_roles
  WHERE profile_id = p_profile_id;

  INSERT INTO public.profile_org_roles (profile_id, org_role_id)
  SELECT p_profile_id, rid
  FROM unnest(v_unique_ids) AS rid;

  UPDATE public.profiles
  SET
    org_role_id = CASE
      WHEN array_length(v_unique_ids, 1) > 0 THEN v_unique_ids[1]
      ELSE NULL
    END,
    updated_at = now()
  WHERE id = p_profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.get_my_org_role_permissions()
RETURNS jsonb AS $$
  SELECT public.merge_org_role_permissions(
    ARRAY(
      SELECT public.normalize_org_role_permissions(r.permissions)
      FROM public.profile_org_roles por
      JOIN public.org_roles r ON r.id = por.org_role_id
      WHERE por.profile_id = auth.uid()
        AND r.is_active = true
    )
  );
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

  IF v_role <> 'employee' THEN
    RETURN false;
  END IF;

  v_perms := public.get_my_org_role_permissions();

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

CREATE OR REPLACE FUNCTION public.profile_log_snapshot(p_user_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'full_name', p.full_name,
    'username', p.username,
    'role', p.role,
    'org_role_ids', COALESCE((
      SELECT jsonb_agg(por.org_role_id ORDER BY r.label)
      FROM public.profile_org_roles por
      JOIN public.org_roles r ON r.id = por.org_role_id
      WHERE por.profile_id = p_user_id
    ), '[]'::jsonb),
    'org_role_labels', COALESCE((
      SELECT jsonb_agg(r.label ORDER BY r.label)
      FROM public.profile_org_roles por
      JOIN public.org_roles r ON r.id = por.org_role_id
      WHERE por.profile_id = p_user_id
    ), '[]'::jsonb),
    'is_active', p.is_active,
    'email', u.email::text
  )
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
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
  org_role_ids uuid[],
  org_role_labels text[],
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
    COALESCE((
      SELECT array_agg(por.org_role_id ORDER BY r.label)
      FROM public.profile_org_roles por
      JOIN public.org_roles r ON r.id = por.org_role_id
      WHERE por.profile_id = p.id
    ), '{}'::uuid[]) AS org_role_ids,
    COALESCE((
      SELECT array_agg(r.label ORDER BY r.label)
      FROM public.profile_org_roles por
      JOIN public.org_roles r ON r.id = por.org_role_id
      WHERE por.profile_id = p.id
    ), '{}'::text[]) AS org_role_labels,
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
    public.normalize_org_role_permissions(r.permissions) AS permissions,
    r.is_system,
    r.is_active,
    COUNT(DISTINCT por.profile_id) AS user_count,
    r.created_at,
    r.updated_at
  FROM public.org_roles r
  LEFT JOIN public.profile_org_roles por ON por.org_role_id = r.id
  WHERE r.org_id = public.current_org_id()
  GROUP BY r.id
  ORDER BY r.is_system DESC, r.label ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.delete_org_role(p_role_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_role public.org_roles%ROWTYPE;
  v_old_data jsonb;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT * INTO v_role
  FROM public.org_roles
  WHERE id = p_role_id AND org_id = v_org_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Role not found';
  END IF;

  IF v_role.is_system THEN
    RAISE EXCEPTION 'Cannot delete system role';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.profile_org_roles
    WHERE org_role_id = p_role_id
  ) THEN
    RAISE EXCEPTION 'Role has assigned users';
  END IF;

  v_old_data := public.org_role_log_snapshot(p_role_id);

  DELETE FROM public.org_roles
  WHERE id = p_role_id AND org_id = v_org_id;

  PERFORM public.write_data_change_log(
    'delete',
    'org_roles',
    p_role_id,
    'Deleted org role',
    v_old_data,
    NULL,
    jsonb_build_object('source', 'delete_org_role')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP FUNCTION IF EXISTS public.admin_create_org_user(
  text, text, text, text, text, boolean, uuid
);

CREATE OR REPLACE FUNCTION public.admin_create_org_user(
  p_email text,
  p_username text,
  p_password text,
  p_full_name text,
  p_role text DEFAULT 'employee',
  p_is_active boolean DEFAULT true,
  p_org_role_ids uuid[] DEFAULT '{}'::uuid[]
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
    NULL,
    COALESCE(p_is_active, true)
  );

  PERFORM public.set_profile_org_roles(v_user_id, p_org_role_ids);

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

DROP FUNCTION IF EXISTS public.admin_update_org_user(
  uuid, text, text, text, text, text, boolean, uuid, boolean
);

CREATE OR REPLACE FUNCTION public.admin_update_org_user(
  p_user_id uuid,
  p_full_name text DEFAULT NULL,
  p_username text DEFAULT NULL,
  p_email text DEFAULT NULL,
  p_password text DEFAULT NULL,
  p_role text DEFAULT NULL,
  p_is_active boolean DEFAULT NULL,
  p_org_role_ids uuid[] DEFAULT '{}'::uuid[],
  p_set_org_roles boolean DEFAULT false
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

  IF p_set_org_roles THEN
    PERFORM public.set_profile_org_roles(p_user_id, p_org_role_ids);
  END IF;

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

GRANT EXECUTE ON FUNCTION public.merge_org_role_permissions(jsonb[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_profile_org_roles(uuid, uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_org_roles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_org_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_create_org_user(text, text, text, text, text, boolean, uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_org_user(uuid, text, text, text, text, text, boolean, uuid[], boolean) TO authenticated;

-- Refresh PostgREST schema cache (fixes "Could not find the function ... in the schema cache")
NOTIFY pgrst, 'reload schema';
