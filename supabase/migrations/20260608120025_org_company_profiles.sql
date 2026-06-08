-- Org company profiles (branches) — Settings → Company Info tab

CREATE TABLE public.org_company_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  profile_name text NOT NULL,
  name_en text NOT NULL,
  name_th text,
  tax_id text,
  tax_branch text,
  phone text,
  email text,
  website text,
  logo_url text,
  address_en text,
  address_th text,
  is_default boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT org_company_profiles_profile_name_check
    CHECK (char_length(btrim(profile_name)) > 0),
  CONSTRAINT org_company_profiles_name_en_check
    CHECK (char_length(btrim(name_en)) > 0)
);

CREATE INDEX idx_org_company_profiles_org
  ON public.org_company_profiles (org_id, profile_name);

CREATE UNIQUE INDEX org_company_profiles_one_default_per_org
  ON public.org_company_profiles (org_id)
  WHERE is_default = true;

ALTER TABLE public.org_company_profiles ENABLE ROW LEVEL SECURITY;

-- Migrate legacy single companyInfo from organizations.settings
INSERT INTO public.org_company_profiles (
  org_id,
  profile_name,
  name_en,
  name_th,
  tax_id,
  tax_branch,
  phone,
  email,
  website,
  address_en,
  address_th,
  is_default
)
SELECT
  o.id,
  NULLIF(btrim(o.settings -> 'companyInfo' ->> 'profileName'), ''),
  NULLIF(btrim(o.settings -> 'companyInfo' ->> 'nameEn'), ''),
  NULLIF(btrim(o.settings -> 'companyInfo' ->> 'nameTh'), ''),
  NULLIF(btrim(o.settings -> 'companyInfo' ->> 'taxId'), ''),
  NULLIF(btrim(o.settings -> 'companyInfo' ->> 'taxBranch'), ''),
  NULLIF(btrim(o.settings -> 'companyInfo' ->> 'phone'), ''),
  NULLIF(btrim(o.settings -> 'companyInfo' ->> 'email'), ''),
  NULLIF(btrim(o.settings -> 'companyInfo' ->> 'website'), ''),
  NULLIF(btrim(o.settings -> 'companyInfo' ->> 'addressEn'), ''),
  NULLIF(btrim(o.settings -> 'companyInfo' ->> 'addressTh'), ''),
  COALESCE((o.settings -> 'companyInfo' ->> 'isDefault')::boolean, true)
FROM public.organizations o
WHERE o.settings ? 'companyInfo'
  AND NULLIF(btrim(o.settings -> 'companyInfo' ->> 'profileName'), '') IS NOT NULL
  AND NULLIF(btrim(o.settings -> 'companyInfo' ->> 'nameEn'), '') IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.org_company_profiles p WHERE p.org_id = o.id
  );

UPDATE public.organizations
SET settings = settings - 'companyInfo'
WHERE settings ? 'companyInfo';

