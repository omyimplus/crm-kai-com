-- Tasks module (Phase 2) — table, lazy seed, job code generate, CRUD RPC
-- Docs: docs/05-frontend/TASKS-MODULE.md · DATA-CHANGE-LOG.md

-- Allow module_key = task in module_statuses
ALTER TABLE public.module_statuses
  DROP CONSTRAINT IF EXISTS module_statuses_module_key_check;

ALTER TABLE public.module_statuses
  ADD CONSTRAINT module_statuses_module_key_check CHECK (
    module_key IN (
      'task', 'customer', 'contact', 'lead', 'opportunity', 'pipeline',
      'quotations', 'salesOrder', 'invoices', 'projects',
      'contractAgreements', 'service'
    )
  );

CREATE TABLE IF NOT EXISTS public.tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  task_code text NOT NULL,
  subject text NOT NULL,
  task_type text NOT NULL DEFAULT 'task',
  module_status_id uuid NOT NULL REFERENCES public.module_statuses(id),
  priority text NOT NULL DEFAULT 'medium',
  start_at timestamptz,
  end_at timestamptz,
  assigned_by uuid REFERENCES public.profiles(id),
  assigned_to uuid REFERENCES public.profiles(id),
  company_id uuid REFERENCES public.companies(id),
  contact_id uuid REFERENCES public.contacts(id),
  opportunity_id uuid,
  lead_id uuid,
  project_id uuid,
  description text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT tasks_task_type_check CHECK (
    task_type IN ('task', 'call', 'email', 'meeting', 'visit')
  ),
  CONSTRAINT tasks_priority_check CHECK (
    priority IN ('high', 'medium', 'low')
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS tasks_unique_code_active_idx
  ON public.tasks (org_id, task_code)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_tasks_org_status
  ON public.tasks (org_id, module_status_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_tasks_org_start
  ON public.tasks (org_id, start_at)
  WHERE deleted_at IS NULL;

ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS tasks_select ON public.tasks;
CREATE POLICY tasks_select ON public.tasks FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
  );

DROP POLICY IF EXISTS tasks_insert ON public.tasks;
CREATE POLICY tasks_insert ON public.tasks FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

DROP POLICY IF EXISTS tasks_update ON public.tasks;
CREATE POLICY tasks_update ON public.tasks FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

-- ---------------------------------------------------------------------------
-- Lazy seed defaults per module
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.seed_org_module_defaults(
  p_org_id uuid,
  p_module_key text
)
RETURNS void AS $$
BEGIN
  IF p_org_id IS NULL OR p_module_key IS NULL THEN
    RETURN;
  END IF;

  IF p_module_key = 'task' THEN
    INSERT INTO public.module_statuses (
      org_id, module_key, status_code, name, color, sort_order, is_default, status
    )
    SELECT v.org_id, v.module_key, v.status_code, v.name, v.color, v.sort_order, v.is_default, v.status
    FROM (VALUES
      (p_org_id, 'task', 'OPEN', 'Open', '#22c55e', 0, true, 'active'),
      (p_org_id, 'task', 'IN_PROGRESS', 'In Progress', '#f59e0b', 1, false, 'active'),
      (p_org_id, 'task', 'COMPLETED', 'Completed', '#3b82f6', 2, false, 'active'),
      (p_org_id, 'task', 'CANCELLED', 'Cancelled', '#ef4444', 3, false, 'active')
    ) AS v(org_id, module_key, status_code, name, color, sort_order, is_default, status)
    WHERE NOT EXISTS (
      SELECT 1 FROM public.module_statuses ms
      WHERE ms.org_id = v.org_id
        AND ms.module_key = v.module_key
        AND lower(trim(ms.status_code)) = lower(trim(v.status_code))
        AND ms.deleted_at IS NULL
    );

    IF NOT EXISTS (
      SELECT 1 FROM public.job_code_sequences
      WHERE org_id = p_org_id
        AND module_key = 'task'
        AND deleted_at IS NULL
    ) THEN
      INSERT INTO public.job_code_sequences (
        org_id,
        module_key,
        prefix,
        date_enabled,
        date_include_year,
        date_include_month,
        date_include_day,
        date_part_order,
        date_style,
        segment_order,
        separator_enabled,
        segment_separator,
        pad_length,
        start_number,
        last_number,
        reset_rule,
        status
      ) VALUES (
        p_org_id,
        'task',
        'TSK',
        true,
        true,
        true,
        true,
        ARRAY['year', 'month', 'day'],
        'compact',
        ARRAY['prefix', 'date', 'number'],
        true,
        '-',
        4,
        1,
        0,
        'never',
        'active'
      );
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.ensure_task_module_defaults()
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;
  PERFORM public.seed_org_module_defaults(v_org_id, 'task');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- Job code generation
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.format_job_code_segment_date(
  p_row public.job_code_sequences,
  p_ref timestamptz DEFAULT now()
)
RETURNS text AS $$
DECLARE
  v_tokens text[] := ARRAY[]::text[];
  v_part text;
  v_local timestamp;
BEGIN
  IF NOT p_row.date_enabled THEN
    RETURN NULL;
  END IF;

  v_local := p_ref AT TIME ZONE 'Asia/Bangkok';

  FOREACH v_part IN ARRAY p_row.date_part_order LOOP
    IF v_part = 'year' AND p_row.date_include_year THEN
      v_tokens := array_append(v_tokens, to_char(v_local, 'YYYY'));
    ELSIF v_part = 'month' AND p_row.date_include_month THEN
      v_tokens := array_append(v_tokens, to_char(v_local, 'MM'));
    ELSIF v_part = 'day' AND p_row.date_include_day THEN
      v_tokens := array_append(v_tokens, to_char(v_local, 'DD'));
    END IF;
  END LOOP;

  IF coalesce(array_length(v_tokens, 1), 0) = 0 THEN
    RETURN NULL;
  END IF;

  IF p_row.date_style IN ('iso', 'dash') THEN
    RETURN array_to_string(v_tokens, '-');
  END IF;

  RETURN array_to_string(v_tokens, '');
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.generate_job_code(p_module_key text)
RETURNS text AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_row public.job_code_sequences%ROWTYPE;
  v_next integer;
  v_parts text[] := ARRAY[]::text[];
  v_segment text;
  v_sep text;
  v_code text;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  PERFORM public.seed_org_module_defaults(v_org_id, p_module_key);

  SELECT *
  INTO v_row
  FROM public.job_code_sequences
  WHERE org_id = v_org_id
    AND module_key = p_module_key
    AND deleted_at IS NULL
    AND status = 'active'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job code sequence not configured for module %', p_module_key;
  END IF;

  v_next := greatest(v_row.last_number, v_row.start_number - 1) + 1;

  UPDATE public.job_code_sequences
  SET
    last_number = v_next,
    updated_at = now()
  WHERE id = v_row.id;

  v_sep := CASE WHEN v_row.separator_enabled THEN coalesce(v_row.segment_separator, '-') ELSE '' END;

  FOREACH v_segment IN ARRAY v_row.segment_order LOOP
    IF v_segment = 'prefix' AND coalesce(v_row.prefix, '') <> '' THEN
      v_parts := array_append(v_parts, v_row.prefix);
    ELSIF v_segment = 'date' THEN
      v_code := public.format_job_code_segment_date(v_row, now());
      IF v_code IS NOT NULL THEN
        v_parts := array_append(v_parts, v_code);
      END IF;
    ELSIF v_segment = 'number' THEN
      v_parts := array_append(v_parts, lpad(v_next::text, least(greatest(v_row.pad_length, 1), 10), '0'));
    END IF;
  END LOOP;

  RETURN array_to_string(v_parts, v_sep);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- Assignees for task form (all active org members)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.list_org_assignees()
RETURNS TABLE (
  id uuid,
  full_name text,
  username text,
  avatar_url text,
  role text,
  is_active boolean
) AS $$
BEGIN
  IF public.current_org_id() IS NULL OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.full_name,
    p.username,
    p.avatar_url,
    p.role,
    p.is_active
  FROM public.profiles p
  WHERE p.org_id = public.current_org_id()
    AND p.is_active = true
  ORDER BY coalesce(p.full_name, p.username, p.id::text);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- Task snapshots + CRUD
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.task_log_snapshot(p_task_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', t.id,
    'task_code', t.task_code,
    'subject', t.subject,
    'task_type', t.task_type,
    'module_status_id', t.module_status_id,
    'priority', t.priority,
    'start_at', t.start_at,
    'end_at', t.end_at,
    'assigned_by', t.assigned_by,
    'assigned_to', t.assigned_to,
    'company_id', t.company_id,
    'contact_id', t.contact_id,
    'opportunity_id', t.opportunity_id,
    'lead_id', t.lead_id,
    'project_id', t.project_id,
    'description', t.description
  )
  FROM public.tasks t
  WHERE t.id = p_task_id
    AND t.org_id = public.current_org_id()
    AND t.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

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

  PERFORM public.ensure_task_module_defaults();

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
    nullif(trim(p_payload->>'start_at'), '')::timestamptz,
    nullif(trim(p_payload->>'end_at'), '')::timestamptz,
    coalesce(nullif(trim(p_payload->>'assigned_by'), '')::uuid, auth.uid()),
    nullif(trim(p_payload->>'assigned_to'), '')::uuid,
    nullif(trim(p_payload->>'company_id'), '')::uuid,
    nullif(trim(p_payload->>'contact_id'), '')::uuid,
    nullif(trim(p_payload->>'description'), ''),
    auth.uid()
  )
  RETURNING id INTO v_id;

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

CREATE OR REPLACE FUNCTION public.soft_delete_task(p_task_id uuid)
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

  v_old_data := public.task_log_snapshot(p_task_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  UPDATE public.tasks
  SET
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_task_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'tasks',
    p_task_id,
    'Soft deleted task',
    v_old_data,
    NULL,
    jsonb_build_object('source', 'soft_delete_task', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Backfill defaults for existing orgs
DO $$
DECLARE
  v_org record;
BEGIN
  FOR v_org IN SELECT id FROM public.organizations LOOP
    PERFORM public.seed_org_module_defaults(v_org.id, 'task');
  END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION public.seed_org_module_defaults(uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_task_module_defaults() TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_job_code(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_org_assignees() TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_tasks(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_task(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_task(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_task(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.task_log_snapshot(uuid) TO authenticated;

NOTIFY pgrst, 'reload schema';
