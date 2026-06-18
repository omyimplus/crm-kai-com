-- list_tasks was STABLE but called ensure_task_module_defaults() (INSERT) → read-only txn error on PostgREST
-- Defaults are ensured via ensure_task_module_defaults RPC / create_task / migration backfill instead.

CREATE OR REPLACE FUNCTION public.list_tasks(p_status_code text DEFAULT NULL)
RETURNS TABLE (
  id uuid,
  org_id uuid,
  task_code text,
  subject text,
  task_type text,
  module_status_id uuid,
  status_code text,
  status_name text,
  status_color text,
  priority text,
  start_at timestamptz,
  end_at timestamptz,
  assigned_by uuid,
  assigned_by_name text,
  assigned_to uuid,
  assigned_to_name text,
  company_id uuid,
  company_name text,
  contact_id uuid,
  contact_name text,
  description text,
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
    t.id,
    t.org_id,
    t.task_code,
    t.subject,
    t.task_type,
    t.module_status_id,
    ms.status_code,
    ms.name AS status_name,
    ms.color AS status_color,
    t.priority,
    t.start_at,
    t.end_at,
    t.assigned_by,
    ab.full_name AS assigned_by_name,
    t.assigned_to,
    ato.full_name AS assigned_to_name,
    t.company_id,
    c.name AS company_name,
    t.contact_id,
    trim(concat_ws(' ', ct.first_name, ct.last_name)) AS contact_name,
    t.description,
    t.created_by,
    t.created_at,
    t.updated_at
  FROM public.tasks t
  JOIN public.module_statuses ms ON ms.id = t.module_status_id
  LEFT JOIN public.profiles ab ON ab.id = t.assigned_by
  LEFT JOIN public.profiles ato ON ato.id = t.assigned_to
  LEFT JOIN public.companies c ON c.id = t.company_id AND c.deleted_at IS NULL
  LEFT JOIN public.contacts ct ON ct.id = t.contact_id AND ct.deleted_at IS NULL
  WHERE t.org_id = public.current_org_id()
    AND t.deleted_at IS NULL
    AND ms.module_key = 'task'
    AND ms.deleted_at IS NULL
    AND (
      p_status_code IS NULL
      OR upper(trim(p_status_code)) = upper(trim(ms.status_code))
    )
  ORDER BY coalesce(t.start_at, t.created_at) DESC, t.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

NOTIFY pgrst, 'reload schema';
