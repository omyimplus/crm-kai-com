-- Login session log for Setup → Active Sessions (device, browser, IP, last seen)

CREATE TABLE public.user_login_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  device_type text NOT NULL DEFAULT 'unknown'
    CHECK (device_type IN ('desktop', 'mobile', 'tablet', 'unknown')),
  browser text NOT NULL DEFAULT 'unknown',
  ip_address text,
  user_agent text,
  logged_in_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_user_login_sessions_org_last_seen
  ON public.user_login_sessions (org_id, last_seen_at DESC);

CREATE INDEX idx_user_login_sessions_profile_active
  ON public.user_login_sessions (profile_id, is_active)
  WHERE is_active = true;

ALTER TABLE public.user_login_sessions ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.record_user_login_session(
  p_device_type text,
  p_browser text,
  p_ip_address text DEFAULT NULL,
  p_user_agent text DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_device text := lower(btrim(COALESCE(p_device_type, 'unknown')));
  v_browser text := NULLIF(btrim(p_browser), '');
  v_session_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization';
  END IF;

  IF v_device NOT IN ('desktop', 'mobile', 'tablet', 'unknown') THEN
    v_device := 'unknown';
  END IF;

  UPDATE public.user_login_sessions
  SET
    is_active = false,
    ended_at = COALESCE(ended_at, now())
  WHERE profile_id = auth.uid()
    AND is_active = true;

  INSERT INTO public.user_login_sessions (
    org_id,
    profile_id,
    device_type,
    browser,
    ip_address,
    user_agent
  )
  VALUES (
    v_org_id,
    auth.uid(),
    v_device,
    COALESCE(v_browser, 'unknown'),
    NULLIF(btrim(p_ip_address), ''),
    NULLIF(btrim(p_user_agent), '')
  )
  RETURNING id INTO v_session_id;

  RETURN v_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.touch_user_login_session(p_session_id uuid)
RETURNS void AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.user_login_sessions
  SET last_seen_at = now()
  WHERE id = p_session_id
    AND profile_id = auth.uid()
    AND is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.end_user_login_session(p_session_id uuid)
RETURNS void AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.user_login_sessions
  SET
    is_active = false,
    ended_at = COALESCE(ended_at, now())
  WHERE id = p_session_id
    AND profile_id = auth.uid()
    AND is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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

GRANT EXECUTE ON FUNCTION public.record_user_login_session(text, text, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.touch_user_login_session(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.end_user_login_session(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_org_login_sessions() TO authenticated;
