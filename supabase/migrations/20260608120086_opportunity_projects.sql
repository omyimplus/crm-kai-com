-- Opportunity projects — หลายโปรเจกต์ต่อ 1 opp · มูลค่ารวม = estimated_value
-- Docs: docs/05-frontend/OPPORTUNITIES-MODULE.md

CREATE TABLE IF NOT EXISTS public.opportunity_projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  opportunity_id uuid NOT NULL REFERENCES public.opportunities(id) ON DELETE CASCADE,
  project_name text,
  project_type text,
  project_sub_type text,
  products_group text,
  estimated_value numeric(15, 2) NOT NULL DEFAULT 0,
  project_costs numeric(15, 2) NOT NULL DEFAULT 0,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT opportunity_projects_estimated_value_check CHECK (estimated_value >= 0),
  CONSTRAINT opportunity_projects_project_costs_check CHECK (project_costs >= 0)
);

CREATE INDEX IF NOT EXISTS idx_opportunity_projects_opportunity
  ON public.opportunity_projects (opportunity_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_opportunity_projects_org
  ON public.opportunity_projects (org_id);

DROP TRIGGER IF EXISTS opportunity_projects_updated_at ON public.opportunity_projects;
CREATE TRIGGER opportunity_projects_updated_at
  BEFORE UPDATE ON public.opportunity_projects
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.opportunity_projects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS opportunity_projects_select ON public.opportunity_projects;
CREATE POLICY opportunity_projects_select ON public.opportunity_projects
  FOR SELECT
  USING (org_id = public.current_org_id() AND public.is_active_user());

DROP POLICY IF EXISTS opportunity_projects_insert ON public.opportunity_projects;
CREATE POLICY opportunity_projects_insert ON public.opportunity_projects
  FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

DROP POLICY IF EXISTS opportunity_projects_update ON public.opportunity_projects;
CREATE POLICY opportunity_projects_update ON public.opportunity_projects
  FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

DROP POLICY IF EXISTS opportunity_projects_delete ON public.opportunity_projects;
CREATE POLICY opportunity_projects_delete ON public.opportunity_projects
  FOR DELETE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

-- ย้ายข้อมูลโปรเจกต์เดิม (1 แถวต่อ opp)
INSERT INTO public.opportunity_projects (
  org_id,
  opportunity_id,
  project_name,
  project_type,
  project_sub_type,
  products_group,
  estimated_value,
  project_costs,
  sort_order
)
SELECT
  o.org_id,
  o.id,
  o.project_name,
  o.project_type,
  o.project_sub_type,
  o.products_group,
  o.estimated_value,
  o.project_costs,
  0
FROM public.opportunities o
WHERE o.deleted_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM public.opportunity_projects p WHERE p.opportunity_id = o.id
  )
  AND (
    coalesce(trim(o.project_name), '') <> ''
    OR coalesce(trim(o.project_type), '') <> ''
    OR coalesce(trim(o.project_sub_type), '') <> ''
    OR coalesce(trim(o.products_group), '') <> ''
    OR o.estimated_value > 0
    OR o.project_costs > 0
  );

CREATE OR REPLACE FUNCTION public.sync_opportunity_projects(
  p_opportunity_id uuid,
  p_projects jsonb
)
RETURNS numeric AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_item jsonb;
  v_idx integer := 0;
  v_total numeric := 0;
  v_first_name text;
  v_first_type text;
  v_first_sub_type text;
  v_first_products text;
  v_first_costs numeric := 0;
BEGIN
  IF v_org_id IS NULL OR NOT public.is_active_user() OR public.is_readonly() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.opportunities o
    WHERE o.id = p_opportunity_id
      AND o.org_id = v_org_id
      AND o.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Opportunity not found';
  END IF;

  DELETE FROM public.opportunity_projects p
  WHERE p.opportunity_id = p_opportunity_id
    AND p.org_id = v_org_id;

  FOR v_item IN
    SELECT value
    FROM jsonb_array_elements(coalesce(p_projects, '[]'::jsonb))
  LOOP
    INSERT INTO public.opportunity_projects (
      org_id,
      opportunity_id,
      project_name,
      project_type,
      project_sub_type,
      products_group,
      estimated_value,
      project_costs,
      sort_order
    ) VALUES (
      v_org_id,
      p_opportunity_id,
      nullif(trim(v_item->>'project_name'), ''),
      nullif(trim(v_item->>'project_type'), ''),
      nullif(trim(v_item->>'project_sub_type'), ''),
      nullif(trim(v_item->>'products_group'), ''),
      coalesce(nullif(trim(v_item->>'estimated_value'), '')::numeric, 0),
      coalesce(nullif(trim(v_item->>'project_costs'), '')::numeric, 0),
      v_idx
    );

    v_total := v_total + coalesce(nullif(trim(v_item->>'estimated_value'), '')::numeric, 0);

    IF v_idx = 0 THEN
      v_first_name := nullif(trim(v_item->>'project_name'), '');
      v_first_type := nullif(trim(v_item->>'project_type'), '');
      v_first_sub_type := nullif(trim(v_item->>'project_sub_type'), '');
      v_first_products := nullif(trim(v_item->>'products_group'), '');
      v_first_costs := coalesce(nullif(trim(v_item->>'project_costs'), '')::numeric, 0);
    END IF;

    v_idx := v_idx + 1;
  END LOOP;

  UPDATE public.opportunities o
  SET
    estimated_value = v_total,
    project_name = v_first_name,
    project_type = v_first_type,
    project_sub_type = v_first_sub_type,
    products_group = v_first_products,
    project_costs = v_first_costs,
    updated_at = now()
  WHERE o.id = p_opportunity_id
    AND o.org_id = v_org_id
    AND o.deleted_at IS NULL;

  RETURN v_total;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.list_opportunity_projects(p_opportunity_id uuid)
