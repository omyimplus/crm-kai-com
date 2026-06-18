-- Job code: separator toggle + allowed separator characters

ALTER TABLE public.job_code_sequences
  ADD COLUMN IF NOT EXISTS separator_enabled boolean NOT NULL DEFAULT true;

ALTER TABLE public.job_code_sequences
  DROP CONSTRAINT IF EXISTS job_code_sequences_segment_separator_format;

ALTER TABLE public.job_code_sequences
  ADD CONSTRAINT job_code_sequences_segment_separator_format CHECK (
    segment_separator ~ '^[-_./:]$'
  );

CREATE OR REPLACE FUNCTION public.validate_job_code_payload(p_payload jsonb)
RETURNS void AS $$
DECLARE
  v_prefix text;
  v_date_style text;
  v_reset_rule text;
  v_pad_length integer;
  v_start_number integer;
  v_date_part_order text[];
  v_segment_order text[];
  v_part text;
  v_separator_enabled boolean;
  v_separator text;
BEGIN
  v_prefix := upper(trim(coalesce(p_payload->>'prefix', '')));
  IF coalesce(v_prefix, '') = '' THEN
    RAISE EXCEPTION 'Prefix required';
  END IF;
  IF v_prefix !~ '^[A-Z][A-Z0-9]{0,9}$' THEN
    RAISE EXCEPTION 'Invalid prefix format';
  END IF;

  v_date_style := coalesce(nullif(trim(p_payload->>'date_style'), ''), 'compact');
  IF v_date_style NOT IN ('compact', 'dash', 'iso') THEN
    RAISE EXCEPTION 'Invalid date style';
  END IF;

  v_reset_rule := coalesce(nullif(trim(p_payload->>'reset_rule'), ''), 'never');
  IF v_reset_rule NOT IN ('never', 'daily', 'monthly', 'yearly') THEN
    RAISE EXCEPTION 'Invalid reset rule';
  END IF;

  v_pad_length := coalesce((p_payload->>'pad_length')::integer, 4);
  IF v_pad_length < 1 OR v_pad_length > 10 THEN
    RAISE EXCEPTION 'Invalid pad length';
  END IF;

  v_start_number := coalesce((p_payload->>'start_number')::integer, 1);
  IF v_start_number < 1 THEN
    RAISE EXCEPTION 'Invalid start number';
  END IF;

  v_separator_enabled := coalesce((p_payload->>'separator_enabled')::boolean, true);
  v_separator := coalesce(nullif(p_payload->>'segment_separator', ''), '-');
  IF v_separator_enabled AND v_separator !~ '^[-_./:]$' THEN
    RAISE EXCEPTION 'Invalid segment separator';
  END IF;

  v_date_part_order := coalesce(
    ARRAY(SELECT jsonb_array_elements_text(p_payload->'date_part_order')),
    ARRAY['year', 'month', 'day']
  );
  IF array_length(v_date_part_order, 1) IS NULL OR array_length(v_date_part_order, 1) = 0 THEN
    RAISE EXCEPTION 'Date part order required';
  END IF;
  FOREACH v_part IN ARRAY v_date_part_order LOOP
    IF v_part NOT IN ('year', 'month', 'day') THEN
      RAISE EXCEPTION 'Invalid date part order';
    END IF;
  END LOOP;

  v_segment_order := coalesce(
    ARRAY(SELECT jsonb_array_elements_text(p_payload->'segment_order')),
    ARRAY['prefix', 'date', 'number']
  );
  IF array_length(v_segment_order, 1) IS DISTINCT FROM 3 THEN
    RAISE EXCEPTION 'Invalid segment order';
  END IF;
  FOREACH v_part IN ARRAY v_segment_order LOOP
    IF v_part NOT IN ('prefix', 'date', 'number') THEN
      RAISE EXCEPTION 'Invalid segment order';
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.job_code_sequence_log_snapshot(p_job_code_sequence_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', j.id,
    'module_key', j.module_key,
    'prefix', j.prefix,
    'date_enabled', j.date_enabled,
    'date_include_year', j.date_include_year,
    'date_include_month', j.date_include_month,
    'date_include_day', j.date_include_day,
    'date_part_order', j.date_part_order,
    'date_style', j.date_style,
    'segment_order', j.segment_order,
    'separator_enabled', j.separator_enabled,
    'segment_separator', j.segment_separator,
    'pad_length', j.pad_length,
    'start_number', j.start_number,
    'last_number', j.last_number,
    'reset_rule', j.reset_rule,
    'status', j.status,
    'notes', j.notes
  )
  FROM public.job_code_sequences j
  WHERE j.id = p_job_code_sequence_id
    AND j.org_id = public.current_org_id()
    AND j.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_job_code_sequence(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_id uuid;
  v_new_data jsonb;
  v_module_key text;
  v_prefix text;
  v_date_part_order text[];
  v_segment_order text[];
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  PERFORM public.validate_job_code_payload(p_payload);

  v_module_key := nullif(trim(p_payload->>'module_key'), '');
  IF v_module_key IS NULL THEN
    RAISE EXCEPTION 'Module required';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.job_code_sequences
    WHERE org_id = v_org_id
      AND module_key = v_module_key
      AND deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Job code already configured for module';
  END IF;

  v_prefix := upper(trim(p_payload->>'prefix'));
  v_date_part_order := ARRAY(SELECT jsonb_array_elements_text(p_payload->'date_part_order'));
  v_segment_order := ARRAY(SELECT jsonb_array_elements_text(p_payload->'segment_order'));

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
    status,
    notes,
    created_by
  ) VALUES (
    v_org_id,
    v_module_key,
    v_prefix,
    coalesce((p_payload->>'date_enabled')::boolean, true),
    coalesce((p_payload->>'date_include_year')::boolean, true),
    coalesce((p_payload->>'date_include_month')::boolean, true),
    coalesce((p_payload->>'date_include_day')::boolean, true),
    v_date_part_order,
    coalesce(nullif(trim(p_payload->>'date_style'), ''), 'compact'),
    v_segment_order,
    coalesce((p_payload->>'separator_enabled')::boolean, true),
    coalesce(nullif(p_payload->>'segment_separator', ''), '-'),
    coalesce((p_payload->>'pad_length')::integer, 4),
    coalesce((p_payload->>'start_number')::integer, 1),
    coalesce((p_payload->>'last_number')::integer, 0),
    coalesce(nullif(trim(p_payload->>'reset_rule'), ''), 'never'),
    coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    nullif(trim(p_payload->>'notes'), ''),
    auth.uid()
  )
  RETURNING id INTO v_id;

  v_new_data := public.job_code_sequence_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'job_code_sequences',
    v_id,
    'Created job code sequence',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_job_code_sequence')
  );

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_job_code_sequence(
  p_job_code_sequence_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_prefix text;
  v_date_part_order text[];
  v_segment_order text[];
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  PERFORM public.validate_job_code_payload(p_payload);

  v_old_data := public.job_code_sequence_log_snapshot(p_job_code_sequence_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Job code sequence not found';
  END IF;

  v_prefix := upper(trim(p_payload->>'prefix'));
  v_date_part_order := ARRAY(SELECT jsonb_array_elements_text(p_payload->'date_part_order'));
  v_segment_order := ARRAY(SELECT jsonb_array_elements_text(p_payload->'segment_order'));

  UPDATE public.job_code_sequences
  SET
    prefix = v_prefix,
    date_enabled = coalesce((p_payload->>'date_enabled')::boolean, true),
    date_include_year = coalesce((p_payload->>'date_include_year')::boolean, true),
    date_include_month = coalesce((p_payload->>'date_include_month')::boolean, true),
    date_include_day = coalesce((p_payload->>'date_include_day')::boolean, true),
    date_part_order = v_date_part_order,
    date_style = coalesce(nullif(trim(p_payload->>'date_style'), ''), 'compact'),
    segment_order = v_segment_order,
    separator_enabled = coalesce((p_payload->>'separator_enabled')::boolean, true),
    segment_separator = coalesce(nullif(p_payload->>'segment_separator', ''), '-'),
    pad_length = coalesce((p_payload->>'pad_length')::integer, 4),
    start_number = coalesce((p_payload->>'start_number')::integer, 1),
    reset_rule = coalesce(nullif(trim(p_payload->>'reset_rule'), ''), 'never'),
    status = coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    notes = nullif(trim(p_payload->>'notes'), ''),
    updated_at = now()
  WHERE id = p_job_code_sequence_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Job code sequence not found';
  END IF;

  v_new_data := public.job_code_sequence_log_snapshot(p_job_code_sequence_id);

  PERFORM public.write_data_change_log(
    'update',
    'job_code_sequences',
    p_job_code_sequence_id,
    'Updated job code sequence',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_job_code_sequence')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

NOTIFY pgrst, 'reload schema';
