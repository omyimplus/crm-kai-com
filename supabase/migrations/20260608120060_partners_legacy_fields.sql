-- Partner fields aligned with legacy CRM form
-- Docs: PARTNER-MASTER-FIELDS.md

ALTER TABLE public.partners ADD COLUMN IF NOT EXISTS partner_type text NOT NULL DEFAULT 'distributor';
ALTER TABLE public.partners ADD COLUMN IF NOT EXISTS tier text NOT NULL DEFAULT 'silver';
ALTER TABLE public.partners ADD COLUMN IF NOT EXISTS partner_since date;
ALTER TABLE public.partners ADD COLUMN IF NOT EXISTS contact_person text NOT NULL DEFAULT '';
ALTER TABLE public.partners ADD COLUMN IF NOT EXISTS email text NOT NULL DEFAULT '';
ALTER TABLE public.partners ADD COLUMN IF NOT EXISTS phone text NOT NULL DEFAULT '';
ALTER TABLE public.partners ADD COLUMN IF NOT EXISTS website text;
ALTER TABLE public.partners ADD COLUMN IF NOT EXISTS commission_rate numeric(5, 2) NOT NULL DEFAULT 0;

ALTER TABLE public.partners DROP CONSTRAINT IF EXISTS partners_type_check;
ALTER TABLE public.partners ADD CONSTRAINT partners_type_check CHECK (
  partner_type IN ('distributor', 'reseller', 'agent', 'vendor', 'strategic', 'other')
);

ALTER TABLE public.partners DROP CONSTRAINT IF EXISTS partners_tier_check;
ALTER TABLE public.partners ADD CONSTRAINT partners_tier_check CHECK (
  tier IN ('platinum', 'gold', 'silver', 'bronze', 'standard')
);

ALTER TABLE public.partners DROP CONSTRAINT IF EXISTS partners_commission_rate_check;
ALTER TABLE public.partners ADD CONSTRAINT partners_commission_rate_check CHECK (
  commission_rate >= 0 AND commission_rate <= 100
);

