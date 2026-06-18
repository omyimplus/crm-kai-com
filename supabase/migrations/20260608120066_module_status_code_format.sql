-- Module status code format: UPPER_SNAKE_CASE (constant for reports / CRM value)
-- Pattern mirrors org_roles (lowercase) but uppercase for machine-readable status codes

UPDATE public.module_statuses
SET status_code = upper(trim(status_code))
WHERE status_code IS DISTINCT FROM upper(trim(status_code));

ALTER TABLE public.module_statuses
  DROP CONSTRAINT IF EXISTS module_statuses_code_format;

ALTER TABLE public.module_statuses
  ADD CONSTRAINT module_statuses_code_format CHECK (
    status_code ~ '^[A-Z][A-Z0-9_]{1,48}$'
  );

CREATE OR REPLACE FUNCTION public.create_module_status(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_id uuid;
  v_new_data jsonb;
  v_code text;
  v_module_key text;
  v_is_default boolean;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_module_key := nullif(trim(p_payload->>'module_key'), '');
  IF v_module_key IS NULL THEN
    RAISE EXCEPTION 'Module required';
  END IF;

  v_code := upper(trim(p_payload->>'status_code'));
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Status code required';
  END IF;

  IF v_code !~ '^[A-Z][A-Z0-9_]{1,48}$' THEN
    RAISE EXCEPTION 'Invalid status code format';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Status name required';
  END IF;

  v_is_default := coalesce((p_payload->>'is_default')::boolean, false);

  INSERT INTO public.module_statuses (
    org_id,
    module_key,
    status_code,
    name,
    description,
    color,
    sort_order,
    is_default,
    status,
    notes,
    created_by
  ) VALUES (
    v_org_id,
    v_module_key,
    v_code,
    trim(p_payload->>'name'),
    nullif(trim(p_payload->>'description'), ''),
    nullif(trim(p_payload->>'color'), ''),
    coalesce((p_payload->>'sort_order')::integer, 0),
    v_is_default,
    coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    nullif(trim(p_payload->>'notes'), ''),
    auth.uid()
  )
  RETURNING id INTO v_id;

  IF v_is_default THEN
    PERFORM public.clear_module_status_default(v_module_key, v_id);
    UPDATE public.module_statuses
    SET is_default = true
    WHERE id = v_id;
  END IF;

  v_new_data := public.module_status_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'module_statuses',
    v_id,
    'Created module status',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_module_status')
  );

  RETURN v_id;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate status code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_module_status(
  p_module_status_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_code text;
  v_module_key text;
  v_is_default boolean;
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

  v_module_key := nullif(trim(p_payload->>'module_key'), '');
  IF v_module_key IS NULL THEN
    RAISE EXCEPTION 'Module required';
  END IF;

  v_code := upper(trim(p_payload->>'status_code'));
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Status code required';
  END IF;

  IF v_code !~ '^[A-Z][A-Z0-9_]{1,48}$' THEN
    RAISE EXCEPTION 'Invalid status code format';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Status name required';
  END IF;

  v_is_default := coalesce((p_payload->>'is_default')::boolean, false);

  UPDATE public.module_statuses
  SET
    module_key = v_module_key,
    status_code = v_code,
    name = trim(p_payload->>'name'),
    description = nullif(trim(p_payload->>'description'), ''),
    color = nullif(trim(p_payload->>'color'), ''),
    sort_order = coalesce((p_payload->>'sort_order')::integer, 0),
    is_default = v_is_default,
    status = coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    notes = nullif(trim(p_payload->>'notes'), ''),
    updated_at = now()
  WHERE id = p_module_status_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Module status not found';
  END IF;

  IF v_is_default THEN
    PERFORM public.clear_module_status_default(v_module_key, p_module_status_id);
    UPDATE public.module_statuses
    SET is_default = true
    WHERE id = p_module_status_id;
  END IF;

  v_new_data := public.module_status_log_snapshot(p_module_status_id);

  PERFORM public.write_data_change_log(
    'update',
    'module_statuses',
    p_module_status_id,
    'Updated module status',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_module_status')
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate status code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

NOTIFY pgrst, 'reload schema';
