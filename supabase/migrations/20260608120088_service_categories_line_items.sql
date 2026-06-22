-- Service categories (module_key) · services master · opportunity line items
-- Docs: CATEGORY-HIERARCHY.md · OPPORTUNITIES-MODULE.md

-- ---------------------------------------------------------------------------
-- Categories: allow service tree
-- ---------------------------------------------------------------------------
ALTER TABLE public.categories
  DROP CONSTRAINT IF EXISTS categories_module_key_check;

ALTER TABLE public.categories
  ADD CONSTRAINT categories_module_key_check
  CHECK (module_key IN ('product', 'service'));

-- ---------------------------------------------------------------------------
-- Services master (repair, MA, installation, …)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.services (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  service_code text NOT NULL,
  name text NOT NULL,
  description text,
  category_id uuid REFERENCES public.categories(id) ON DELETE SET NULL,
  unit_id uuid REFERENCES public.units(id) ON DELETE SET NULL,
  list_price numeric(15, 2) NOT NULL DEFAULT 0,
  cost_price numeric(15, 2),
  currency text NOT NULL DEFAULT 'THB',
  service_kind text NOT NULL DEFAULT 'other',
  status text NOT NULL DEFAULT 'active',
  is_sellable boolean NOT NULL DEFAULT true,
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT services_status_check CHECK (status IN ('active', 'inactive')),
  CONSTRAINT services_list_price_check CHECK (list_price >= 0),
  CONSTRAINT services_cost_price_check CHECK (cost_price IS NULL OR cost_price >= 0),
  CONSTRAINT services_currency_check CHECK (currency IN ('THB', 'USD')),
  CONSTRAINT services_kind_check CHECK (
    service_kind IN ('repair', 'maintenance', 'installation', 'consulting', 'other')
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS services_unique_code_active_idx
  ON public.services (org_id, lower(trim(service_code)))
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_services_org_category
  ON public.services (org_id, category_id)
  WHERE deleted_at IS NULL;

DROP TRIGGER IF EXISTS services_updated_at ON public.services;
CREATE TRIGGER services_updated_at
  BEFORE UPDATE ON public.services
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS services_select ON public.services;
CREATE POLICY services_select ON public.services FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (deleted_at IS NULL OR public.is_admin_or_owner())
  );

DROP POLICY IF EXISTS services_insert ON public.services FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

DROP POLICY IF EXISTS services_update ON public.services FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

CREATE OR REPLACE FUNCTION public.service_validate_category(p_category_id uuid)
RETURNS void AS $$
BEGIN
  IF p_category_id IS NULL THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.categories c
    WHERE c.id = p_category_id
      AND c.org_id = public.current_org_id()
      AND c.module_key = 'service'
      AND c.deleted_at IS NULL
      AND c.status = 'active'
  ) THEN
    RAISE EXCEPTION 'Invalid service category';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.service_log_snapshot(p_service_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', s.id,
    'service_code', s.service_code,
    'name', s.name,
    'description', s.description,
    'category_id', s.category_id,
    'unit_id', s.unit_id,
    'list_price', s.list_price,
    'cost_price', s.cost_price,
    'currency', s.currency,
    'service_kind', s.service_kind,
    'status', s.status,
    'is_sellable', s.is_sellable,
    'notes', s.notes
  )
  FROM public.services s
  WHERE s.id = p_service_id
    AND s.org_id = public.current_org_id()
    AND s.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_service(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_id uuid;
  v_code text;
  v_category_id uuid;
  v_new_data jsonb;
BEGIN
  IF v_org_id IS NULL OR NOT public.is_active_user() OR public.is_readonly() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_code := trim(p_payload->>'service_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Service code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Service name required';
  END IF;

  v_category_id := nullif(trim(p_payload->>'category_id'), '')::uuid;
  PERFORM public.service_validate_category(v_category_id);

  INSERT INTO public.services (
    org_id,
    service_code,
    name,
    description,
    category_id,
    unit_id,
    list_price,
    cost_price,
    currency,
    service_kind,
    status,
    is_sellable,
    notes,
    created_by
  ) VALUES (
    v_org_id,
    v_code,
    trim(p_payload->>'name'),
    nullif(trim(p_payload->>'description'), ''),
    v_category_id,
    nullif(trim(p_payload->>'unit_id'), '')::uuid,
    coalesce((p_payload->>'list_price')::numeric, 0),
    nullif(trim(p_payload->>'cost_price'), '')::numeric,
    coalesce(nullif(trim(p_payload->>'currency'), ''), 'THB'),
    coalesce(nullif(trim(p_payload->>'service_kind'), ''), 'other'),
    coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    coalesce((p_payload->>'is_sellable')::boolean, true),
    nullif(trim(p_payload->>'notes'), ''),
    auth.uid()
  )
  RETURNING id INTO v_id;

  v_new_data := public.service_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'services',
    v_id,
    'Created service',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_service')
  );

  RETURN v_id;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate service code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.create_service(jsonb) TO authenticated;

-- ---------------------------------------------------------------------------
-- Opportunity line items
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.opportunity_line_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  opportunity_id uuid NOT NULL REFERENCES public.opportunities(id) ON DELETE CASCADE,
  line_type text NOT NULL,
  category_id uuid REFERENCES public.categories(id) ON DELETE SET NULL,
  category_path jsonb NOT NULL DEFAULT '[]'::jsonb,
  product_id uuid REFERENCES public.products(id) ON DELETE SET NULL,
  service_id uuid REFERENCES public.services(id) ON DELETE SET NULL,
  item_name text,
  line_description text,
  quantity numeric(15, 4) NOT NULL DEFAULT 1,
  unit_price numeric(15, 2) NOT NULL DEFAULT 0,
  line_total numeric(15, 2) NOT NULL DEFAULT 0,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT opportunity_line_items_type_check CHECK (line_type IN ('product', 'service')),
  CONSTRAINT opportunity_line_items_quantity_check CHECK (quantity > 0),
  CONSTRAINT opportunity_line_items_unit_price_check CHECK (unit_price >= 0),
  CONSTRAINT opportunity_line_items_line_total_check CHECK (line_total >= 0)
);

