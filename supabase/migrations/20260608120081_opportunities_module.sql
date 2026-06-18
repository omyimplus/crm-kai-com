-- Opportunities module — table, lazy seed, CRUD RPC, convert from lead
-- Docs: docs/05-frontend/OPPORTUNITIES-MODULE.md

CREATE TABLE IF NOT EXISTS public.opportunities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  opportunity_code text NOT NULL,
  title text NOT NULL,
  lead_id uuid NOT NULL REFERENCES public.leads(id) ON DELETE RESTRICT,
  company_id uuid REFERENCES public.companies(id) ON DELETE SET NULL,
  contact_id uuid REFERENCES public.contacts(id) ON DELETE SET NULL,
  pipeline_id uuid NOT NULL REFERENCES public.pipelines(id) ON DELETE RESTRICT,
  stage_id uuid NOT NULL REFERENCES public.pipeline_stages(id) ON DELETE RESTRICT,
  probability integer NOT NULL DEFAULT 0,
  estimated_value numeric(15, 2) NOT NULL DEFAULT 0,
  close_date date,
  description text,
  project_name text,
  project_type text,
  project_sub_type text,
  products_group text,
  project_costs numeric(15, 2) NOT NULL DEFAULT 0,
  owner_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  sales_owner_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  sales_designer_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  sales_team_id uuid REFERENCES public.sales_teams(id) ON DELETE SET NULL,
  address_bill_to text,
  currency text NOT NULL DEFAULT 'THB',
  status text NOT NULL DEFAULT 'open',
  closed_at timestamptz,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT opportunities_probability_check CHECK (
    probability >= 0 AND probability <= 100
  ),
  CONSTRAINT opportunities_estimated_value_check CHECK (
    estimated_value >= 0
  ),
  CONSTRAINT opportunities_project_costs_check CHECK (
    project_costs >= 0
  ),
  CONSTRAINT opportunities_status_check CHECK (
    status IN ('open', 'won', 'lost')
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS opportunities_unique_code_active_idx
  ON public.opportunities (org_id, opportunity_code)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS opportunities_unique_lead_active_idx
  ON public.opportunities (lead_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_opportunities_org_stage
  ON public.opportunities (org_id, stage_id)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_opportunities_org_status
  ON public.opportunities (org_id, status)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_opportunities_org_company
  ON public.opportunities (org_id, company_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.opportunities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS opportunities_select ON public.opportunities;
CREATE POLICY opportunities_select ON public.opportunities FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
  );

DROP POLICY IF EXISTS opportunities_insert ON public.opportunities;
CREATE POLICY opportunities_insert ON public.opportunities FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

DROP POLICY IF EXISTS opportunities_update ON public.opportunities;
CREATE POLICY opportunities_update ON public.opportunities FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

-- Stage change → status + closed_at (like deals)
CREATE OR REPLACE FUNCTION public.log_opportunity_stage_change()
RETURNS trigger AS $$
BEGIN
  IF OLD.stage_id IS DISTINCT FROM NEW.stage_id THEN
    IF EXISTS (SELECT 1 FROM public.pipeline_stages WHERE id = NEW.stage_id AND is_won) THEN
      NEW.status := 'won';
      NEW.closed_at := coalesce(NEW.closed_at, now());
    ELSIF EXISTS (SELECT 1 FROM public.pipeline_stages WHERE id = NEW.stage_id AND is_lost) THEN
      NEW.status := 'lost';
      NEW.closed_at := coalesce(NEW.closed_at, now());
    ELSE
      NEW.status := 'open';
      NEW.closed_at := NULL;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS opportunities_stage_change ON public.opportunities;
CREATE TRIGGER opportunities_stage_change BEFORE UPDATE ON public.opportunities
  FOR EACH ROW EXECUTE FUNCTION public.log_opportunity_stage_change();

DROP TRIGGER IF EXISTS opportunities_updated_at ON public.opportunities;
CREATE TRIGGER opportunities_updated_at BEFORE UPDATE ON public.opportunities
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Lazy seed — extend seed_org_module_defaults for opportunity (job code only)
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
  ELSIF p_module_key = 'opportunity' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.job_code_sequences
      WHERE org_id = p_org_id
        AND module_key = 'opportunity'
        AND deleted_at IS NULL
    ) THEN
      INSERT INTO public.job_code_sequences (
        org_id, module_key, prefix, date_enabled, date_include_year, date_include_month,
        date_include_day, date_part_order, date_style, segment_order, separator_enabled,
        segment_separator, pad_length, start_number, last_number, reset_rule, status
      ) VALUES (
        p_org_id, 'opportunity', 'OPP', true, true, true, true,
        ARRAY['year', 'month', 'day'], 'compact', ARRAY['prefix', 'date', 'number'],
        true, '-', 4, 1, 0, 'never', 'active'
      );
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.ensure_opportunity_module_defaults()
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
BEGIN
  IF v_org_id IS NULL OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;
  PERFORM public.seed_org_module_defaults(v_org_id, 'opportunity');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

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
    'status', o.status
  )
  FROM public.opportunities o
  WHERE o.id = p_opportunity_id
    AND o.org_id = public.current_org_id()
    AND o.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.lead_address_snapshot(p_lead_id uuid)
RETURNS text AS $$
DECLARE
  v_lead public.leads%ROWTYPE;
  v_parts text[] := ARRAY[]::text[];
