-- Block soft delete of module status when active tasks still reference it.
-- Use status = inactive to hide from new assignments instead.

CREATE OR REPLACE FUNCTION public.soft_delete_module_status(p_module_status_id uuid)
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

  v_old_data := public.module_status_log_snapshot(p_module_status_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Module status not found';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.tasks t
    WHERE t.module_status_id = p_module_status_id
      AND t.org_id = v_org_id
      AND t.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Module status in use by tasks';
  END IF;

  UPDATE public.module_statuses
  SET
    is_default = false,
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_module_status_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Module status not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'module_statuses',
    p_module_status_id,
    'Soft deleted module status',
    v_old_data,
    jsonb_build_object('deleted_at', now()),
    jsonb_build_object('source', 'soft_delete_module_status', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

NOTIFY pgrst, 'reload schema';