CREATE INDEX IF NOT EXISTS idx_opportunity_line_items_opportunity
  ON public.opportunity_line_items (opportunity_id, sort_order);

ALTER TABLE public.opportunity_line_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS opportunity_line_items_select ON public.opportunity_line_items;
CREATE POLICY opportunity_line_items_select ON public.opportunity_line_items FOR SELECT
  USING (org_id = public.current_org_id() AND public.is_active_user());

DROP POLICY IF EXISTS opportunity_line_items_insert ON public.opportunity_line_items;
CREATE POLICY opportunity_line_items_insert ON public.opportunity_line_items FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

DROP POLICY IF EXISTS opportunity_line_items_update ON public.opportunity_line_items;
CREATE POLICY opportunity_line_items_update ON public.opportunity_line_items FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

DROP POLICY IF EXISTS opportunity_line_items_delete ON public.opportunity_line_items;
CREATE POLICY opportunity_line_items_delete ON public.opportunity_line_items FOR DELETE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

DROP TRIGGER IF EXISTS opportunity_line_items_updated_at ON public.opportunity_line_items;
CREATE TRIGGER opportunity_line_items_updated_at
  BEFORE UPDATE ON public.opportunity_line_items
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.sync_opportunity_line_items(
  p_opportunity_id uuid,
  p_line_items jsonb
)
RETURNS numeric AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_item jsonb;
  v_idx integer := 0;
  v_total numeric := 0;
  v_qty numeric;
  v_unit_price numeric;
  v_line_total numeric;
  v_path jsonb;
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

  DELETE FROM public.opportunity_line_items li
  WHERE li.opportunity_id = p_opportunity_id
    AND li.org_id = v_org_id;

  FOR v_item IN
    SELECT value
    FROM jsonb_array_elements(coalesce(p_line_items, '[]'::jsonb))
  LOOP
    v_qty := coalesce(nullif(trim(v_item->>'quantity'), '')::numeric, 1);
    IF v_qty <= 0 THEN
      v_qty := 1;
    END IF;

    v_unit_price := coalesce(nullif(trim(v_item->>'unit_price'), '')::numeric, 0);
    v_line_total := coalesce(
      nullif(trim(v_item->>'line_total'), '')::numeric,
      round(v_qty * v_unit_price, 2)
    );

    v_path := coalesce(v_item->'category_path', '[]'::jsonb);
    IF jsonb_typeof(v_path) <> 'array' THEN
      v_path := '[]'::jsonb;
    END IF;

    INSERT INTO public.opportunity_line_items (
      org_id,
      opportunity_id,
      line_type,
      category_id,
      category_path,
      product_id,
      service_id,
      item_name,
      line_description,
      quantity,
      unit_price,
      line_total,
      sort_order
    ) VALUES (
      v_org_id,
      p_opportunity_id,
      coalesce(nullif(trim(v_item->>'line_type'), ''), 'product'),
      nullif(trim(v_item->>'category_id'), '')::uuid,
      v_path,
      nullif(trim(v_item->>'product_id'), '')::uuid,
      nullif(trim(v_item->>'service_id'), '')::uuid,
      nullif(trim(v_item->>'item_name'), ''),
      nullif(trim(v_item->>'line_description'), ''),
      v_qty,
      v_unit_price,
      v_line_total,
      v_idx
    );

    v_total := v_total + v_line_total;
    v_idx := v_idx + 1;
  END LOOP;

  UPDATE public.opportunities o
  SET
    estimated_value = v_total,
    updated_at = now()
  WHERE o.id = p_opportunity_id
    AND o.org_id = v_org_id
    AND o.deleted_at IS NULL;

  RETURN v_total;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.list_opportunity_line_items(p_opportunity_id uuid)