CREATE OR REPLACE FUNCTION public.list_org_company_profiles()
RETURNS TABLE (
  id uuid,
  profile_name text,
  name_en text,
  name_th text,
  tax_id text,
  tax_branch text,
  phone text,
  email text,
  website text,
  logo_url text,
  address_en text,
  address_th text,
  is_default boolean,
  created_at timestamptz,
  updated_at timestamptz
) AS $$
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.profile_name,
    p.name_en,
    p.name_th,
    p.tax_id,
    p.tax_branch,
    p.phone,
    p.email,
    p.website,
    p.logo_url,
    p.address_en,
    p.address_th,
    p.is_default,
    p.created_at,
    p.updated_at
  FROM public.org_company_profiles p
  WHERE p.org_id = public.current_org_id()
  ORDER BY p.is_default DESC, p.profile_name ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_org_company_profile(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_profile_id uuid;
  v_has_any boolean;
  v_profile_name text := NULLIF(btrim(p_payload ->> 'profileName'), '');
  v_name_en text := NULLIF(btrim(p_payload ->> 'nameEn'), '');
  v_is_default boolean := COALESCE((p_payload ->> 'isDefault')::boolean, false);
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF v_profile_name IS NULL THEN
    RAISE EXCEPTION 'Profile name is required';
  END IF;

  IF v_name_en IS NULL THEN
    RAISE EXCEPTION 'Company name (EN) is required';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.org_company_profiles WHERE org_id = v_org_id
  ) INTO v_has_any;

  IF NOT v_has_any THEN
    v_is_default := true;
  END IF;

  IF v_is_default THEN
    UPDATE public.org_company_profiles
    SET is_default = false, updated_at = now()
    WHERE org_id = v_org_id AND is_default = true;
  END IF;

  INSERT INTO public.org_company_profiles (
    org_id,
    profile_name,
    name_en,
    name_th,
    tax_id,
    tax_branch,
    phone,
    email,
    website,
    address_en,
    address_th,
    is_default
  )
  VALUES (
    v_org_id,
    v_profile_name,
    v_name_en,
    NULLIF(btrim(p_payload ->> 'nameTh'), ''),
    NULLIF(btrim(p_payload ->> 'taxId'), ''),
    NULLIF(btrim(p_payload ->> 'taxBranch'), ''),
    NULLIF(btrim(p_payload ->> 'phone'), ''),
    NULLIF(btrim(p_payload ->> 'email'), ''),
    NULLIF(btrim(p_payload ->> 'website'), ''),
    NULLIF(btrim(p_payload ->> 'addressEn'), ''),
    NULLIF(btrim(p_payload ->> 'addressTh'), ''),
    v_is_default
  )
  RETURNING id INTO v_profile_id;

  RETURN v_profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_org_company_profile(
  p_profile_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_profile_name text := NULLIF(btrim(p_payload ->> 'profileName'), '');
  v_name_en text := NULLIF(btrim(p_payload ->> 'nameEn'), '');
  v_is_default boolean := COALESCE((p_payload ->> 'isDefault')::boolean, false);
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.org_company_profiles
    WHERE id = p_profile_id AND org_id = v_org_id
  ) THEN
    RAISE EXCEPTION 'Company profile not found';
  END IF;

  IF v_profile_name IS NULL THEN
    RAISE EXCEPTION 'Profile name is required';
  END IF;

  IF v_name_en IS NULL THEN
    RAISE EXCEPTION 'Company name (EN) is required';
  END IF;

  IF v_is_default THEN
    UPDATE public.org_company_profiles
    SET is_default = false, updated_at = now()
    WHERE org_id = v_org_id AND is_default = true AND id <> p_profile_id;
  END IF;

  UPDATE public.org_company_profiles
  SET
    profile_name = v_profile_name,
    name_en = v_name_en,
    name_th = NULLIF(btrim(p_payload ->> 'nameTh'), ''),
    tax_id = NULLIF(btrim(p_payload ->> 'taxId'), ''),
    tax_branch = NULLIF(btrim(p_payload ->> 'taxBranch'), ''),
    phone = NULLIF(btrim(p_payload ->> 'phone'), ''),
    email = NULLIF(btrim(p_payload ->> 'email'), ''),
    website = NULLIF(btrim(p_payload ->> 'website'), ''),
    address_en = NULLIF(btrim(p_payload ->> 'addressEn'), ''),
    address_th = NULLIF(btrim(p_payload ->> 'addressTh'), ''),
    is_default = v_is_default,
    updated_at = now()
  WHERE id = p_profile_id AND org_id = v_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.delete_org_company_profile(p_profile_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_was_default boolean;
  v_fallback_id uuid;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT is_default INTO v_was_default
  FROM public.org_company_profiles
  WHERE id = p_profile_id AND org_id = v_org_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Company profile not found';
  END IF;

  DELETE FROM public.org_company_profiles
  WHERE id = p_profile_id AND org_id = v_org_id;

  IF v_was_default THEN
    SELECT id INTO v_fallback_id
    FROM public.org_company_profiles
    WHERE org_id = v_org_id
    ORDER BY created_at ASC
    LIMIT 1;

    IF v_fallback_id IS NOT NULL THEN
      UPDATE public.org_company_profiles
      SET is_default = true, updated_at = now()
      WHERE id = v_fallback_id;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP FUNCTION IF EXISTS public.update_org_company_info(jsonb);

GRANT EXECUTE ON FUNCTION public.list_org_company_profiles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_org_company_profile(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_org_company_profile(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_org_company_profile(uuid) TO authenticated;
