-- Settings → Auth Providers tab: organizations.settings.authProviders

CREATE OR REPLACE FUNCTION public.org_auth_provider_defaults()
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'microsoft365', jsonb_build_object(
      'enabled', false,
      'clientId', '',
      'clientSecret', '',
      'tenantId', 'common',
      'allowedDomains', ''
    ),
    'google', jsonb_build_object(
      'enabled', false,
      'clientId', '',
      'clientSecret', '',
      'tenantId', '',
      'allowedDomains', ''
    ),
    'azureAd', jsonb_build_object(
      'enabled', false,
      'clientId', '',
      'clientSecret', '',
      'tenantId', '',
      'allowedDomains', ''
    ),
    'usernamePassword', jsonb_build_object(
      'enabled', true
    )
  );
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public._sanitize_auth_provider_for_client(p_provider jsonb)
RETURNS jsonb AS $$
DECLARE
  v_has_secret boolean;
BEGIN
  v_has_secret := NULLIF(btrim(p_provider ->> 'clientSecret'), '') IS NOT NULL;

  RETURN (
    p_provider - 'clientSecret'
  ) || jsonb_build_object('hasClientSecret', v_has_secret);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.get_org_auth_providers()
RETURNS jsonb AS $$
DECLARE
  v_root jsonb;
  v_defaults jsonb := public.org_auth_provider_defaults();
  v_merged jsonb;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT o.settings -> 'authProviders'
  INTO v_root
  FROM public.organizations o
  WHERE o.id = public.current_org_id();

  v_merged := v_defaults || COALESCE(v_root, '{}'::jsonb);

  RETURN jsonb_build_object(
    'microsoft365', public._sanitize_auth_provider_for_client(v_merged -> 'microsoft365'),
    'google', public._sanitize_auth_provider_for_client(v_merged -> 'google'),
    'azureAd', public._sanitize_auth_provider_for_client(v_merged -> 'azureAd'),
    'usernamePassword', v_merged -> 'usernamePassword'
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_org_auth_providers(p_payload jsonb)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_settings jsonb;
  v_current jsonb;
  v_defaults jsonb := public.org_auth_provider_defaults();
  v_merged jsonb;
  v_provider text;
  v_incoming jsonb;
  v_current_provider jsonb;
  v_secret text;
  v_enabled_count int := 0;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT o.settings, o.settings -> 'authProviders'
  INTO v_settings, v_current
  FROM public.organizations o
  WHERE o.id = v_org_id;

  v_merged := v_defaults || COALESCE(v_current, '{}'::jsonb) || COALESCE(p_payload, '{}'::jsonb);

  FOREACH v_provider IN ARRAY ARRAY['microsoft365', 'google', 'azureAd', 'usernamePassword'] LOOP
    v_incoming := v_merged -> v_provider;
    v_current_provider := COALESCE(v_current -> v_provider, v_defaults -> v_provider);

    IF v_provider = 'usernamePassword' THEN
      v_merged := jsonb_set(
        v_merged,
        ARRAY[v_provider],
        jsonb_build_object(
          'enabled', COALESCE((v_incoming ->> 'enabled')::boolean, true)
        )
      );
    ELSE
      v_secret := NULLIF(btrim(v_incoming ->> 'clientSecret'), '');

      IF v_secret = '__keep__' OR v_secret IS NULL THEN
        v_secret := NULLIF(btrim(v_current_provider ->> 'clientSecret'), '');
      END IF;

      v_merged := jsonb_set(
        v_merged,
        ARRAY[v_provider],
        jsonb_build_object(
          'enabled', COALESCE((v_incoming ->> 'enabled')::boolean, false),
          'clientId', NULLIF(btrim(v_incoming ->> 'clientId'), ''),
          'clientSecret', COALESCE(v_secret, ''),
          'tenantId', NULLIF(btrim(v_incoming ->> 'tenantId'), ''),
          'allowedDomains', NULLIF(btrim(v_incoming ->> 'allowedDomains'), '')
        )
      );

      IF COALESCE((v_merged -> v_provider ->> 'enabled')::boolean, false)
        AND (
          NULLIF(btrim(v_merged -> v_provider ->> 'clientId'), '') IS NULL
          OR NULLIF(btrim(v_merged -> v_provider ->> 'clientSecret'), '') IS NULL
        )
      THEN
        RAISE EXCEPTION 'OAuth client ID and secret are required when provider is enabled';
      END IF;
    END IF;
  END LOOP;

  SELECT COUNT(*)::int
  INTO v_enabled_count
  FROM (
    SELECT key
    FROM jsonb_each(v_merged) AS e(key, value)
    WHERE COALESCE((value ->> 'enabled')::boolean, false)
  ) enabled_providers;

  IF v_enabled_count < 1 THEN
    RAISE EXCEPTION 'At least one sign-in provider must remain enabled';
  END IF;

  UPDATE public.organizations
  SET
    settings = COALESCE(v_settings, '{}'::jsonb)
      || jsonb_build_object('authProviders', v_merged),
    updated_at = now()
  WHERE id = v_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_org_auth_providers() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_org_auth_providers(jsonb) TO authenticated;

NOTIFY pgrst, 'reload schema';
