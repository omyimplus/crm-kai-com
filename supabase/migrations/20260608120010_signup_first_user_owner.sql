-- First user in an org becomes owner (was always sales — blocked Setup / กำหนด Role)
-- Docs: docs/03-auth/README.md

CREATE OR REPLACE FUNCTION public.signup_profile(p_full_name text)
RETURNS void AS $$
DECLARE
  v_org_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid()) THEN
    RAISE EXCEPTION 'Profile already exists';
  END IF;
  SELECT id INTO v_org_id FROM public.organizations WHERE slug = 'demo' LIMIT 1;
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'Demo organization not found. Run seed.';
  END IF;
  INSERT INTO public.profiles (id, org_id, full_name, role)
  VALUES (
    auth.uid(),
    v_org_id,
    p_full_name,
    CASE
      WHEN NOT EXISTS (SELECT 1 FROM public.profiles WHERE org_id = v_org_id) THEN 'owner'
      ELSE 'sales'
    END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- One-time: promote sole sales user per org to owner (local dev fix)
UPDATE public.profiles p
SET role = 'owner', updated_at = now()
WHERE p.role = 'sales'
  AND NOT EXISTS (
    SELECT 1 FROM public.profiles o
    WHERE o.org_id = p.org_id
      AND o.role IN ('owner', 'admin')
  );
