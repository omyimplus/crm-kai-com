-- Cascade soft delete contacts when customer is deleted (unlink active contacts)
-- Docs: CONTACT-MASTER-FIELDS.md · CUSTOMER-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

-- Self-contained: cascade needs contact_log_snapshot (also defined in migration 39)
CREATE OR REPLACE FUNCTION public.contact_log_snapshot(p_contact_id uuid)
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
    'notes', c.notes
  )
  FROM public.contacts c
  WHERE c.id = p_contact_id
    AND c.org_id = public.current_org_id()
    AND c.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.contact_log_snapshot(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.soft_delete_company(p_company_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_contact_id uuid;
  v_contact_old jsonb;
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

  -- ผู้ติดต่อที่ผูกลูกค้านี้ — soft delete ก่อน (ไม่ให้ค้าง company_id กับลูกค้าที่ถูกลบ)
  FOR v_contact_id IN
    SELECT c.id
    FROM public.contacts c
    WHERE c.company_id = p_company_id
      AND c.org_id = v_org_id
      AND c.deleted_at IS NULL
  LOOP
    v_contact_old := public.contact_log_snapshot(v_contact_id);

    UPDATE public.contacts
    SET
      deleted_at = now(),
      updated_at = now()
    WHERE id = v_contact_id
      AND org_id = v_org_id
      AND deleted_at IS NULL;

    PERFORM public.write_data_change_log(
      'delete',
      'contacts',
      v_contact_id,
      'Soft-deleted contact (customer deleted)',
      v_contact_old,
      NULL,
      jsonb_build_object(
        'source', 'soft_delete_company',
        'cascade', true,
        'company_id', p_company_id
      )
    );
  END LOOP;

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

-- กัน contact active ชี้ไปลูกค้าที่ soft delete แล้ว (ข้อมูลเก่า / race)
CREATE OR REPLACE FUNCTION public.contacts_block_deleted_company()
RETURNS trigger AS $$
BEGIN
  IF NEW.company_id IS NOT NULL AND EXISTS (
    SELECT 1
    FROM public.companies co
    WHERE co.id = NEW.company_id
      AND co.deleted_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Customer is deleted';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS contacts_block_deleted_company_trg ON public.contacts;
CREATE TRIGGER contacts_block_deleted_company_trg
  BEFORE INSERT OR UPDATE OF company_id ON public.contacts
  FOR EACH ROW EXECUTE FUNCTION public.contacts_block_deleted_company();
