-- Leads — link contact + expose in RPC
-- Docs: docs/05-frontend/LEADS-MODULE.md

ALTER TABLE public.leads
  ADD COLUMN IF NOT EXISTS contact_id uuid REFERENCES public.contacts(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_leads_org_contact
  ON public.leads (org_id, contact_id)
  WHERE deleted_at IS NULL;

CREATE OR REPLACE FUNCTION public.lead_log_snapshot(p_lead_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', l.id,
    'lead_code', l.lead_code,
    'full_name', l.full_name,
    'lead_type', l.lead_type,
    'owner_id', l.owner_id,
    'tele_sale_id', l.tele_sale_id,
    'company_id', l.company_id,
    'contact_id', l.contact_id,
    'company_name', l.company_name,
    'email', l.email,
    'phone', l.phone,
    'mobile', l.mobile,
    'tax_id', l.tax_id,
    'lead_value', l.lead_value,
    'customer_type', l.customer_type,
    'industry_segment', l.industry_segment,
    'sales_grade', l.sales_grade,
    'lead_source_id', l.lead_source_id,
    'module_status_id', l.module_status_id,
    'priority', l.priority,
    'next_action_at', l.next_action_at,
    'next_action', l.next_action,
    'lead_score', l.lead_score,
    'requirement', l.requirement,
    'address_street', l.address_street,
    'address_sub_district', l.address_sub_district,
    'address_district', l.address_district,
    'address_province', l.address_province,
    'address_postal_code', l.address_postal_code
  )
  FROM public.leads l
  WHERE l.id = p_lead_id
    AND l.org_id = public.current_org_id()
    AND l.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

DROP FUNCTION IF EXISTS public.list_leads(text, uuid);

CREATE OR REPLACE FUNCTION public.list_leads(
  p_status_code text DEFAULT NULL,
  p_lead_source_id uuid DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  org_id uuid,
  lead_code text,
  full_name text,
  lead_type text,
  owner_id uuid,
  owner_name text,
  tele_sale_id uuid,
  tele_sale_name text,
  company_id uuid,
  contact_id uuid,
  contact_name text,
  company_name text,
  email text,
  phone text,
  mobile text,
  tax_id text,
  lead_value numeric,
  customer_type text,
  industry_segment text,
  sales_grade text,
  lead_source_id uuid,
  lead_source_name text,
  module_status_id uuid,
  status_code text,
  status_name text,
  status_color text,
  priority text,
  next_action_at timestamptz,
  next_action text,
  lead_score integer,
  requirement text,
  address_street text,
  address_sub_district text,
  address_district text,
  address_province text,
  address_postal_code text,
  created_by uuid,
  created_at timestamptz,
  updated_at timestamptz
) AS $$
BEGIN
  IF public.current_org_id() IS NULL OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  RETURN QUERY
  SELECT
    l.id,
    l.org_id,
    l.lead_code,
    l.full_name,
    l.lead_type,
    l.owner_id,
    ow.full_name AS owner_name,
    l.tele_sale_id,
    ts.full_name AS tele_sale_name,
    l.company_id,
    l.contact_id,
    nullif(trim(concat_ws(' ', ct.first_name, ct.last_name)), '') AS contact_name,
    coalesce(c.name, l.company_name) AS company_name,
    l.email,
    l.phone,
    l.mobile,
    l.tax_id,
    l.lead_value,
    l.customer_type,
    l.industry_segment,
    l.sales_grade,
    l.lead_source_id,
    ls.name AS lead_source_name,
    l.module_status_id,
    ms.status_code,
    ms.name AS status_name,
    ms.color AS status_color,
    l.priority,
    l.next_action_at,
    l.next_action,
    l.lead_score,
    l.requirement,
    l.address_street,
    l.address_sub_district,
    l.address_district,
    l.address_province,
    l.address_postal_code,
    l.created_by,
    l.created_at,
    l.updated_at
  FROM public.leads l
  JOIN public.module_statuses ms ON ms.id = l.module_status_id
  LEFT JOIN public.profiles ow ON ow.id = l.owner_id
  LEFT JOIN public.profiles ts ON ts.id = l.tele_sale_id
  LEFT JOIN public.companies c ON c.id = l.company_id AND c.deleted_at IS NULL
  LEFT JOIN public.contacts ct ON ct.id = l.contact_id AND ct.deleted_at IS NULL
  LEFT JOIN public.lead_sources ls ON ls.id = l.lead_source_id AND ls.deleted_at IS NULL
  WHERE l.org_id = public.current_org_id()
    AND l.deleted_at IS NULL
    AND ms.module_key = 'lead'
    AND ms.deleted_at IS NULL
    AND (
      p_status_code IS NULL
      OR upper(trim(p_status_code)) = upper(trim(ms.status_code))
    )
    AND (
      p_lead_source_id IS NULL
      OR l.lead_source_id = p_lead_source_id
    )
  ORDER BY l.created_at DESC, l.lead_code DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

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
    coalesce(nullif(trim(p_payload->>'customer_type'), ''), 'company'),
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
    customer_type = coalesce(nullif(trim(p_payload->>'customer_type'), ''), 'company'),
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

GRANT EXECUTE ON FUNCTION public.list_leads(text, uuid) TO authenticated;
