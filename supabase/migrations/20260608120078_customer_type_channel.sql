-- Customer Type: company/individual → channel types (mockup)
-- end_user · dealer · contractor · distributor · oem · other
-- Docs: CUSTOMER-MASTER-FIELDS.md §0

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_individual_type_fields_check;
ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_customer_type_check;

UPDATE public.companies
SET customer_type = 'end_user', updated_at = now()
WHERE customer_type = 'company';

UPDATE public.companies
SET customer_type = 'other', updated_at = now()
WHERE customer_type = 'individual';

ALTER TABLE public.companies
  ALTER COLUMN customer_type SET DEFAULT 'end_user';

ALTER TABLE public.companies
  ADD CONSTRAINT companies_customer_type_check
  CHECK (customer_type IN ('end_user', 'dealer', 'contractor', 'distributor', 'oem', 'other'));

ALTER TABLE public.leads DROP CONSTRAINT IF EXISTS leads_customer_type_check;

UPDATE public.leads
SET customer_type = 'end_user', updated_at = now()
WHERE customer_type = 'company';

UPDATE public.leads
SET customer_type = 'other', updated_at = now()
WHERE customer_type = 'individual';

ALTER TABLE public.leads
  ALTER COLUMN customer_type SET DEFAULT 'end_user';

ALTER TABLE public.leads
  ADD CONSTRAINT leads_customer_type_check
  CHECK (customer_type IN ('end_user', 'dealer', 'contractor', 'distributor', 'oem', 'other'));

