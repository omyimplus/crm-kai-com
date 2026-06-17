-- Customer create/update RPCs + data_change_logs (กฎเหล็ก §13)
-- Docs: docs/06-crm-schema/CUSTOMER-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

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

  v_customer_type := coalesce(nullif(trim(p_payload->>'customer_type'), ''), 'company');
  v_industry_segment := nullif(trim(p_payload->>'industry_segment'), '');
  v_industry := nullif(trim(p_payload->>'industry'), '');

  IF v_customer_type = 'individual' THEN
    v_industry_segment := 'individual';
    v_industry := NULL;
  END IF;

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

  v_customer_type := coalesce(nullif(trim(p_payload->>'customer_type'), ''), 'company');
  v_industry_segment := nullif(trim(p_payload->>'industry_segment'), '');
  v_industry := nullif(trim(p_payload->>'industry'), '');

  IF v_customer_type = 'individual' THEN
    v_industry_segment := 'individual';
    v_industry := NULL;
  END IF;

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

GRANT EXECUTE ON FUNCTION public.create_company(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_company(uuid, jsonb) TO authenticated;
