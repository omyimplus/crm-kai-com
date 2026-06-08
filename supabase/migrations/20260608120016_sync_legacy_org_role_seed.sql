-- Legacy org_role seed from old chip UI: Manager, Sales, CS, Engineer
-- (Admin chip = platform admin — not org_role)
-- Sync: frontend/app/config/orgRoleTemplates.ts + 20260608120012
-- Includes permission helpers from 20260608120007 when not yet applied

CREATE OR REPLACE FUNCTION public.org_role_permission_keys()
RETURNS text[] AS $$
  SELECT ARRAY[
    'app.dashboard', 'app.tasks', 'app.lead', 'app.opportunity', 'app.quotations',
    'app.pipeline', 'app.salesOrder', 'app.invoices', 'app.reports', 'app.projects',
    'app.contractAgreements', 'app.service',
    'master.customer', 'master.contact', 'master.salesTarget', 'master.products',
    'master.category', 'master.leadSource', 'master.unit', 'master.employee',
    'master.salesTeam', 'master.roles', 'master.moduleStatuses', 'master.jobCode'
  ]::text[];
$$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.org_role_module_actions(p_module_key text)
RETURNS text[] AS $$
BEGIN
  IF p_module_key = 'app.reports' THEN
    RETURN ARRAY['view', 'create', 'edit', 'delete', 'export'];
  ELSIF p_module_key LIKE 'app.%' THEN
    RETURN ARRAY['view', 'create', 'edit', 'delete'];
  ELSIF p_module_key LIKE 'master.%' THEN
    RETURN ARRAY['view', 'create', 'edit', 'delete'];
  END IF;
  RETURN ARRAY[]::text[];
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.normalize_org_role_permissions(p_permissions jsonb)
RETURNS jsonb AS $$
DECLARE
  v_key text;
  v_result jsonb := '{}'::jsonb;
  v_raw jsonb;
  v_action text;
  v_allowed text[];
  v_filtered jsonb := '[]'::jsonb;
BEGIN
  FOREACH v_key IN ARRAY public.org_role_permission_keys()
  LOOP
    v_allowed := public.org_role_module_actions(v_key);
    v_raw := COALESCE(p_permissions -> v_key, '[]'::jsonb);
    v_filtered := '[]'::jsonb;

    IF jsonb_typeof(v_raw) = 'array' THEN
      FOR v_action IN SELECT jsonb_array_elements_text(v_raw)
      LOOP
        IF v_action = ANY (v_allowed) THEN
          v_filtered := v_filtered || to_jsonb(v_action);
        END IF;
      END LOOP;
    END IF;

    v_result := v_result || jsonb_build_object(v_key, v_filtered);
  END LOOP;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.org_role_template_permissions(p_code text)
RETURNS jsonb AS $$
DECLARE
  v_raw jsonb;
