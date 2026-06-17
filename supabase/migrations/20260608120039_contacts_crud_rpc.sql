-- Contact CRUD RPCs + data_change_logs (กฎเหล็ก §13)
-- Docs: docs/06-crm-schema/CONTACT-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

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

CREATE OR REPLACE FUNCTION public.create_contact(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_company_id uuid;
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
    coalesce((p_payload->>'is_main_contact')::boolean, false),
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
    is_main_contact = coalesce((p_payload->>'is_main_contact')::boolean, false),
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

CREATE OR REPLACE FUNCTION public.soft_delete_contact(p_contact_id uuid)
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

  v_old_data := public.contact_log_snapshot(p_contact_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Contact not found';
  END IF;

  UPDATE public.contacts
  SET
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_contact_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contact not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'contacts',
    p_contact_id,
    'Soft-deleted contact',
    v_old_data,
    NULL,
    jsonb_build_object('source', 'soft_delete_contact', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.contact_log_snapshot(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_contact(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_contact(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_contact(uuid) TO authenticated;
