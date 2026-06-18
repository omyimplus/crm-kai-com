-- Fix: soft_delete_company (migration 41) calls contact_log_snapshot from migration 39
-- If 41 was applied before 39, delete customer with linked contacts fails.

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