BEGIN
  SELECT * INTO v_lead
  FROM public.leads l
  WHERE l.id = p_lead_id
    AND l.org_id = public.current_org_id()
    AND l.deleted_at IS NULL;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  IF coalesce(trim(v_lead.address_street), '') <> '' THEN
    v_parts := array_append(v_parts, trim(v_lead.address_street));
  END IF;
  IF coalesce(trim(v_lead.address_sub_district), '') <> '' THEN
    v_parts := array_append(v_parts, trim(v_lead.address_sub_district));
  END IF;
  IF coalesce(trim(v_lead.address_district), '') <> '' THEN
    v_parts := array_append(v_parts, trim(v_lead.address_district));
  END IF;
  IF coalesce(trim(v_lead.address_province), '') <> '' THEN
    v_parts := array_append(v_parts, trim(v_lead.address_province));
  END IF;
  IF coalesce(trim(v_lead.address_postal_code), '') <> '' THEN
    v_parts := array_append(v_parts, trim(v_lead.address_postal_code));
  END IF;

  IF array_length(v_parts, 1) IS NULL THEN
    RETURN NULL;
  END IF;

  RETURN array_to_string(v_parts, ', ');
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- List / get by lead
-- ---------------------------------------------------------------------------

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
  JOIN public.leads l ON l.id = o.lead_id AND l.deleted_at IS NULL
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

CREATE OR REPLACE FUNCTION public.get_opportunity_by_lead(p_lead_id uuid)
RETURNS uuid AS $$
DECLARE
  v_id uuid;
BEGIN
  IF public.current_org_id() IS NULL OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT o.id INTO v_id
  FROM public.opportunities o
  WHERE o.lead_id = p_lead_id
    AND o.org_id = public.current_org_id()
    AND o.deleted_at IS NULL
  LIMIT 1;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ---------------------------------------------------------------------------
-- Create from lead (only entry point)
-- ---------------------------------------------------------------------------

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

  v_owner_id := coalesce(
    nullif(trim(p_payload->>'owner_id'), '')::uuid,
    v_lead.owner_id,
    auth.uid()
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
    coalesce(nullif(trim(p_payload->>'company_id'), '')::uuid, v_lead.company_id),
    coalesce(nullif(trim(p_payload->>'contact_id'), '')::uuid, v_lead.contact_id),
    v_pipeline_id,
    v_stage_id,
    coalesce(nullif(trim(p_payload->>'probability'), '')::integer, v_stage_probability, 0),
    coalesce(nullif(trim(p_payload->>'estimated_value'), '')::numeric, v_lead.lead_value, 0),
    nullif(trim(p_payload->>'close_date'), '')::date,
    nullif(trim(p_payload->>'description'), ''),
    nullif(trim(p_payload->>'project_name'), ''),
    nullif(trim(p_payload->>'project_type'), ''),
    nullif(trim(p_payload->>'project_sub_type'), ''),
    nullif(trim(p_payload->>'products_group'), ''),
    coalesce(nullif(trim(p_payload->>'project_costs'), '')::numeric, 0),
    v_owner_id,
    nullif(trim(p_payload->>'sales_owner_id'), '')::uuid,
    nullif(trim(p_payload->>'sales_designer_id'), '')::uuid,
    nullif(trim(p_payload->>'sales_team_id'), '')::uuid,
    coalesce(nullif(trim(p_payload->>'address_bill_to'), ''), public.lead_address_snapshot(p_lead_id)),
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

  IF v_status_id IS NOT NULL THEN
    v_old_lead := public.lead_log_snapshot(p_lead_id);

    UPDATE public.leads
    SET
      module_status_id = v_status_id,
      updated_at = now()
    WHERE id = p_lead_id
      AND org_id = v_org_id
      AND deleted_at IS NULL;

    v_new_lead := public.lead_log_snapshot(p_lead_id);

    PERFORM public.log_data_change(
      v_org_id,
      'leads',
      p_lead_id,
      'Lead converted to opportunity',
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

-- ---------------------------------------------------------------------------
-- Update / soft delete
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.update_opportunity(
  p_opportunity_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_row public.opportunities%ROWTYPE;
  v_stage_probability integer;
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
      nullif(trim(p_payload->>'probability'), '')::integer,
      CASE WHEN nullif(trim(p_payload->>'stage_id'), '') IS NOT NULL THEN v_stage_probability ELSE NULL END,
      probability
    ),
    estimated_value = coalesce(nullif(trim(p_payload->>'estimated_value'), '')::numeric, estimated_value),
    close_date = CASE
      WHEN p_payload ? 'close_date' THEN nullif(trim(p_payload->>'close_date'), '')::date
      ELSE close_date
    END,
    description = CASE
      WHEN p_payload ? 'description' THEN nullif(trim(p_payload->>'description'), '')
      ELSE description
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

CREATE OR REPLACE FUNCTION public.soft_delete_opportunity(p_opportunity_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
BEGIN
  IF v_org_id IS NULL OR NOT public.is_active_user() OR public.is_readonly() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.opportunity_log_snapshot(p_opportunity_id);

  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Opportunity not found';
  END IF;

  UPDATE public.opportunities
  SET
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_opportunity_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  PERFORM public.log_data_change(
    v_org_id,
    'opportunities',
    p_opportunity_id,
    'Soft deleted opportunity',
    v_old_data,
    NULL,
    jsonb_build_object('source', 'soft_delete_opportunity', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Backfill job code sequences for existing orgs
DO $$
DECLARE
  v_org_id uuid;
BEGIN
  FOR v_org_id IN SELECT id FROM public.organizations LOOP
    PERFORM public.seed_org_module_defaults(v_org_id, 'opportunity');
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.ensure_opportunity_module_defaults() TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_opportunities(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_opportunity_by_lead(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_opportunity_from_lead(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_opportunity(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.soft_delete_opportunity(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.opportunity_log_snapshot(uuid) TO authenticated;

NOTIFY pgrst, 'reload schema';
