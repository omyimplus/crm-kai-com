-- Expose ended_at in list_org_login_sessions for Active Sessions UI

CREATE OR REPLACE FUNCTION public.list_org_login_sessions()
RETURNS TABLE (
  id uuid,
  profile_id uuid,
  full_name text,
  email text,
  device_type text,
  browser text,
  ip_address text,
  logged_in_at timestamptz,
  last_seen_at timestamptz,
  ended_at timestamptz,
  is_active boolean,
  is_online boolean
) AS $$
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  RETURN QUERY
  SELECT
    s.id,
    s.profile_id,
    p.full_name,
    u.email::text,
    s.device_type,
    s.browser,
    s.ip_address,
    s.logged_in_at,
    s.last_seen_at,
    s.ended_at,
    s.is_active,
    (
      s.is_active
      AND s.last_seen_at > now() - interval '30 minutes'
    ) AS is_online
  FROM public.user_login_sessions s
  JOIN public.profiles p ON p.id = s.profile_id
  JOIN auth.users u ON u.id = p.id
  WHERE s.org_id = public.current_org_id()
  ORDER BY s.last_seen_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, auth;

GRANT EXECUTE ON FUNCTION public.list_org_login_sessions() TO authenticated;
