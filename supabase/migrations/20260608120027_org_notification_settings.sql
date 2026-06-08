-- Settings → Notifications tab: organizations.settings.notifications

CREATE OR REPLACE FUNCTION public.org_notification_defaults()
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'emailNotifications', true,
    'pushNotifications', true,
    'taskReminders', true,
    'paymentAlerts', true,
    'leadAssignments', true,
    'weeklyReport', false
  );
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.get_org_notification_settings()
RETURNS jsonb AS $$
DECLARE
  v_settings jsonb;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT o.settings
  INTO v_settings
  FROM public.organizations o
  WHERE o.id = public.current_org_id();

  RETURN public.org_notification_defaults()
    || COALESCE(v_settings -> 'notifications', '{}'::jsonb);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_org_notification_settings(p_notifications jsonb)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_settings jsonb;
  v_merged jsonb;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_merged := public.org_notification_defaults()
    || COALESCE(p_notifications, '{}'::jsonb);

  SELECT o.settings
  INTO v_settings
  FROM public.organizations o
  WHERE o.id = v_org_id;

  UPDATE public.organizations
  SET
    settings = COALESCE(v_settings, '{}'::jsonb)
      || jsonb_build_object('notifications', v_merged),
    updated_at = now()
  WHERE id = v_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.send_org_notification_email()
RETURNS void AS $$
DECLARE
  v_settings jsonb;
  v_email jsonb;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT o.settings
  INTO v_settings
  FROM public.organizations o
  WHERE o.id = public.current_org_id();

  v_email := v_settings -> 'email';

  IF v_email IS NULL
    OR NULLIF(btrim(v_email ->> 'host'), '') IS NULL
    OR NULLIF(btrim(v_email ->> 'fromAddress'), '') IS NULL
  THEN
    RAISE EXCEPTION 'Email service not configured';
  END IF;

  -- Phase 1: SMTP send not implemented — UI + guard only
  RAISE EXCEPTION 'Send notification email is not available yet';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_org_notification_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_org_notification_settings(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.send_org_notification_email() TO authenticated;

NOTIFY pgrst, 'reload schema';
