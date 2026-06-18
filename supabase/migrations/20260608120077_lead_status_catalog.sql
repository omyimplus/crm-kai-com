-- Lead module statuses — align catalog with product spec (8 statuses)
-- Docs: docs/05-frontend/LEADS-MODULE.md

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
        org_id, module_key, prefix, date_enabled, date_include_year, date_include_month,
        date_include_day, date_part_order, date_style, segment_order, separator_enabled,
        segment_separator, pad_length, start_number, last_number, reset_rule, status
      ) VALUES (
        p_org_id, 'task', 'TSK', true, true, true, true,
        ARRAY['year', 'month', 'day'], 'compact', ARRAY['prefix', 'date', 'number'],
        true, '-', 4, 1, 0, 'never', 'active'
      );
    END IF;
  ELSIF p_module_key = 'lead' THEN
    INSERT INTO public.module_statuses (
      org_id, module_key, status_code, name, color, sort_order, is_default, status
    )
    SELECT v.org_id, v.module_key, v.status_code, v.name, v.color, v.sort_order, v.is_default, v.status
    FROM (VALUES
      (p_org_id, 'lead', 'NEW', 'New', '#22c55e', 0, true, 'active'),
      (p_org_id, 'lead', 'OPEN', 'Open', '#0ea5e9', 1, false, 'active'),
      (p_org_id, 'lead', 'CONTACTED', 'Contacted', '#06b6d4', 2, false, 'active'),
      (p_org_id, 'lead', 'NURTURING', 'Nurturing', '#f59e0b', 3, false, 'active'),
      (p_org_id, 'lead', 'QUALIFIED', 'Qualified', '#8b5cf6', 4, false, 'active'),
      (p_org_id, 'lead', 'UNQUALIFIED', 'Unqualified', '#94a3b8', 5, false, 'active'),
      (p_org_id, 'lead', 'CANCELLED', 'Cancelled', '#ef4444', 6, false, 'active'),
      (p_org_id, 'lead', 'CONVERTED', 'Converted', '#6366f1', 7, false, 'active')
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
        AND module_key = 'lead'
        AND deleted_at IS NULL
    ) THEN
      INSERT INTO public.job_code_sequences (
        org_id, module_key, prefix, date_enabled, date_include_year, date_include_month,
        date_include_day, date_part_order, date_style, segment_order, separator_enabled,
        segment_separator, pad_length, start_number, last_number, reset_rule, status
      ) VALUES (
        p_org_id, 'lead', 'LD', true, true, true, true,
        ARRAY['year', 'month', 'day'], 'compact', ARRAY['prefix', 'date', 'number'],
        true, '-', 4, 1, 0, 'never', 'active'
      );
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Backfill + sync metadata for existing orgs
DO $$
DECLARE
  v_org_id uuid;
BEGIN
  FOR v_org_id IN SELECT id FROM public.organizations LOOP
    PERFORM public.seed_org_module_defaults(v_org_id, 'lead');
  END LOOP;

  UPDATE public.module_statuses ms
  SET
    name = v.name,
    color = v.color,
    sort_order = v.sort_order,
    is_default = v.is_default,
    updated_at = now()
  FROM (
    VALUES
      ('NEW', 'New', '#22c55e', 0, true),
      ('OPEN', 'Open', '#0ea5e9', 1, false),
      ('CONTACTED', 'Contacted', '#06b6d4', 2, false),
      ('NURTURING', 'Nurturing', '#f59e0b', 3, false),
      ('QUALIFIED', 'Qualified', '#8b5cf6', 4, false),
      ('UNQUALIFIED', 'Unqualified', '#94a3b8', 5, false),
      ('CANCELLED', 'Cancelled', '#ef4444', 6, false),
      ('CONVERTED', 'Converted', '#6366f1', 7, false)
  ) AS v(status_code, name, color, sort_order, is_default)
  WHERE ms.module_key = 'lead'
    AND ms.deleted_at IS NULL
    AND upper(trim(ms.status_code)) = v.status_code;

  -- Ensure single default per org
  UPDATE public.module_statuses
  SET is_default = false, updated_at = now()
  WHERE module_key = 'lead'
    AND deleted_at IS NULL
    AND upper(trim(status_code)) <> 'NEW';

  UPDATE public.module_statuses
  SET is_default = true, updated_at = now()
  WHERE module_key = 'lead'
    AND deleted_at IS NULL
    AND upper(trim(status_code)) = 'NEW';
END;
$$;

NOTIFY pgrst, 'reload schema';
