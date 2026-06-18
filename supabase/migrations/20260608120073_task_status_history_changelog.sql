-- Task status history — actual change log (not ordered pipeline of all statuses)
-- Append on status change · edit dates on existing rows by id

ALTER TABLE public.task_status_history
  DROP CONSTRAINT IF EXISTS task_status_history_unique_task_status;

CREATE OR REPLACE FUNCTION public.apply_task_status_history(
  p_task_id uuid,
  p_org_id uuid,
  p_entries jsonb
)
RETURNS void AS $$
DECLARE
  v_entry jsonb;
  v_id uuid;
  v_status_at timestamptz;
BEGIN
  IF p_entries IS NULL OR jsonb_typeof(p_entries) <> 'array' THEN
    RETURN;
  END IF;

  FOR v_entry IN SELECT value FROM jsonb_array_elements(p_entries) AS value
  LOOP
    v_id := nullif(trim(v_entry->>'id'), '')::uuid;
    v_status_at := nullif(trim(v_entry->>'status_at'), '')::timestamptz;

    IF v_id IS NULL OR v_status_at IS NULL THEN
      CONTINUE;
    END IF;

    UPDATE public.task_status_history h
    SET
      status_at = v_status_at,
      changed_by = auth.uid(),
      updated_at = now()
    WHERE h.id = v_id
      AND h.task_id = p_task_id
      AND h.org_id = p_org_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.record_task_status_history(
  p_task_id uuid,
  p_org_id uuid,
  p_module_status_id uuid,
  p_status_at timestamptz DEFAULT now()
)
RETURNS void AS $$
BEGIN
  IF p_module_status_id IS NULL OR p_status_at IS NULL THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.module_statuses ms
    WHERE ms.id = p_module_status_id
      AND ms.org_id = p_org_id
      AND ms.module_key = 'task'
      AND ms.deleted_at IS NULL
  ) THEN
    RETURN;
  END IF;

  INSERT INTO public.task_status_history (
    org_id,
    task_id,
    module_status_id,
    status_at,
    changed_by
  ) VALUES (
    p_org_id,
    p_task_id,
    p_module_status_id,
    p_status_at,
    auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.list_task_status_history(p_task_id uuid)
RETURNS TABLE (
  id uuid,
  module_status_id uuid,
  status_code text,
  status_name text,
  status_color text,
  sort_order integer,
  status_at timestamptz,
  changed_by uuid,
  changed_by_name text
) AS $$
BEGIN
  IF public.current_org_id() IS NULL OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.tasks t
    WHERE t.id = p_task_id
      AND t.org_id = public.current_org_id()
      AND t.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  RETURN QUERY
  SELECT
    h.id,
    h.module_status_id,
    ms.status_code,
    ms.name AS status_name,
    ms.color AS status_color,
    ms.sort_order,
    h.status_at,
    h.changed_by,
    p.full_name AS changed_by_name
  FROM public.task_status_history h
  JOIN public.module_statuses ms ON ms.id = h.module_status_id
  LEFT JOIN public.profiles p ON p.id = h.changed_by
  WHERE h.task_id = p_task_id
    AND h.org_id = public.current_org_id()
    AND ms.module_key = 'task'
    AND ms.deleted_at IS NULL
  ORDER BY h.status_at ASC, h.created_at ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_task(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_id uuid;
  v_code text;
  v_status_id uuid;
  v_new_data jsonb;
  v_subject text;
  v_task_type text;
  v_start_at timestamptz;
  v_status_at timestamptz;
  v_entry jsonb;
  v_hist_status_id uuid;
  v_hist_status_at timestamptz;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  PERFORM public.ensure_task_module_defaults();

  v_subject := trim(coalesce(p_payload->>'subject', ''));
  IF v_subject = '' THEN
    RAISE EXCEPTION 'Subject required';
  END IF;

  v_task_type := coalesce(nullif(trim(p_payload->>'task_type'), ''), 'task');
  IF v_task_type NOT IN ('task', 'call', 'email', 'meeting', 'visit') THEN
    RAISE EXCEPTION 'Invalid task type';
  END IF;

  IF nullif(trim(p_payload->>'module_status_id'), '') IS NOT NULL THEN
    v_status_id := (p_payload->>'module_status_id')::uuid;
  ELSE
    SELECT ms.id INTO v_status_id
    FROM public.module_statuses ms
    WHERE ms.org_id = v_org_id
      AND ms.module_key = 'task'
      AND ms.is_default = true
      AND ms.status = 'active'
      AND ms.deleted_at IS NULL
    LIMIT 1;
  END IF;

  IF v_status_id IS NULL THEN
    RAISE EXCEPTION 'Task status not configured';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.module_statuses ms
    WHERE ms.id = v_status_id
      AND ms.org_id = v_org_id
      AND ms.module_key = 'task'
      AND ms.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Invalid task status';
  END IF;

  v_start_at := nullif(trim(p_payload->>'start_at'), '')::timestamptz;
  v_status_at := coalesce(
    nullif(trim(p_payload->>'status_changed_at'), '')::timestamptz,
    v_start_at,
    now()
  );

  v_code := public.generate_job_code('task');

  INSERT INTO public.tasks (
    org_id,
    task_code,
    subject,
    task_type,
    module_status_id,
    priority,
    start_at,
    end_at,
    assigned_by,
    assigned_to,
    company_id,
    contact_id,
    description,
    created_by
  ) VALUES (
    v_org_id,
    v_code,
    v_subject,
    v_task_type,
    v_status_id,
    coalesce(nullif(trim(p_payload->>'priority'), ''), 'medium'),
    v_start_at,
    nullif(trim(p_payload->>'end_at'), '')::timestamptz,
    coalesce(nullif(trim(p_payload->>'assigned_by'), '')::uuid, auth.uid()),
    nullif(trim(p_payload->>'assigned_to'), '')::uuid,
    nullif(trim(p_payload->>'company_id'), '')::uuid,
    nullif(trim(p_payload->>'contact_id'), '')::uuid,
    nullif(trim(p_payload->>'description'), ''),
    auth.uid()
  )
  RETURNING id INTO v_id;

  IF p_payload->'status_history' IS NOT NULL
    AND jsonb_typeof(p_payload->'status_history') = 'array'
    AND jsonb_array_length(p_payload->'status_history') > 0
  THEN
    FOR v_entry IN SELECT value FROM jsonb_array_elements(p_payload->'status_history') AS value
    LOOP
      v_hist_status_id := nullif(trim(v_entry->>'module_status_id'), '')::uuid;
      v_hist_status_at := nullif(trim(v_entry->>'status_at'), '')::timestamptz;
      IF v_hist_status_id IS NOT NULL AND v_hist_status_at IS NOT NULL THEN
        PERFORM public.record_task_status_history(v_id, v_org_id, v_hist_status_id, v_hist_status_at);
      END IF;
    END LOOP;
  ELSE
    PERFORM public.record_task_status_history(v_id, v_org_id, v_status_id, v_status_at);
  END IF;

  v_new_data := public.task_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'tasks',
    v_id,
    'Created task',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_task')
  );

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_task(
  p_task_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_subject text;
  v_task_type text;
  v_status_id uuid;
  v_old_status_id uuid;
  v_status_at timestamptz;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.task_log_snapshot(p_task_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  v_old_status_id := (v_old_data->>'module_status_id')::uuid;

  v_subject := trim(coalesce(p_payload->>'subject', ''));
  IF v_subject = '' THEN
    RAISE EXCEPTION 'Subject required';
  END IF;

  v_task_type := coalesce(nullif(trim(p_payload->>'task_type'), ''), 'task');
  IF v_task_type NOT IN ('task', 'call', 'email', 'meeting', 'visit') THEN
    RAISE EXCEPTION 'Invalid task type';
  END IF;

  v_status_id := (p_payload->>'module_status_id')::uuid;
  IF NOT EXISTS (
    SELECT 1 FROM public.module_statuses ms
    WHERE ms.id = v_status_id
      AND ms.org_id = v_org_id
      AND ms.module_key = 'task'
      AND ms.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Invalid task status';
  END IF;

  v_status_at := coalesce(
    nullif(trim(p_payload->>'status_changed_at'), '')::timestamptz,
    now()
  );

  UPDATE public.tasks
  SET
    subject = v_subject,
    task_type = v_task_type,
    module_status_id = v_status_id,
    priority = coalesce(nullif(trim(p_payload->>'priority'), ''), 'medium'),
    start_at = nullif(trim(p_payload->>'start_at'), '')::timestamptz,
    end_at = nullif(trim(p_payload->>'end_at'), '')::timestamptz,
    assigned_by = nullif(trim(p_payload->>'assigned_by'), '')::uuid,
    assigned_to = nullif(trim(p_payload->>'assigned_to'), '')::uuid,
    company_id = nullif(trim(p_payload->>'company_id'), '')::uuid,
    contact_id = nullif(trim(p_payload->>'contact_id'), '')::uuid,
    description = nullif(trim(p_payload->>'description'), ''),
    updated_at = now()
  WHERE id = p_task_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  IF v_status_id IS DISTINCT FROM v_old_status_id THEN
    PERFORM public.record_task_status_history(p_task_id, v_org_id, v_status_id, v_status_at);
  ELSE
    UPDATE public.task_status_history h
    SET
      status_at = v_status_at,
      changed_by = auth.uid(),
      updated_at = now()
    WHERE h.id = (
      SELECT h2.id
      FROM public.task_status_history h2
      WHERE h2.task_id = p_task_id
        AND h2.org_id = v_org_id
        AND h2.module_status_id = v_status_id
      ORDER BY h2.status_at DESC, h2.created_at DESC
      LIMIT 1
    );
  END IF;

  PERFORM public.apply_task_status_history(p_task_id, v_org_id, p_payload->'status_history');

  v_new_data := public.task_log_snapshot(p_task_id);

  PERFORM public.write_data_change_log(
    'update',
    'tasks',
    p_task_id,
    'Updated task',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_task')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

NOTIFY pgrst, 'reload schema';
