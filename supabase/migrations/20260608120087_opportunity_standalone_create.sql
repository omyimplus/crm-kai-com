-- Opportunities — standalone create (no lead) · lead_id optional
-- Docs: docs/05-frontend/OPPORTUNITIES-MODULE.md

ALTER TABLE public.opportunities
  ALTER COLUMN lead_id DROP NOT NULL;

DROP INDEX IF EXISTS public.opportunities_unique_lead_active_idx;
CREATE UNIQUE INDEX opportunities_unique_lead_active_idx
  ON public.opportunities (lead_id)
  WHERE deleted_at IS NULL AND lead_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.list_opportunities(p_stage_id uuid DEFAULT NULL)
RETURNS TABLE (
  id uuid,
  org_id uuid,
  opportunity_code text,
  title text,
  lead_id uuid,
  lead_code text,
  company_id uuid,
  company_name text,
  contact_id uuid,
  contact_name text,
  pipeline_id uuid,
  stage_id uuid,
  stage_name text,
  stage_color text,
  stage_probability integer,
  stage_is_won boolean,
  stage_is_lost boolean,
  probability integer,
  estimated_value numeric,
  close_date date,
  description text,
  project_name text,
  project_type text,
  project_sub_type text,
  products_group text,
  project_costs numeric,
  owner_id uuid,
  owner_name text,
  sales_owner_id uuid,
  sales_owner_name text,
  sales_designer_id uuid,
  sales_designer_name text,
  sales_team_id uuid,
  sales_team_name text,
  address_bill_to text,
  currency text,
  status text,
  closed_at timestamptz,
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
    o.id,
    o.org_id,
    o.opportunity_code,
    o.title,
    o.lead_id,
    l.lead_code,
    o.company_id,
    coalesce(c.name, l.company_name) AS company_name,
    o.contact_id,
    nullif(trim(concat_ws(' ', ct.first_name, ct.last_name)), '') AS contact_name,
    o.pipeline_id,
    o.stage_id,
    ps.name AS stage_name,
    ps.color AS stage_color,
    ps.probability AS stage_probability,
    ps.is_won AS stage_is_won,
    ps.is_lost AS stage_is_lost,
    o.probability,
    o.estimated_value,
    o.close_date,
    o.description,
    o.project_name,
    o.project_type,
    o.project_sub_type,
    o.products_group,
    o.project_costs,
    o.owner_id,
    owner_p.full_name AS owner_name,
    o.sales_owner_id,
    sales_owner_p.full_name AS sales_owner_name,
    o.sales_designer_id,
    designer_p.full_name AS sales_designer_name,
    o.sales_team_id,
    st.name AS sales_team_name,
    o.address_bill_to,
    o.currency,
    o.status,
    o.closed_at,
    o.created_by,
    o.created_at,
    o.updated_at
  FROM public.opportunities o
  JOIN public.pipeline_stages ps ON ps.id = o.stage_id
  LEFT JOIN public.leads l ON l.id = o.lead_id AND l.deleted_at IS NULL
  LEFT JOIN public.companies c ON c.id = o.company_id AND c.deleted_at IS NULL
  LEFT JOIN public.contacts ct ON ct.id = o.contact_id AND ct.deleted_at IS NULL
  LEFT JOIN public.profiles owner_p ON owner_p.id = o.owner_id
  LEFT JOIN public.profiles sales_owner_p ON sales_owner_p.id = o.sales_owner_id
  LEFT JOIN public.profiles designer_p ON designer_p.id = o.sales_designer_id
  LEFT JOIN public.sales_teams st ON st.id = o.sales_team_id AND st.deleted_at IS NULL
  WHERE o.org_id = public.current_org_id()
    AND o.deleted_at IS NULL
    AND (
      p_stage_id IS NULL
      OR o.stage_id = p_stage_id
    )
  ORDER BY o.created_at DESC, o.opportunity_code DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_opportunity(p_payload jsonb DEFAULT '{}'::jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_pipeline_id uuid;
  v_stage_id uuid;
  v_stage_probability integer;
  v_code text;
  v_id uuid;
  v_company_id uuid;
  v_projects jsonb;
  v_new_data jsonb;
BEGIN
  IF v_org_id IS NULL OR NOT public.is_active_user() OR public.is_readonly() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF nullif(trim(p_payload->>'title'), '') IS NULL THEN
    RAISE EXCEPTION 'Title required';
  END IF;

  v_company_id := nullif(trim(p_payload->>'company_id'), '')::uuid;
  IF v_company_id IS NULL THEN
    RAISE EXCEPTION 'Customer required';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.companies c
    WHERE c.id = v_company_id
      AND c.org_id = v_org_id
      AND c.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Customer not found';
  END IF;

  IF nullif(trim(p_payload->>'owner_id'), '') IS NULL THEN
    RAISE EXCEPTION 'Owner required';
  END IF;

  PERFORM public.ensure_opportunity_module_defaults();

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

  v_projects := coalesce(p_payload->'projects', '[]'::jsonb);
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
    trim(p_payload->>'title'),
    NULL,
    v_company_id,
    nullif(trim(p_payload->>'contact_id'), '')::uuid,
    v_pipeline_id,
    v_stage_id,
    v_stage_probability,
    0,
    nullif(trim(p_payload->>'close_date'), '')::date,
    nullif(trim(p_payload->>'description'), ''),
    NULL,
    NULL,
    NULL,
    NULL,
    0,
    nullif(trim(p_payload->>'owner_id'), '')::uuid,
    nullif(trim(p_payload->>'sales_owner_id'), '')::uuid,
    nullif(trim(p_payload->>'sales_designer_id'), '')::uuid,
    nullif(trim(p_payload->>'sales_team_id'), '')::uuid,
    coalesce(
      nullif(trim(p_payload->>'address_bill_to'), ''),
      (
        SELECT b.address
        FROM public.get_company_default_bill_address(v_company_id) b
      ),
      ''
    ),
    auth.uid()
  )
  RETURNING id INTO v_id;

  PERFORM public.sync_opportunity_projects(v_id, v_projects);

  v_new_data := public.opportunity_log_snapshot(v_id);

  PERFORM public.log_data_change(
    v_org_id,
    'opportunities',
    v_id,
    'Created opportunity',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_opportunity')
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
  v_standalone boolean;
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

  v_standalone := v_row.lead_id IS NULL;
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

  IF p_payload ? 'projects' THEN
    v_new_estimated := public.sync_opportunity_projects(p_opportunity_id, p_payload->'projects');
  ELSIF p_payload ? 'estimated_value' THEN
    v_new_estimated := coalesce(nullif(trim(p_payload->>'estimated_value'), '')::numeric, 0);
  ELSE
    v_new_estimated := v_row.estimated_value;
  END IF;

  IF v_standalone THEN
    IF p_payload ? 'company_id'
      AND nullif(trim(p_payload->>'company_id'), '') IS NOT NULL
      AND NOT EXISTS (
        SELECT 1 FROM public.companies c
        WHERE c.id = (p_payload->>'company_id')::uuid
          AND c.org_id = v_org_id
          AND c.deleted_at IS NULL
      ) THEN
      RAISE EXCEPTION 'Customer not found';
    END IF;

    UPDATE public.opportunities
    SET
      title = coalesce(nullif(trim(p_payload->>'title'), ''), title),
      company_id = CASE
        WHEN p_payload ? 'company_id' THEN nullif(trim(p_payload->>'company_id'), '')::uuid
        ELSE company_id
      END,
      contact_id = CASE
        WHEN p_payload ? 'contact_id' THEN nullif(trim(p_payload->>'contact_id'), '')::uuid
        ELSE contact_id
      END,
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
      description = CASE
        WHEN p_payload ? 'description' THEN nullif(trim(p_payload->>'description'), '')
        ELSE description
      END,
      owner_id = CASE
        WHEN p_payload ? 'owner_id' THEN nullif(trim(p_payload->>'owner_id'), '')::uuid
        ELSE owner_id
      END,
      sales_owner_id = CASE
        WHEN p_payload ? 'sales_owner_id' THEN nullif(trim(p_payload->>'sales_owner_id'), '')::uuid
        ELSE sales_owner_id
      END,
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
  ELSE
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

GRANT EXECUTE ON FUNCTION public.create_opportunity(jsonb) TO authenticated;

NOTIFY pgrst, 'reload schema';
