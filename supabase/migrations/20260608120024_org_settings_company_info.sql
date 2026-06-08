-- Setup → Settings: company info in organizations.settings.companyInfo

CREATE OR REPLACE FUNCTION public.get_org_settings()
RETURNS TABLE (
  id uuid,
  name text,
  slug text,
  logo_url text,
  settings jsonb
) AS $$
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  RETURN QUERY
  SELECT
    o.id,
    o.name,
    o.slug,
    o.logo_url,
    o.settings
  FROM public.organizations o
  WHERE o.id = public.current_org_id();
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_org_company_info(p_company_info jsonb)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_settings jsonb;
  v_profile_name text;
  v_name_en text;
  v_company jsonb;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization';
  END IF;

  v_profile_name := NULLIF(btrim(p_company_info ->> 'profileName'), '');
  v_name_en := NULLIF(btrim(p_company_info ->> 'nameEn'), '');

  IF v_profile_name IS NULL THEN
    RAISE EXCEPTION 'Profile name is required';
  END IF;

  IF v_name_en IS NULL THEN
    RAISE EXCEPTION 'Company name (EN) is required';
  END IF;

  v_company := jsonb_build_object(
    'profileName', v_profile_name,
    'nameEn', v_name_en,
    'nameTh', NULLIF(btrim(p_company_info ->> 'nameTh'), ''),
    'taxId', NULLIF(btrim(p_company_info ->> 'taxId'), ''),
    'taxBranch', NULLIF(btrim(p_company_info ->> 'taxBranch'), ''),
    'phone', NULLIF(btrim(p_company_info ->> 'phone'), ''),
    'email', NULLIF(btrim(p_company_info ->> 'email'), ''),
    'website', NULLIF(btrim(p_company_info ->> 'website'), ''),
    'addressEn', NULLIF(btrim(p_company_info ->> 'addressEn'), ''),
    'addressTh', NULLIF(btrim(p_company_info ->> 'addressTh'), ''),
    'isDefault', COALESCE((p_company_info ->> 'isDefault')::boolean, true)
  );

  SELECT o.settings
  INTO v_settings
  FROM public.organizations o
  WHERE o.id = v_org_id;

  UPDATE public.organizations
  SET
    settings = COALESCE(v_settings, '{}'::jsonb) || jsonb_build_object('companyInfo', v_company),
    updated_at = now()
  WHERE id = v_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_org_settings() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_org_company_info(jsonb) TO authenticated;