CREATE OR REPLACE FUNCTION public.partner_log_snapshot(p_partner_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', p.id,
    'partner_code', p.partner_code,
    'name', p.name,
    'partner_type', p.partner_type,
    'tier', p.tier,
    'partner_since', p.partner_since,
    'status', p.status,
    'contact_person', p.contact_person,
    'email', p.email,
    'phone', p.phone,
    'website', p.website,
    'commission_rate', p.commission_rate
  )
  FROM public.partners p
  WHERE p.id = p_partner_id
    AND p.org_id = public.current_org_id()
    AND p.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.partner_deleted_snapshot(p_partner_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', p.id,
    'partner_code', p.partner_code,
    'name', p.name,
    'partner_type', p.partner_type,
    'tier', p.tier,
    'partner_since', p.partner_since,
    'status', p.status,
    'contact_person', p.contact_person,
    'email', p.email,
    'phone', p.phone,
    'website', p.website,
    'commission_rate', p.commission_rate,
    'deleted_at', p.deleted_at
  )
  FROM public.partners p
  WHERE p.id = p_partner_id
    AND p.org_id = public.current_org_id()
    AND p.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_partner(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_id uuid;
  v_new_data jsonb;
  v_code text;
  v_type text;
  v_tier text;
  v_rate numeric(5, 2);
  v_since date;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_code := trim(p_payload->>'partner_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Partner code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Partner company name required';
  END IF;

  IF coalesce(trim(p_payload->>'contact_person'), '') = '' THEN
    RAISE EXCEPTION 'Partner contact person required';
  END IF;

  IF coalesce(trim(p_payload->>'email'), '') = '' THEN
    RAISE EXCEPTION 'Partner email required';
  END IF;

  IF coalesce(trim(p_payload->>'phone'), '') = '' THEN
    RAISE EXCEPTION 'Partner phone required';
  END IF;

  v_type := coalesce(nullif(trim(p_payload->>'partner_type'), ''), 'distributor');
  IF v_type NOT IN ('distributor', 'reseller', 'agent', 'vendor', 'strategic', 'other') THEN
    RAISE EXCEPTION 'Invalid partner type';
  END IF;

  v_tier := coalesce(nullif(trim(p_payload->>'tier'), ''), 'silver');
  IF v_tier NOT IN ('platinum', 'gold', 'silver', 'bronze', 'standard') THEN
    RAISE EXCEPTION 'Invalid partner tier';
  END IF;

  v_rate := coalesce(nullif(trim(p_payload->>'commission_rate'), '')::numeric, 0);
  IF v_rate < 0 OR v_rate > 100 THEN
    RAISE EXCEPTION 'Invalid partner commission rate';
  END IF;

  v_since := NULLIF(trim(p_payload->>'partner_since'), '')::date;

  INSERT INTO public.partners (
    org_id,
    partner_code,
    name,
    partner_type,
    tier,
    partner_since,
    status,
    contact_person,
    email,
    phone,
    website,
    commission_rate,
    created_by
  ) VALUES (
    v_org_id,
    v_code,
    trim(p_payload->>'name'),
    v_type,
    v_tier,
    v_since,
    coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    trim(p_payload->>'contact_person'),
    trim(p_payload->>'email'),
    trim(p_payload->>'phone'),
    nullif(trim(p_payload->>'website'), ''),
    v_rate,
    auth.uid()
  )
  RETURNING id INTO v_id;

  v_new_data := public.partner_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'partners',
    v_id,
    'Created partner',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_partner')
  );

  RETURN v_id;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate partner code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_partner(
  p_partner_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_code text;
  v_type text;
  v_tier text;
  v_rate numeric(5, 2);
  v_since date;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_code := trim(p_payload->>'partner_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Partner code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Partner company name required';
  END IF;

  IF coalesce(trim(p_payload->>'contact_person'), '') = '' THEN
    RAISE EXCEPTION 'Partner contact person required';
  END IF;

  IF coalesce(trim(p_payload->>'email'), '') = '' THEN
    RAISE EXCEPTION 'Partner email required';
  END IF;

  IF coalesce(trim(p_payload->>'phone'), '') = '' THEN
    RAISE EXCEPTION 'Partner phone required';
  END IF;

  v_type := coalesce(nullif(trim(p_payload->>'partner_type'), ''), 'distributor');
  IF v_type NOT IN ('distributor', 'reseller', 'agent', 'vendor', 'strategic', 'other') THEN
    RAISE EXCEPTION 'Invalid partner type';
  END IF;

  v_tier := coalesce(nullif(trim(p_payload->>'tier'), ''), 'silver');
  IF v_tier NOT IN ('platinum', 'gold', 'silver', 'bronze', 'standard') THEN
    RAISE EXCEPTION 'Invalid partner tier';
  END IF;

  v_rate := coalesce(nullif(trim(p_payload->>'commission_rate'), '')::numeric, 0);
  IF v_rate < 0 OR v_rate > 100 THEN
    RAISE EXCEPTION 'Invalid partner commission rate';
  END IF;

  v_since := NULLIF(trim(p_payload->>'partner_since'), '')::date;

  v_old_data := public.partner_log_snapshot(p_partner_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Partner not found';
  END IF;

  UPDATE public.partners
  SET
    partner_code = v_code,
    name = trim(p_payload->>'name'),
    partner_type = v_type,
    tier = v_tier,
    partner_since = v_since,
    status = coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    contact_person = trim(p_payload->>'contact_person'),
    email = trim(p_payload->>'email'),
    phone = trim(p_payload->>'phone'),
    website = nullif(trim(p_payload->>'website'), ''),
    commission_rate = v_rate,
    updated_at = now()
  WHERE id = p_partner_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Partner not found';
  END IF;

  v_new_data := public.partner_log_snapshot(p_partner_id);

  PERFORM public.write_data_change_log(
    'update',
    'partners',
    p_partner_id,
    'Updated partner',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_partner')
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate partner code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

NOTIFY pgrst, 'reload schema';