RETURNS TABLE (
  id uuid,
  opportunity_id uuid,
  line_type text,
  category_id uuid,
  category_path jsonb,
  product_id uuid,
  service_id uuid,
  item_name text,
  line_description text,
  quantity numeric,
  unit_price numeric,
  line_total numeric,
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
    li.id,
    li.opportunity_id,
    li.line_type,
    li.category_id,
    li.category_path,
    li.product_id,
    li.service_id,
    li.item_name,
    li.line_description,
    li.quantity,
    li.unit_price,
    li.line_total,
    li.sort_order,
    li.created_at,
    li.updated_at
  FROM public.opportunity_line_items li
  JOIN public.opportunities o ON o.id = li.opportunity_id AND o.deleted_at IS NULL
  WHERE li.opportunity_id = p_opportunity_id
    AND li.org_id = public.current_org_id()
  ORDER BY li.sort_order, li.created_at;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.sync_opportunity_line_items(uuid, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_opportunity_line_items(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.sync_opportunity_content(
  p_opportunity_id uuid,
  p_payload jsonb
)
RETURNS numeric AS $$
BEGIN
  IF p_payload ? 'line_items' THEN
    RETURN public.sync_opportunity_line_items(p_opportunity_id, p_payload->'line_items');
  END IF;

  IF p_payload ? 'projects' THEN
    RETURN public.sync_opportunity_projects(p_opportunity_id, p_payload->'projects');
  END IF;

  RETURN coalesce(
    (
      SELECT o.estimated_value
      FROM public.opportunities o
      WHERE o.id = p_opportunity_id
    ),
    0
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.sync_opportunity_content(uuid, jsonb) TO authenticated;

-- Patch create_opportunity (standalone) — line_items support
CREATE OR REPLACE FUNCTION public.create_opportunity(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_pipeline_id uuid;
  v_stage_id uuid;
  v_stage_probability integer;
  v_code text;
  v_id uuid;
  v_company_id uuid;
  v_new_data jsonb;
  v_projects jsonb;
BEGIN
  IF v_org_id IS NULL OR NOT public.is_active_user() OR public.is_readonly() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  PERFORM public.ensure_opportunity_module_defaults();

  IF coalesce(trim(p_payload->>'title'), '') = '' THEN
    RAISE EXCEPTION 'Opportunity title required';
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

  SELECT p.id INTO v_pipeline_id
  FROM public.pipelines p
  WHERE p.org_id = v_org_id
    AND p.is_default = true
  LIMIT 1;

  IF v_pipeline_id IS NULL THEN
    RAISE EXCEPTION 'Default pipeline not found';
  END IF;

  v_stage_id := nullif(trim(p_payload->>'stage_id'), '')::uuid;
  IF v_stage_id IS NULL THEN
    SELECT ps.id INTO v_stage_id
    FROM public.pipeline_stages ps
    WHERE ps.pipeline_id = v_pipeline_id
      AND ps.org_id = v_org_id
      AND NOT ps.is_won
      AND NOT ps.is_lost
    ORDER BY ps.sort_order
    LIMIT 1;
  END IF;

  SELECT ps.probability INTO v_stage_probability
  FROM public.pipeline_stages ps
  WHERE ps.id = v_stage_id
    AND ps.pipeline_id = v_pipeline_id
    AND ps.org_id = v_org_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid pipeline stage';
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
      (SELECT b.address FROM public.get_company_default_bill_address(v_company_id) b),
      ''
    ),
    auth.uid()
  )
  RETURNING id INTO v_id;

  PERFORM public.sync_opportunity_content(v_id, p_payload);

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

-- Patch create_opportunity_from_lead — line_items support
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
  v_sync_payload jsonb;
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

  IF NOT (p_payload ? 'line_items') THEN
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

  v_sync_payload := CASE
    WHEN p_payload ? 'line_items' THEN p_payload
    ELSE p_payload || jsonb_build_object('projects', v_projects)
  END;

  v_estimated_value := public.sync_opportunity_content(v_id, v_sync_payload);

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

-- Patch update_opportunity — line_items support
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

  IF p_payload ? 'line_items' OR p_payload ? 'projects' THEN
    v_new_estimated := public.sync_opportunity_content(p_opportunity_id, p_payload);
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
    WHERE id = p_opportunity_id;
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
    WHERE id = p_opportunity_id;

    IF v_new_estimated IS DISTINCT FROM v_row.estimated_value THEN
      v_old_lead := public.lead_log_snapshot(v_row.lead_id);

      UPDATE public.leads
      SET
        lead_value = v_new_estimated,
        updated_at = now()
      WHERE id = v_row.lead_id
        AND org_id = v_org_id
        AND deleted_at IS NULL;

      v_new_lead := public.lead_log_snapshot(v_row.lead_id);

      IF v_old_lead IS NOT NULL AND v_new_lead IS NOT NULL THEN
        PERFORM public.log_data_change(
          v_org_id,
          'leads',
          v_row.lead_id,
          'Synced lead value from opportunity',
          v_old_lead,
          v_new_lead,
          jsonb_build_object('source', 'update_opportunity', 'opportunity_id', p_opportunity_id)
        );
      END IF;
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

-- Patch create_opportunity_from_lead — line_items support
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
  v_sync_payload jsonb;
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

  IF NOT (p_payload ? 'line_items') THEN
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

  v_sync_payload := CASE
    WHEN p_payload ? 'line_items' THEN p_payload
    ELSE p_payload || jsonb_build_object('projects', v_projects)
  END;

  v_estimated_value := public.sync_opportunity_content(v_id, v_sync_payload);

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
