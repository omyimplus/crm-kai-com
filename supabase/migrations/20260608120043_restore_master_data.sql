-- Restore soft-deleted customers + contacts (cascade restore via data_change_logs)
-- Docs: CUSTOMER-MASTER-FIELDS.md · CONTACT-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

-- อ่านรายการที่ soft delete ได้ (frontend แยก tab Active / Deleted)
DROP POLICY IF EXISTS companies_select ON public.companies;
CREATE POLICY companies_select ON public.companies FOR SELECT
  USING (org_id = public.current_org_id() AND public.is_active_user());

DROP POLICY IF EXISTS contacts_select ON public.contacts;
CREATE POLICY contacts_select ON public.contacts FOR SELECT
  USING (org_id = public.current_org_id() AND public.is_active_user());

CREATE OR REPLACE FUNCTION public.company_deleted_snapshot(p_company_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', c.id,
    'name', c.name,
    'customer_type', c.customer_type,
    'email', c.email,
    'mobile', c.mobile,
    'phone', c.phone,
    'industry', c.industry,
    'industry_segment', c.industry_segment,
    'sales_grade', c.sales_grade,
    'website', c.website,
    'address', c.address,
    'owner_id', c.owner_id,
    'status', c.status,
    'tax_id', c.tax_id,
    'tax_branch', c.tax_branch,
    'tax_vat', c.tax_vat,
    'vat_currency', c.vat_currency,
    'payment_code', c.payment_code,
    'credit_term_days', c.credit_term_days,
    'credit_limit', c.credit_limit,
    'credit_balance', c.credit_balance,
    'notes', c.notes,
    'deleted_at', c.deleted_at
  )
  FROM public.companies c
  WHERE c.id = p_company_id
    AND c.org_id = public.current_org_id()
    AND c.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.contact_deleted_snapshot(p_contact_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', c.id,
    'company_id', c.company_id,
    'first_name', c.first_name,
    'last_name', c.last_name,
    'email', c.email,
    'phone', c.phone,
    'mobile', c.mobile,
    'job_title', c.job_title,
    'department', c.department,
    'contact_role', c.contact_role,
    'is_main_contact', c.is_main_contact,
    'notes', c.notes,
    'deleted_at', c.deleted_at
  )
  FROM public.contacts c
  WHERE c.id = p_contact_id
    AND c.org_id = public.current_org_id()
    AND c.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.restore_company(p_company_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_contact_id uuid;
  v_contact_old jsonb;
  v_contact_new jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.company_deleted_snapshot(p_company_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Customer not found or not deleted';
  END IF;

  UPDATE public.companies
  SET
    deleted_at = NULL,
    updated_at = now()
  WHERE id = p_company_id
    AND org_id = v_org_id
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Customer not found or not deleted';
  END IF;

  v_new_data := public.company_log_snapshot(p_company_id);

  PERFORM public.write_data_change_log(
    'update',
    'companies',
    p_company_id,
    'Restored customer',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'restore_company', 'restore', true)
  );

  -- ผู้ติดต่อที่ถูก cascade soft delete พร้อมลูกค้ารายนี้
  FOR v_contact_id IN
    SELECT DISTINCT l.entity_id
    FROM public.data_change_logs l
    INNER JOIN public.contacts c ON c.id = l.entity_id AND c.org_id = v_org_id
    WHERE l.org_id = v_org_id
      AND l.entity_type = 'contacts'
      AND l.action = 'delete'
      AND coalesce(l.metadata->>'cascade', '') = 'true'
      AND (l.metadata->>'company_id')::uuid = p_company_id
      AND c.company_id = p_company_id
      AND c.deleted_at IS NOT NULL
  LOOP
    v_contact_old := public.contact_deleted_snapshot(v_contact_id);

    UPDATE public.contacts
    SET
      deleted_at = NULL,
      updated_at = now()
    WHERE id = v_contact_id
      AND org_id = v_org_id
      AND deleted_at IS NOT NULL;

    v_contact_new := public.contact_log_snapshot(v_contact_id);

    PERFORM public.write_data_change_log(
      'update',
      'contacts',
      v_contact_id,
      'Restored contact (customer restored)',
      v_contact_old,
      v_contact_new,
      jsonb_build_object(
        'source', 'restore_company',
        'cascade', true,
        'company_id', p_company_id,
        'restore', true
      )
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.restore_contact(p_contact_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_company_id uuid;
  v_old_data jsonb;
  v_new_data jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT c.company_id
  INTO v_company_id
  FROM public.contacts c
  WHERE c.id = p_contact_id
    AND c.org_id = v_org_id
    AND c.deleted_at IS NOT NULL;

  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Contact not found or not deleted';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.companies co
    WHERE co.id = v_company_id
      AND co.org_id = v_org_id
      AND co.deleted_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Customer is deleted — restore customer first';
  END IF;

  v_old_data := public.contact_deleted_snapshot(p_contact_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Contact not found or not deleted';
  END IF;

  UPDATE public.contacts
  SET
    deleted_at = NULL,
    updated_at = now()
  WHERE id = p_contact_id
    AND org_id = v_org_id
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contact not found or not deleted';
  END IF;

  v_new_data := public.contact_log_snapshot(p_contact_id);

  PERFORM public.write_data_change_log(
    'update',
    'contacts',
    p_contact_id,
    'Restored contact',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'restore_contact', 'restore', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.company_deleted_snapshot(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.contact_deleted_snapshot(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.restore_company(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.restore_contact(uuid) TO authenticated;
