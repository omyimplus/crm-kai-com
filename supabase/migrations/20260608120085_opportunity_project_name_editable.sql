-- Opportunity project_name editable (opp-owned field)
-- Docs: docs/05-frontend/OPPORTUNITIES-MODULE.md

CREATE OR REPLACE FUNCTION public.create_opportunity_from_lead(
  p_lead_id uuid,
  p_payload jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_lead public.leads%ROWTYPE;
  v_pipeline_id uuid;
  v_stage_id uuid;
  v_stage_probability integer;
  v_code text;
  v_id uuid;
  v_title text;
  v_owner_id uuid;
  v_estimated_value numeric;
  v_status_id uuid;
  v_old_lead jsonb;
  v_new_lead jsonb;
  v_new_data jsonb;
BEGIN
  IF v_org_id IS NULL OR NOT public.is_active_user() OR public.is_readonly() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  PERFORM public.ensure_opportunity_module_defaults();

  SELECT * INTO v_lead
  FROM public.leads l
  WHERE l.id = p_lead_id
    AND l.org_id = v_org_id
    AND l.deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Lead not found';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.opportunities o
    WHERE o.lead_id = p_lead_id
      AND o.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Lead already converted to opportunity';
  END IF;

  SELECT p.id INTO v_pipeline_id
  FROM public.pipelines p
  WHERE p.org_id = v_org_id
    AND p.is_default = true
  ORDER BY p.sort_order, p.created_at
  LIMIT 1;

  IF v_pipeline_id IS NULL THEN
    RAISE EXCEPTION 'Default pipeline not configured';
  END IF;

  SELECT ps.id, ps.probability
  INTO v_stage_id, v_stage_probability
  FROM public.pipeline_stages ps
  WHERE ps.pipeline_id = v_pipeline_id
    AND ps.org_id = v_org_id
    AND ps.is_won = false
    AND ps.is_lost = false
  ORDER BY ps.sort_order
  LIMIT 1;

  IF v_stage_id IS NULL THEN
    RAISE EXCEPTION 'No open pipeline stage configured';
  END IF;

  IF nullif(trim(p_payload->>'stage_id'), '') IS NOT NULL THEN
    SELECT ps.id, ps.probability
    INTO v_stage_id, v_stage_probability
    FROM public.pipeline_stages ps
    WHERE ps.id = (p_payload->>'stage_id')::uuid
      AND ps.pipeline_id = v_pipeline_id
      AND ps.org_id = v_org_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Invalid pipeline stage';
    END IF;
  END IF;

  v_title := coalesce(
    nullif(trim(p_payload->>'title'), ''),
    nullif(trim(v_lead.full_name), ''),
    nullif(trim(v_lead.company_name), ''),
    v_lead.email
  );

  v_owner_id := coalesce(v_lead.owner_id, auth.uid());
  v_estimated_value := coalesce(
    nullif(trim(p_payload->>'estimated_value'), '')::numeric,
    v_lead.lead_value,
    0
  );

  v_code := public.generate_job_code('opportunity');

  INSERT INTO public.opportunities (
    org_id,
    opportunity_code,
    title,
    lead_id,
    company_id,
    contact_id,
    pipeline_id,
    stage_id,
    probability,
    estimated_value,
    close_date,
    description,
    project_name,
    project_type,
    project_sub_type,
    products_group,
    project_costs,
    owner_id,
    sales_owner_id,
    sales_designer_id,
    sales_team_id,
    address_bill_to,
    created_by
  ) VALUES (
    v_org_id,
    v_code,
    v_title,
    p_lead_id,
    v_lead.company_id,
    v_lead.contact_id,
    v_pipeline_id,
    v_stage_id,
    v_stage_probability,
    v_estimated_value,
    nullif(trim(p_payload->>'close_date'), '')::date,
    v_lead.requirement,
    coalesce(
      nullif(trim(p_payload->>'project_name'), ''),
      nullif(trim(v_lead.company_name), '')
    ),
    nullif(trim(p_payload->>'project_type'), ''),
    nullif(trim(p_payload->>'project_sub_type'), ''),
    nullif(trim(p_payload->>'products_group'), ''),
    coalesce(nullif(trim(p_payload->>'project_costs'), '')::numeric, 0),
    v_owner_id,
    v_lead.owner_id,
    nullif(trim(p_payload->>'sales_designer_id'), '')::uuid,
    nullif(trim(p_payload->>'sales_team_id'), '')::uuid,
    coalesce(
      nullif(trim(p_payload->>'address_bill_to'), ''),
      (
        SELECT b.address
        FROM public.get_company_default_bill_address(v_lead.company_id) b
        WHERE v_lead.company_id IS NOT NULL
      ),
      ''
    ),
    auth.uid()
  )
  RETURNING id INTO v_id;

  SELECT ms.id INTO v_status_id
  FROM public.module_statuses ms
  WHERE ms.org_id = v_org_id
    AND ms.module_key = 'lead'
    AND upper(trim(ms.status_code)) = 'CONVERTED'
    AND ms.deleted_at IS NULL
    AND ms.status = 'active'
  ORDER BY ms.sort_order
  LIMIT 1;

  v_old_lead := public.lead_log_snapshot(p_lead_id);

  UPDATE public.leads
  SET
    module_status_id = coalesce(v_status_id, module_status_id),
    lead_value = v_estimated_value,
    updated_at = now()
  WHERE id = p_lead_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  v_new_lead := public.lead_log_snapshot(p_lead_id);

  IF v_old_lead IS DISTINCT FROM v_new_lead THEN
    PERFORM public.log_data_change(
      v_org_id,
      'leads',
      p_lead_id,
      CASE
        WHEN v_status_id IS NOT NULL THEN 'Lead converted to opportunity'
        ELSE 'Lead value synced from opportunity create'
      END,
      v_old_lead,
      v_new_lead,
      jsonb_build_object('source', 'create_opportunity_from_lead', 'opportunity_id', v_id)
    );
  END IF;

  v_new_data := public.opportunity_log_snapshot(v_id);

  PERFORM public.log_data_change(
    v_org_id,
    'opportunities',
    v_id,
    'Created opportunity from lead',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_opportunity_from_lead', 'lead_id', p_lead_id)
  );

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_opportunity(
  p_opportunity_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_row public.opportunities%ROWTYPE;
  v_stage_probability integer;
  v_new_estimated numeric;
  v_old_lead jsonb;
  v_new_lead jsonb;
  v_old_data jsonb;
  v_new_data jsonb;
BEGIN
  IF v_org_id IS NULL OR NOT public.is_active_user() OR public.is_readonly() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT * INTO v_row
  FROM public.opportunities o
  WHERE o.id = p_opportunity_id
    AND o.org_id = v_org_id
    AND o.deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Opportunity not found';
  END IF;

  v_old_data := public.opportunity_log_snapshot(p_opportunity_id);

  IF nullif(trim(p_payload->>'stage_id'), '') IS NOT NULL
    AND (p_payload->>'stage_id')::uuid IS DISTINCT FROM v_row.stage_id THEN
    SELECT ps.probability INTO v_stage_probability
    FROM public.pipeline_stages ps
    WHERE ps.id = (p_payload->>'stage_id')::uuid
      AND ps.pipeline_id = v_row.pipeline_id
      AND ps.org_id = v_org_id;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Invalid pipeline stage';
    END IF;
  END IF;

  IF p_payload ? 'estimated_value' THEN
    v_new_estimated := coalesce(nullif(trim(p_payload->>'estimated_value'), '')::numeric, 0);
  ELSE
    v_new_estimated := v_row.estimated_value;
  END IF;

  UPDATE public.opportunities
  SET
    stage_id = coalesce(nullif(trim(p_payload->>'stage_id'), '')::uuid, stage_id),
    probability = coalesce(
      v_stage_probability,
      (
        SELECT ps.probability
        FROM public.pipeline_stages ps
        WHERE ps.id = coalesce(nullif(trim(p_payload->>'stage_id'), '')::uuid, stage_id)
      ),
      probability
    ),
    estimated_value = v_new_estimated,
    close_date = CASE
      WHEN p_payload ? 'close_date' THEN nullif(trim(p_payload->>'close_date'), '')::date
      ELSE close_date
    END,
    project_name = CASE
      WHEN p_payload ? 'project_name' THEN nullif(trim(p_payload->>'project_name'), '')
      ELSE project_name
    END,
    project_type = CASE
      WHEN p_payload ? 'project_type' THEN nullif(trim(p_payload->>'project_type'), '')
      ELSE project_type
    END,
    project_sub_type = CASE
      WHEN p_payload ? 'project_sub_type' THEN nullif(trim(p_payload->>'project_sub_type'), '')
      ELSE project_sub_type
    END,
    products_group = CASE
      WHEN p_payload ? 'products_group' THEN nullif(trim(p_payload->>'products_group'), '')
      ELSE products_group
    END,
    project_costs = coalesce(nullif(trim(p_payload->>'project_costs'), '')::numeric, project_costs),
    sales_designer_id = CASE
      WHEN p_payload ? 'sales_designer_id' THEN nullif(trim(p_payload->>'sales_designer_id'), '')::uuid
      ELSE sales_designer_id
    END,
    sales_team_id = CASE
      WHEN p_payload ? 'sales_team_id' THEN nullif(trim(p_payload->>'sales_team_id'), '')::uuid
      ELSE sales_team_id
    END,
    address_bill_to = CASE
      WHEN p_payload ? 'address_bill_to' THEN nullif(trim(p_payload->>'address_bill_to'), '')
      ELSE address_bill_to
    END,
    updated_at = now()
  WHERE id = p_opportunity_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF v_row.lead_id IS NOT NULL THEN
    v_old_lead := public.lead_log_snapshot(v_row.lead_id);

    UPDATE public.leads
    SET
      lead_value = v_new_estimated,
      updated_at = now()
    WHERE id = v_row.lead_id
      AND org_id = v_org_id
      AND deleted_at IS NULL;

    v_new_lead := public.lead_log_snapshot(v_row.lead_id);

    IF v_old_lead IS DISTINCT FROM v_new_lead THEN
      PERFORM public.log_data_change(
        v_org_id,
        'leads',
        v_row.lead_id,
        'Lead value synced from opportunity update',
        v_old_lead,
        v_new_lead,
        jsonb_build_object('source', 'update_opportunity', 'opportunity_id', p_opportunity_id)
      );
    END IF;
  END IF;

  v_new_data := public.opportunity_log_snapshot(p_opportunity_id);

  PERFORM public.log_data_change(
    v_org_id,
    'opportunities',
    p_opportunity_id,
    'Updated opportunity',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_opportunity')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

NOTIFY pgrst, 'reload schema';
