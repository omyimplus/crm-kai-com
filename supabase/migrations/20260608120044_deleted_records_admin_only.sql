-- แท็บ ถูกลบ / restore — owner + admin เท่านั้น (employee อ่าน active เท่านั้น)
-- Docs: permissions.md · CUSTOMER-MASTER-FIELDS.md · CONTACT-MASTER-FIELDS.md

DROP POLICY IF EXISTS companies_select ON public.companies;
CREATE POLICY companies_select ON public.companies FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
  );

DROP POLICY IF EXISTS contacts_select ON public.contacts;
CREATE POLICY contacts_select ON public.contacts FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
  );

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

  IF NOT public.is_admin_or_owner() THEN
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

  IF NOT public.is_admin_or_owner() THEN
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
