-- Org images bucket (company logos, etc.) + company profile logo_url in RPCs

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'org-images',
  'org-images',
  true,
  2097152,
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/svg+xml']
)
ON CONFLICT (id) DO UPDATE SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS "Org images are publicly accessible" ON storage.objects;
CREATE POLICY "Org images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'org-images');

DROP POLICY IF EXISTS "Org admins can upload org images" ON storage.objects;
CREATE POLICY "Org admins can upload org images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'org-images'
  AND public.is_admin_or_owner()
  AND (storage.foldername(name))[1] = public.current_org_id()::text
);

DROP POLICY IF EXISTS "Org admins can update org images" ON storage.objects;
CREATE POLICY "Org admins can update org images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'org-images'
  AND public.is_admin_or_owner()
  AND (storage.foldername(name))[1] = public.current_org_id()::text
);

DROP POLICY IF EXISTS "Org admins can delete org images" ON storage.objects;
CREATE POLICY "Org admins can delete org images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'org-images'
  AND public.is_admin_or_owner()
  AND (storage.foldername(name))[1] = public.current_org_id()::text
);

CREATE OR REPLACE FUNCTION public.create_org_company_profile(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_profile_id uuid;
  v_has_any boolean;
  v_profile_name text := NULLIF(btrim(p_payload ->> 'profileName'), '');
  v_name_en text := NULLIF(btrim(p_payload ->> 'nameEn'), '');
  v_is_default boolean := COALESCE((p_payload ->> 'isDefault')::boolean, false);
  v_logo_url text := NULLIF(btrim(p_payload ->> 'logoUrl'), '');
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
    logo_url,
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
    v_logo_url,
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
  v_set_logo boolean := COALESCE((p_payload ->> 'setLogo')::boolean, false);
  v_logo_url text := NULLIF(btrim(p_payload ->> 'logoUrl'), '');
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
    logo_url = CASE
      WHEN v_set_logo THEN v_logo_url
      ELSE logo_url
    END,
    address_en = NULLIF(btrim(p_payload ->> 'addressEn'), ''),
    address_th = NULLIF(btrim(p_payload ->> 'addressTh'), ''),
    is_default = v_is_default,
    updated_at = now()
  WHERE id = p_profile_id AND org_id = v_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

NOTIFY pgrst, 'reload schema';
