-- System users admin (Setup) — list org users with email + admin update profile
-- Source: docs/05-frontend/SETUP-MENU.md § System Users

CREATE OR REPLACE FUNCTION public.is_admin_or_owner()
RETURNS boolean AS $$
  SELECT COALESCE(public.current_user_role(), '') IN ('owner', 'admin')
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.list_org_users()
RETURNS TABLE (
  id uuid,
  org_id uuid,
  full_name text,
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
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.admin_update_profile(
  p_user_id uuid,
  p_role text DEFAULT NULL,
  p_is_active boolean DEFAULT NULL,
  p_full_name text DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_target public.profiles%ROWTYPE;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF p_role IS NOT NULL AND p_role NOT IN ('owner', 'admin', 'sales', 'readonly') THEN
    RAISE EXCEPTION 'Invalid role';
  END IF;

  SELECT * INTO v_target
  FROM public.profiles
  WHERE id = p_user_id AND org_id = public.current_org_id();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User not found';
  END IF;

  IF public.current_user_role() = 'admin' AND v_target.role = 'owner' AND p_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Cannot modify owner';
  END IF;

  IF p_role = 'owner' AND public.current_user_role() <> 'owner' THEN
    RAISE EXCEPTION 'Only owner can assign owner role';
  END IF;

  IF p_user_id = auth.uid() AND p_is_active = false THEN
    RAISE EXCEPTION 'Cannot deactivate own account';
  END IF;

  UPDATE public.profiles
  SET
    role = COALESCE(p_role, role),
    is_active = COALESCE(p_is_active, is_active),
    full_name = COALESCE(NULLIF(trim(p_full_name), ''), full_name),
    updated_at = now()
  WHERE id = p_user_id AND org_id = public.current_org_id();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.is_admin_or_owner() TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_org_users() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_profile(uuid, text, boolean, text) TO authenticated;