RETURNS TABLE (
  id uuid,
  opportunity_id uuid,
  project_name text,
  project_type text,
  project_sub_type text,
  products_group text,
  estimated_value numeric,
  project_costs numeric,
  sort_order integer,
  created_at timestamptz,
  updated_at timestamptz
) AS $$
BEGIN
  IF public.current_org_id() IS NULL OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    p.opportunity_id,
    p.project_name,
    p.project_type,
    p.project_sub_type,
    p.products_group,
    p.estimated_value,
    p.project_costs,
    p.sort_order,
    p.created_at,
    p.updated_at
  FROM public.opportunity_projects p
  JOIN public.opportunities o ON o.id = p.opportunity_id AND o.deleted_at IS NULL
  WHERE p.opportunity_id = p_opportunity_id
    AND p.org_id = public.current_org_id()
  ORDER BY p.sort_order, p.created_at;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.sync_opportunity_projects(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_opportunity_projects(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.opportunity_log_snapshot(p_opportunity_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', o.id,
    'opportunity_code', o.opportunity_code,
    'title', o.title,
    'lead_id', o.lead_id,
    'company_id', o.company_id,
    'contact_id', o.contact_id,
    'pipeline_id', o.pipeline_id,
    'stage_id', o.stage_id,
    'probability', o.probability,
    'estimated_value', o.estimated_value,
    'close_date', o.close_date,
    'description', o.description,
    'project_name', o.project_name,
    'project_type', o.project_type,
    'project_sub_type', o.project_sub_type,
    'products_group', o.products_group,
    'project_costs', o.project_costs,
    'owner_id', o.owner_id,
    'sales_owner_id', o.sales_owner_id,
    'sales_designer_id', o.sales_designer_id,
    'sales_team_id', o.sales_team_id,
    'address_bill_to', o.address_bill_to,
    'status', o.status,
    'projects', coalesce(
      (
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', p.id,
            'project_name', p.project_name,
            'project_type', p.project_type,
            'project_sub_type', p.project_sub_type,
            'products_group', p.products_group,
            'estimated_value', p.estimated_value,
            'project_costs', p.project_costs,
            'sort_order', p.sort_order
          )
          ORDER BY p.sort_order, p.created_at
        )
        FROM public.opportunity_projects p
        WHERE p.opportunity_id = o.id
      ),
      '[]'::jsonb
    )
  )
  FROM public.opportunities o
  WHERE o.id = p_opportunity_id
    AND o.org_id = public.current_org_id()
    AND o.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

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
  v_projects jsonb;
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
  v_projects := coalesce(p_payload->'projects', '[]'::jsonb);

  IF jsonb_array_length(v_projects) = 0 THEN
    v_projects := jsonb_build_array(
      jsonb_build_object(
        'project_name', coalesce(
          nullif(trim(p_payload->>'project_name'), ''),
          nullif(trim(v_lead.company_name), '')
        ),
        'project_type', nullif(trim(p_payload->>'project_type'), ''),
        'project_sub_type', nullif(trim(p_payload->>'project_sub_type'), ''),
        'products_group', nullif(trim(p_payload->>'products_group'), ''),
        'estimated_value', coalesce(
          nullif(trim(p_payload->>'estimated_value'), '')::numeric,
          v_lead.lead_value,
          0
        ),
        'project_costs', coalesce(nullif(trim(p_payload->>'project_costs'), '')::numeric, 0)
      )
    );
  END IF;

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
    0,
    nullif(trim(p_payload->>'close_date'), '')::date,
    v_lead.requirement,
    NULL,
    NULL,
    NULL,
    NULL,
    0,
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

  v_estimated_value := public.sync_opportunity_projects(v_id, v_projects);

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

  IF p_payload ? 'projects' THEN
    v_new_estimated := public.sync_opportunity_projects(p_opportunity_id, p_payload->'projects');
  ELSIF p_payload ? 'estimated_value' THEN
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
