-- Legacy org role templates (Manager, Sales, CS, Engineer) — Admin stays platform role only
-- Sync with frontend/app/config/orgRoleTemplates.ts

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
  FOR v_template IN
    SELECT *
    FROM (VALUES
      ('manager', 'Manager', 'หัวหน้าทีม — เข้าถึง CRM และ Master Data เกือบทั้งหมด'),
      ('sales', 'Sales', 'ฝ่ายขาย — Lead, Opportunity, Pipeline, ใบเสนอราคา'),
      ('cs', 'CS', 'Customer Service — งานบริการลูกค้าและข้อมูลลูกค้า'),
      ('engineer', 'Engineer', 'วิศวกร — โครงการ, สัญญา, งานบริการ')
    ) AS t(code, label, description)
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
    ON CONFLICT (org_id, code) DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Backfill every existing organization
DO $$
DECLARE
  v_org_id uuid;
BEGIN
  FOR v_org_id IN SELECT id FROM public.organizations
  LOOP
    PERFORM public.seed_org_role_templates(v_org_id);
  END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION public.org_role_template_permissions(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.seed_org_role_templates(uuid) TO authenticated;