CREATE OR REPLACE FUNCTION public.create_company(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_id uuid;
  v_new_data jsonb;
  v_customer_type text;
  v_industry_segment text;
  v_industry text;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Company name required';
  END IF;

  IF coalesce(trim(p_payload->>'email'), '') = '' THEN
    RAISE EXCEPTION 'Email required';
  END IF;

  IF coalesce(trim(p_payload->>'phone'), '') = '' THEN
    RAISE EXCEPTION 'Phone required';
  END IF;

  v_customer_type := coalesce(nullif(trim(p_payload->>'customer_type'), ''), 'end_user');
  v_industry_segment := nullif(trim(p_payload->>'industry_segment'), '');
  v_industry := nullif(trim(p_payload->>'industry'), '');

  INSERT INTO public.companies (
    org_id,
    name,
    customer_type,
    email,
    mobile,
    notes,
    industry_segment,
    industry,
    sales_grade,
    website,
    phone,
    address,
    owner_id,
    status,
    tax_id,
    tax_branch,
    tax_vat,
    vat_currency,
    payment_code,
    credit_term_days,
    credit_limit,
    created_by
  ) VALUES (
    v_org_id,
    trim(p_payload->>'name'),
    v_customer_type,
    nullif(trim(p_payload->>'email'), ''),
    nullif(trim(p_payload->>'mobile'), ''),
    nullif(trim(p_payload->>'notes'), ''),
    v_industry_segment,
    v_industry,
    nullif(trim(p_payload->>'sales_grade'), ''),
    nullif(trim(p_payload->>'website'), ''),
    nullif(trim(p_payload->>'phone'), ''),
    nullif(trim(p_payload->>'address'), ''),
    nullif(trim(p_payload->>'owner_id'), '')::uuid,
    coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    nullif(trim(p_payload->>'tax_id'), ''),
    nullif(trim(p_payload->>'tax_branch'), ''),
    nullif(trim(p_payload->>'tax_vat'), ''),
    coalesce(nullif(trim(p_payload->>'vat_currency'), ''), 'THB'),
    nullif(trim(p_payload->>'payment_code'), ''),
    coalesce((p_payload->>'credit_term_days')::integer, 30),
    coalesce((p_payload->>'credit_limit')::numeric, 0),
    auth.uid()
  )
  RETURNING id INTO v_id;

  v_new_data := public.company_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'companies',
    v_id,
    'Created customer',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_company')
  );

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_company(
  p_company_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_customer_type text;
  v_industry_segment text;
  v_industry text;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Company name required';
  END IF;

  IF coalesce(trim(p_payload->>'email'), '') = '' THEN
    RAISE EXCEPTION 'Email required';
  END IF;

  IF coalesce(trim(p_payload->>'phone'), '') = '' THEN
    RAISE EXCEPTION 'Phone required';
  END IF;

  v_old_data := public.company_log_snapshot(p_company_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Company not found';
  END IF;

  v_customer_type := coalesce(nullif(trim(p_payload->>'customer_type'), ''), 'end_user');
  v_industry_segment := nullif(trim(p_payload->>'industry_segment'), '');
  v_industry := nullif(trim(p_payload->>'industry'), '');

  UPDATE public.companies
  SET
    name = trim(p_payload->>'name'),
    customer_type = v_customer_type,
    email = nullif(trim(p_payload->>'email'), ''),
    mobile = nullif(trim(p_payload->>'mobile'), ''),
    notes = nullif(trim(p_payload->>'notes'), ''),
    industry_segment = v_industry_segment,
    industry = v_industry,
    sales_grade = nullif(trim(p_payload->>'sales_grade'), ''),
    website = nullif(trim(p_payload->>'website'), ''),
    phone = nullif(trim(p_payload->>'phone'), ''),
    address = nullif(trim(p_payload->>'address'), ''),
    owner_id = nullif(trim(p_payload->>'owner_id'), '')::uuid,
    status = coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    tax_id = nullif(trim(p_payload->>'tax_id'), ''),
    tax_branch = nullif(trim(p_payload->>'tax_branch'), ''),
    tax_vat = nullif(trim(p_payload->>'tax_vat'), ''),
    vat_currency = coalesce(nullif(trim(p_payload->>'vat_currency'), ''), 'THB'),
    payment_code = nullif(trim(p_payload->>'payment_code'), ''),
    credit_term_days = coalesce((p_payload->>'credit_term_days')::integer, 30),
    credit_limit = coalesce((p_payload->>'credit_limit')::numeric, 0),
    updated_at = now()
  WHERE id = p_company_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Company not found';
  END IF;

  v_new_data := public.company_log_snapshot(p_company_id);

  PERFORM public.write_data_change_log(
    'update',
    'companies',
    p_company_id,
    'Updated customer',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_company')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_lead(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_id uuid;
  v_code text;
  v_status_id uuid;
  v_new_data jsonb;
  v_email text;
  v_mobile text;
  v_score integer;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  PERFORM public.ensure_lead_module_defaults();

  v_email := trim(coalesce(p_payload->>'email', ''));
  IF v_email = '' THEN
    RAISE EXCEPTION 'Email required';
  END IF;

  v_mobile := trim(coalesce(p_payload->>'mobile', ''));
  IF v_mobile = '' THEN
    RAISE EXCEPTION 'Mobile required';
  END IF;

  IF nullif(trim(p_payload->>'module_status_id'), '') IS NOT NULL THEN
    v_status_id := (p_payload->>'module_status_id')::uuid;
  ELSE
    SELECT ms.id INTO v_status_id
    FROM public.module_statuses ms
    WHERE ms.org_id = v_org_id
      AND ms.module_key = 'lead'
      AND ms.is_default = true
      AND ms.status = 'active'
      AND ms.deleted_at IS NULL
    LIMIT 1;
  END IF;

  IF v_status_id IS NULL THEN
    RAISE EXCEPTION 'Lead status not configured';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.module_statuses ms
    WHERE ms.id = v_status_id
      AND ms.org_id = v_org_id
      AND ms.module_key = 'lead'
      AND ms.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Invalid lead status';
  END IF;

  v_score := coalesce(nullif(trim(p_payload->>'lead_score'), '')::integer, 0);
  IF v_score < 0 OR v_score > 100 THEN
    RAISE EXCEPTION 'Invalid lead score';
  END IF;

  v_code := public.generate_job_code('lead');

  INSERT INTO public.leads (
    org_id,
    lead_code,
    full_name,
    lead_type,
    owner_id,
    tele_sale_id,
    company_id,
    contact_id,
    company_name,
    email,
    phone,
    mobile,
    tax_id,
    lead_value,
    customer_type,
    industry_segment,
    sales_grade,
    lead_source_id,
    module_status_id,
    priority,
    next_action_at,
    next_action,
    lead_score,
    requirement,
    address_street,
    address_sub_district,
    address_district,
    address_province,
    address_postal_code,
    created_by
  ) VALUES (
    v_org_id,
    v_code,
    nullif(trim(p_payload->>'full_name'), ''),
    coalesce(nullif(trim(p_payload->>'lead_type'), ''), 'other'),
    nullif(trim(p_payload->>'owner_id'), '')::uuid,
    nullif(trim(p_payload->>'tele_sale_id'), '')::uuid,
    nullif(trim(p_payload->>'company_id'), '')::uuid,
    nullif(trim(p_payload->>'contact_id'), '')::uuid,
    nullif(trim(p_payload->>'company_name'), ''),
    v_email,
    nullif(trim(p_payload->>'phone'), ''),
    v_mobile,
    nullif(trim(p_payload->>'tax_id'), ''),
    coalesce(nullif(trim(p_payload->>'lead_value'), '')::numeric, 0),
    coalesce(nullif(trim(p_payload->>'customer_type'), ''), 'end_user'),
    nullif(trim(p_payload->>'industry_segment'), ''),
    nullif(trim(p_payload->>'sales_grade'), ''),
    nullif(trim(p_payload->>'lead_source_id'), '')::uuid,
    v_status_id,
    coalesce(nullif(trim(p_payload->>'priority'), ''), 'medium'),
    nullif(trim(p_payload->>'next_action_at'), '')::timestamptz,
    nullif(trim(p_payload->>'next_action'), ''),
    v_score,
    nullif(trim(p_payload->>'requirement'), ''),
    nullif(trim(p_payload->>'address_street'), ''),
    nullif(trim(p_payload->>'address_sub_district'), ''),
    nullif(trim(p_payload->>'address_district'), ''),
    nullif(trim(p_payload->>'address_province'), ''),
    nullif(trim(p_payload->>'address_postal_code'), ''),
    auth.uid()
  )
  RETURNING id INTO v_id;

  v_new_data := public.lead_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'leads',
    v_id,
    'Created lead',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_lead')
  );

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_lead(
  p_lead_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_email text;
  v_mobile text;
  v_status_id uuid;
  v_score integer;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.lead_log_snapshot(p_lead_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Lead not found';
  END IF;

  v_email := trim(coalesce(p_payload->>'email', ''));
  IF v_email = '' THEN
    RAISE EXCEPTION 'Email required';
  END IF;

  v_mobile := trim(coalesce(p_payload->>'mobile', ''));
  IF v_mobile = '' THEN
    RAISE EXCEPTION 'Mobile required';
  END IF;

  v_status_id := (p_payload->>'module_status_id')::uuid;
  IF NOT EXISTS (
    SELECT 1 FROM public.module_statuses ms
    WHERE ms.id = v_status_id
      AND ms.org_id = v_org_id
      AND ms.module_key = 'lead'
      AND ms.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Invalid lead status';
  END IF;

  v_score := coalesce(nullif(trim(p_payload->>'lead_score'), '')::integer, 0);
  IF v_score < 0 OR v_score > 100 THEN
    RAISE EXCEPTION 'Invalid lead score';
  END IF;

  UPDATE public.leads
  SET
    full_name = nullif(trim(p_payload->>'full_name'), ''),
    lead_type = coalesce(nullif(trim(p_payload->>'lead_type'), ''), 'other'),
    owner_id = nullif(trim(p_payload->>'owner_id'), '')::uuid,
    tele_sale_id = nullif(trim(p_payload->>'tele_sale_id'), '')::uuid,
    company_id = nullif(trim(p_payload->>'company_id'), '')::uuid,
    contact_id = nullif(trim(p_payload->>'contact_id'), '')::uuid,
    company_name = nullif(trim(p_payload->>'company_name'), ''),
    email = v_email,
    phone = nullif(trim(p_payload->>'phone'), ''),
    mobile = v_mobile,
    tax_id = nullif(trim(p_payload->>'tax_id'), ''),
    lead_value = coalesce(nullif(trim(p_payload->>'lead_value'), '')::numeric, 0),
    customer_type = coalesce(nullif(trim(p_payload->>'customer_type'), ''), 'end_user'),
    industry_segment = nullif(trim(p_payload->>'industry_segment'), ''),
    sales_grade = nullif(trim(p_payload->>'sales_grade'), ''),
    lead_source_id = nullif(trim(p_payload->>'lead_source_id'), '')::uuid,
    module_status_id = v_status_id,
    priority = coalesce(nullif(trim(p_payload->>'priority'), ''), 'medium'),
    next_action_at = nullif(trim(p_payload->>'next_action_at'), '')::timestamptz,
    next_action = nullif(trim(p_payload->>'next_action'), ''),
    lead_score = v_score,
    requirement = nullif(trim(p_payload->>'requirement'), ''),
    address_street = nullif(trim(p_payload->>'address_street'), ''),
    address_sub_district = nullif(trim(p_payload->>'address_sub_district'), ''),
    address_district = nullif(trim(p_payload->>'address_district'), ''),
    address_province = nullif(trim(p_payload->>'address_province'), ''),
    address_postal_code = nullif(trim(p_payload->>'address_postal_code'), ''),
    updated_at = now()
  WHERE id = p_lead_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Lead not found';
  END IF;

  v_new_data := public.lead_log_snapshot(p_lead_id);

  PERFORM public.write_data_change_log(
    'update',
    'leads',
    p_lead_id,
    'Updated lead',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_lead')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
