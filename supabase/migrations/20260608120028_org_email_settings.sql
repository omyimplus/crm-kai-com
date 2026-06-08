-- Settings → Email Service tab: organizations.settings.email

CREATE OR REPLACE FUNCTION public.org_email_defaults()
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'enabled', false,
    'host', '',
    'port', 587,
    'username', '',
    'password', '',
    'fromName', '',
    'fromEmail', '',
    'useSslTls', false
  );
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.get_org_email_settings()
RETURNS jsonb AS $$
DECLARE
  v_email jsonb;
  v_has_password boolean;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT o.settings -> 'email'
  INTO v_email
  FROM public.organizations o
  WHERE o.id = public.current_org_id();

  v_email := public.org_email_defaults()
    || COALESCE(v_email, '{}'::jsonb);

  v_has_password := NULLIF(btrim(v_email ->> 'password'), '') IS NOT NULL;

  RETURN (
    v_email
    - 'password'
  ) || jsonb_build_object('hasPassword', v_has_password);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_org_email_settings(p_payload jsonb)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_settings jsonb;
  v_current_email jsonb;
  v_merged jsonb;
  v_password text;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT o.settings, o.settings -> 'email'
  INTO v_settings, v_current_email
  FROM public.organizations o
  WHERE o.id = v_org_id;

  v_merged := public.org_email_defaults()
    || COALESCE(v_current_email, '{}'::jsonb)
    || COALESCE(p_payload, '{}'::jsonb);

  v_password := NULLIF(btrim(p_payload ->> 'password'), '');

  IF v_password IS NULL THEN
    v_merged := v_merged || jsonb_build_object(
      'password', COALESCE(v_current_email ->> 'password', '')
    );
  ELSE
    v_merged := v_merged || jsonb_build_object('password', v_password);
  END IF;

  IF COALESCE((v_merged ->> 'enabled')::boolean, false) THEN
    IF NULLIF(btrim(v_merged ->> 'host'), '') IS NULL THEN
      RAISE EXCEPTION 'SMTP host is required';
    END IF;

    IF NULLIF(btrim(v_merged ->> 'username'), '') IS NULL THEN
      RAISE EXCEPTION 'SMTP username is required';
    END IF;

    IF NULLIF(btrim(v_merged ->> 'fromName'), '') IS NULL THEN
      RAISE EXCEPTION 'From name is required';
    END IF;

    IF NULLIF(btrim(v_merged ->> 'fromEmail'), '') IS NULL THEN
      RAISE EXCEPTION 'From email is required';
    END IF;

    IF NULLIF(btrim(v_merged ->> 'password'), '') IS NULL
      AND NULLIF(btrim(COALESCE(v_current_email ->> 'password', '')), '') IS NULL
    THEN
      RAISE EXCEPTION 'SMTP password is required';
    END IF;

    IF COALESCE((v_merged ->> 'port')::int, 0) < 1
      OR COALESCE((v_merged ->> 'port')::int, 0) > 65535
    THEN
      RAISE EXCEPTION 'Invalid SMTP port';
    END IF;
  END IF;

  UPDATE public.organizations
  SET
    settings = COALESCE(v_settings, '{}'::jsonb)
      || jsonb_build_object('email', v_merged),
    updated_at = now()
  WHERE id = v_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.test_org_email_connection(p_test_recipient text DEFAULT NULL)
RETURNS void AS $$
DECLARE
  v_email jsonb;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT o.settings -> 'email'
  INTO v_email
  FROM public.organizations o
  WHERE o.id = public.current_org_id();

  IF v_email IS NULL
    OR COALESCE((v_email ->> 'enabled')::boolean, false) = false
  THEN
    RAISE EXCEPTION 'Email service is disabled';
  END IF;

  IF NULLIF(btrim(v_email ->> 'host'), '') IS NULL
    OR NULLIF(btrim(v_email ->> 'username'), '') IS NULL
    OR NULLIF(btrim(v_email ->> 'password'), '') IS NULL
    OR NULLIF(btrim(v_email ->> 'fromEmail'), '') IS NULL
  THEN
    RAISE EXCEPTION 'Email service not configured';
  END IF;

  IF p_test_recipient IS NOT NULL AND NULLIF(btrim(p_test_recipient), '') IS NOT NULL THEN
    IF btrim(p_test_recipient) !~ '^[^@]+@[^@]+\.[^@]+$' THEN
      RAISE EXCEPTION 'Invalid test recipient email';
    END IF;
  END IF;

  -- Phase 1: validate stored settings only — SMTP handshake/send later
  RAISE EXCEPTION 'SMTP test send is not available yet';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.send_org_notification_email()
RETURNS void AS $$
DECLARE
  v_email jsonb;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT o.settings -> 'email'
  INTO v_email
  FROM public.organizations o
  WHERE o.id = public.current_org_id();

  IF v_email IS NULL
    OR COALESCE((v_email ->> 'enabled')::boolean, false) = false
    OR NULLIF(btrim(v_email ->> 'host'), '') IS NULL
    OR NULLIF(btrim(v_email ->> 'fromEmail'), '') IS NULL
    OR NULLIF(btrim(v_email ->> 'password'), '') IS NULL
  THEN
    RAISE EXCEPTION 'Email service not configured';
  END IF;

  RAISE EXCEPTION 'Send notification email is not available yet';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_org_email_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_org_email_settings(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.test_org_email_connection(text) TO authenticated;

NOTIFY pgrst, 'reload schema';
