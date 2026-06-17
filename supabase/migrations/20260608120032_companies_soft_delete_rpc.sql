-- Customer soft delete + data_change_logs (กฎเหล็ก §13)
-- Docs: docs/06-crm-schema/DATA-CHANGE-LOG.md

CREATE OR REPLACE FUNCTION public.company_log_snapshot(p_company_id uuid)
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
    'notes', c.notes
  )
  FROM public.companies c
  WHERE c.id = p_company_id
    AND c.org_id = public.current_org_id()
    AND c.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.soft_delete_company(p_company_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.company_log_snapshot(p_company_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Company not found';
  END IF;

  UPDATE public.companies
  SET
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_company_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Company not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'companies',
    p_company_id,
    'Soft-deleted customer',
    v_old_data,
    NULL,
    jsonb_build_object('source', 'soft_delete_company', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.company_log_snapshot(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_company(uuid) TO authenticated;
