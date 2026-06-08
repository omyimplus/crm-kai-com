-- Data change audit log — บันทึกทุกครั้งที่ข้อมูลเปลี่ยน (กฎเหล็ก §13)
-- Docs: docs/06-crm-schema/DATA-CHANGE-LOG.md

CREATE TABLE public.data_change_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  actor_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  action text NOT NULL CHECK (action IN ('create', 'update', 'delete')),
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  summary text,
  old_data jsonb,
  new_data jsonb,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_data_change_logs_org_created
  ON public.data_change_logs (org_id, created_at DESC);

CREATE INDEX idx_data_change_logs_entity
  ON public.data_change_logs (org_id, entity_type, entity_id, created_at DESC);

ALTER TABLE public.data_change_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY data_change_logs_select ON public.data_change_logs FOR SELECT
  USING (org_id = public.current_org_id() AND public.is_admin_or_owner());

-- INSERT เฉพาะผ่าน SECURITY DEFINER functions (ไม่มี policy ให้ client insert ตรง)

CREATE OR REPLACE FUNCTION public.write_data_change_log(
  p_action text,
  p_entity_type text,
  p_entity_id uuid,
  p_summary text DEFAULT NULL,
  p_old_data jsonb DEFAULT NULL,
  p_new_data jsonb DEFAULT NULL,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid AS $$
DECLARE
  v_log_id uuid;
  v_org_id uuid;
BEGIN
  IF p_action NOT IN ('create', 'update', 'delete') THEN
    RAISE EXCEPTION 'Invalid action';
  END IF;

  v_org_id := public.current_org_id();
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  INSERT INTO public.data_change_logs (
    org_id,
    actor_id,
    action,
    entity_type,
    entity_id,
    summary,
    old_data,
    new_data,
    metadata
  ) VALUES (
    v_org_id,
    auth.uid(),
    p_action,
    p_entity_type,
    p_entity_id,
    p_summary,
    p_old_data,
    p_new_data,
    COALESCE(p_metadata, '{}'::jsonb)
  )
  RETURNING id INTO v_log_id;

  RETURN v_log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.profile_log_snapshot(p_user_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'full_name', p.full_name,
    'username', p.username,
    'role', p.role,
    'is_active', p.is_active,
    'email', u.email::text
  )
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE p.id = p_user_id;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, auth;

GRANT EXECUTE ON FUNCTION public.write_data_change_log(text, text, uuid, text, jsonb, jsonb, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.profile_log_snapshot(uuid) TO authenticated;

-- Wire system users RPCs to write_data_change_log

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
  p_is_active boolean DEFAULT NULL
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