BEGIN
  CASE lower(btrim(p_code))
  WHEN 'manager' THEN
    SELECT jsonb_object_agg(
      k,
      CASE
        WHEN k = 'app.reports' THEN '["view","create","edit","delete","export"]'::jsonb
        ELSE '["view","create","edit","delete"]'::jsonb
      END
    )
    INTO v_raw
    FROM unnest(public.org_role_permission_keys()) AS k;

  WHEN 'sales' THEN
    v_raw := '{
      "app.dashboard": ["view"],
      "app.tasks": ["view","create","edit"],
      "app.lead": ["view","create","edit","delete"],
      "app.opportunity": ["view","create","edit","delete"],
      "app.quotations": ["view","create","edit","delete"],
      "app.pipeline": ["view","create","edit"],
      "app.salesOrder": ["view","create","edit"],
      "app.invoices": ["view"],
      "app.reports": ["view","export"],
      "app.projects": ["view"],
      "app.contractAgreements": ["view"],
      "app.service": ["view"],
      "master.customer": ["view","create","edit"],
      "master.contact": ["view","create","edit"],
      "master.salesTarget": ["view"],
      "master.products": ["view"],
      "master.category": ["view"],
      "master.leadSource": ["view"],
      "master.unit": ["view"],
      "master.employee": ["view"],
      "master.salesTeam": ["view"]
    }'::jsonb;

  WHEN 'cs' THEN
    v_raw := '{
      "app.dashboard": ["view"],
      "app.tasks": ["view","create","edit"],
      "app.lead": ["view"],
      "app.opportunity": ["view"],
      "app.invoices": ["view"],
      "app.reports": ["view"],
      "app.projects": ["view"],
      "app.contractAgreements": ["view"],
      "app.service": ["view","create","edit","delete"],
      "master.customer": ["view","edit"],
      "master.contact": ["view","create","edit"],
      "master.products": ["view"],
      "master.moduleStatuses": ["view"]
    }'::jsonb;

  WHEN 'engineer' THEN
    v_raw := '{
      "app.dashboard": ["view"],
      "app.tasks": ["view","create","edit"],
      "app.projects": ["view","create","edit","delete"],
      "app.service": ["view","create","edit"],
      "app.contractAgreements": ["view","create","edit"],
      "app.reports": ["view"],
      "master.customer": ["view"],
      "master.contact": ["view"],
      "master.jobCode": ["view","create","edit"],
      "master.moduleStatuses": ["view"],
      "master.products": ["view"]
    }'::jsonb;

  ELSE
    RAISE EXCEPTION 'Unknown org role template: %', p_code;
  END CASE;

  RETURN public.normalize_org_role_permissions(v_raw);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.seed_org_role_templates(p_org_id uuid)
RETURNS void AS $$
DECLARE
  v_template record;
BEGIN
  IF p_org_id IS NULL THEN
    RETURN;
  END IF;

  FOR v_template IN
    SELECT *
    FROM (VALUES
      (1, 'manager', 'Manager', 'หัวหน้าทีม — เข้าถึง CRM และ Master Data เกือบทั้งหมด'),
      (2, 'sales', 'Sales', 'ฝ่ายขาย — Lead, Opportunity, Pipeline, ใบเสนอราคา'),
      (3, 'cs', 'CS', 'Customer Service — งานบริการลูกค้าและข้อมูลลูกค้า'),
      (4, 'engineer', 'Engineer', 'วิศวกร — โครงการ, สัญญา, งานบริการ')
    ) AS t(sort_order, code, label, description)
  LOOP
    INSERT INTO public.org_roles (
      org_id,
      code,
      label,
      description,
      permissions,
      is_system,
      is_active
    )
    VALUES (
      p_org_id,
      v_template.code,
      v_template.label,
      v_template.description,
      public.org_role_template_permissions(v_template.code),
      true,
      true
    )
    ON CONFLICT (org_id, code) DO UPDATE SET
      label = EXCLUDED.label,
      description = EXCLUDED.description,
      permissions = EXCLUDED.permissions,
      is_system = true,
      is_active = true,
      updated_at = now();
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.trg_organizations_seed_org_roles()
RETURNS trigger AS $$
BEGIN
  PERFORM public.seed_org_role_templates(NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS organizations_seed_org_roles ON public.organizations;

CREATE TRIGGER organizations_seed_org_roles
  AFTER INSERT ON public.organizations
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_organizations_seed_org_roles();

-- Demo org (Phase 1) — ensure exists before seed even if seed.sql not run
INSERT INTO public.organizations (id, name, slug, settings)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'Demo Corp',
  'demo',
  '{"currency": "THB", "timezone": "Asia/Bangkok"}'::jsonb
)
ON CONFLICT (slug) DO NOTHING;

-- Seed / refresh legacy roles for every org
DO $$
DECLARE
  v_org_id uuid;
BEGIN
  FOR v_org_id IN SELECT id FROM public.organizations
  LOOP
    PERFORM public.seed_org_role_templates(v_org_id);
  END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION public.org_role_permission_keys() TO authenticated;
GRANT EXECUTE ON FUNCTION public.org_role_module_actions(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.normalize_org_role_permissions(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.org_role_template_permissions(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.seed_org_role_templates(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.trg_organizations_seed_org_roles() TO authenticated;
