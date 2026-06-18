-- ผู้ติดต่อหลัก — 1 คนต่อลูกค้า · ตั้งใหม่แล้วยกเลิกคนเดิมอัตโนมัติ
-- Docs: CONTACT-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

-- แก้ข้อมูลเดิมที่มี main ซ้ำ (เก็บคนที่ updated ล่าสุด)
WITH ranked AS (
  SELECT
    c.id,
    ROW_NUMBER() OVER (
      PARTITION BY c.company_id, c.org_id
      ORDER BY c.updated_at DESC NULLS LAST, c.created_at DESC NULLS LAST, c.id
    ) AS rn
  FROM public.contacts c
  WHERE c.is_main_contact = true
    AND c.deleted_at IS NULL
    AND c.company_id IS NOT NULL
)
UPDATE public.contacts c
SET
  is_main_contact = false,
  updated_at = now()
FROM ranked r
WHERE c.id = r.id
  AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS contacts_one_main_per_company_idx
  ON public.contacts (company_id)
  WHERE is_main_contact = true
    AND deleted_at IS NULL
    AND company_id IS NOT NULL;

COMMENT ON INDEX public.contacts_one_main_per_company_idx IS
  'At most one active main contact per customer (company_id)';

CREATE OR REPLACE FUNCTION public.ensure_single_main_contact(
  p_company_id uuid,
  p_keep_contact_id uuid DEFAULT NULL
)
RETURNS void AS $$
BEGIN
  IF p_company_id IS NULL THEN
    RETURN;
  END IF;

  UPDATE public.contacts
  SET
    is_main_contact = false,
    updated_at = now()
  WHERE company_id = p_company_id
    AND org_id = public.current_org_id()
    AND deleted_at IS NULL
    AND is_main_contact = true
    AND (p_keep_contact_id IS NULL OR id IS DISTINCT FROM p_keep_contact_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_contact(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_company_id uuid;
  v_is_main boolean;
  v_id uuid;
  v_new_data jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF coalesce(trim(p_payload->>'first_name'), '') = '' THEN
    RAISE EXCEPTION 'First name required';
  END IF;

  v_company_id := NULLIF(trim(p_payload->>'company_id'), '')::uuid;
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Customer required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.companies co
    WHERE co.id = v_company_id
      AND co.org_id = v_org_id
      AND co.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Customer not found';
  END IF;

  v_is_main := coalesce((p_payload->>'is_main_contact')::boolean, false);
  IF v_is_main THEN
    PERFORM public.ensure_single_main_contact(v_company_id, NULL);
  END IF;

  INSERT INTO public.contacts (
    org_id,
    company_id,
    first_name,
    last_name,
    email,
    phone,
    mobile,
    job_title,
    department,
    contact_role,
    is_main_contact,
    notes,
    created_by
  ) VALUES (
    v_org_id,
    v_company_id,
    trim(p_payload->>'first_name'),
    nullif(trim(p_payload->>'last_name'), ''),
    nullif(trim(p_payload->>'email'), ''),
    nullif(trim(p_payload->>'phone'), ''),
    nullif(trim(p_payload->>'mobile'), ''),
    nullif(trim(p_payload->>'job_title'), ''),
    nullif(trim(p_payload->>'department'), ''),
    coalesce(nullif(trim(p_payload->>'contact_role'), ''), 'other'),
    v_is_main,
    nullif(trim(p_payload->>'notes'), ''),
    auth.uid()
  )
  RETURNING id INTO v_id;

  v_new_data := public.contact_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'contacts',
    v_id,
    'Created contact',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_contact')
  );

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_contact(
  p_contact_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_company_id uuid;
  v_is_main boolean;
  v_old_data jsonb;
  v_new_data jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF coalesce(trim(p_payload->>'first_name'), '') = '' THEN
    RAISE EXCEPTION 'First name required';
  END IF;

  v_company_id := NULLIF(trim(p_payload->>'company_id'), '')::uuid;
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Customer required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.companies co
    WHERE co.id = v_company_id
      AND co.org_id = v_org_id
      AND co.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Customer not found';
  END IF;

  v_old_data := public.contact_log_snapshot(p_contact_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Contact not found';
  END IF;

  v_is_main := coalesce((p_payload->>'is_main_contact')::boolean, false);
  IF v_is_main THEN
    PERFORM public.ensure_single_main_contact(v_company_id, p_contact_id);
  END IF;

  UPDATE public.contacts
  SET
    company_id = v_company_id,
    first_name = trim(p_payload->>'first_name'),
    last_name = nullif(trim(p_payload->>'last_name'), ''),
    email = nullif(trim(p_payload->>'email'), ''),
    phone = nullif(trim(p_payload->>'phone'), ''),
    mobile = nullif(trim(p_payload->>'mobile'), ''),
    job_title = nullif(trim(p_payload->>'job_title'), ''),
    department = nullif(trim(p_payload->>'department'), ''),
    contact_role = coalesce(nullif(trim(p_payload->>'contact_role'), ''), 'other'),
    is_main_contact = v_is_main,
    notes = nullif(trim(p_payload->>'notes'), ''),
    updated_at = now()
  WHERE id = p_contact_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contact not found';
  END IF;

  v_new_data := public.contact_log_snapshot(p_contact_id);

  PERFORM public.write_data_change_log(
    'update',
    'contacts',
    p_contact_id,
    'Updated contact',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_contact')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.restore_company(p_company_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_contact_id uuid;
  v_contact_old jsonb;
  v_contact_new jsonb;
  v_main_keep_id uuid;
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

  SELECT c.id
  INTO v_main_keep_id
  FROM public.contacts c
  WHERE c.company_id = p_company_id
    AND c.org_id = v_org_id
    AND c.deleted_at IS NULL
    AND c.is_main_contact = true
  ORDER BY c.updated_at DESC, c.id
  LIMIT 1;

  IF v_main_keep_id IS NOT NULL THEN
    PERFORM public.ensure_single_main_contact(p_company_id, v_main_keep_id);
  END IF;
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

  IF EXISTS (
    SELECT 1
    FROM public.contacts c
    WHERE c.id = p_contact_id
      AND c.is_main_contact = true
  ) THEN
    PERFORM public.ensure_single_main_contact(v_company_id, p_contact_id);
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
