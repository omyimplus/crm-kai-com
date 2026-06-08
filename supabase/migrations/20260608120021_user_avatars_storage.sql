-- Profile avatars: storage bucket + admin_update avatar_url support

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880,
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "Org admins can upload avatars" ON storage.objects;
CREATE POLICY "Org admins can upload avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars'
  AND public.is_admin_or_owner()
  AND (storage.foldername(name))[1] = public.current_org_id()::text
);

DROP POLICY IF EXISTS "Org admins can update avatars" ON storage.objects;
CREATE POLICY "Org admins can update avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND public.is_admin_or_owner()
  AND (storage.foldername(name))[1] = public.current_org_id()::text
);

DROP POLICY IF EXISTS "Org admins can delete avatars" ON storage.objects;
CREATE POLICY "Org admins can delete avatars"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars'
  AND public.is_admin_or_owner()
  AND (storage.foldername(name))[1] = public.current_org_id()::text
);

CREATE OR REPLACE FUNCTION public.profile_log_snapshot(p_user_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'full_name', p.full_name,
    'username', p.username,
    'avatar_url', p.avatar_url,
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

DROP FUNCTION IF EXISTS public.admin_update_org_user(
  uuid, text, text, text, text, text, boolean, uuid[], boolean
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
  p_set_org_roles boolean DEFAULT false,
  p_avatar_url text DEFAULT NULL,
  p_set_avatar boolean DEFAULT false
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
    avatar_url = CASE
      WHEN p_set_avatar THEN NULLIF(btrim(p_avatar_url), '')
      ELSE avatar_url
    END,
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

GRANT EXECUTE ON FUNCTION public.admin_update_org_user(
  uuid, text, text, text, text, text, boolean, uuid[], boolean, text, boolean
) TO authenticated;

NOTIFY pgrst, 'reload schema';
