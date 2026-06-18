-- Add master.partner permission key + sales template view access

CREATE OR REPLACE FUNCTION public.org_role_permission_keys()
RETURNS text[] AS $$
  SELECT ARRAY[
    'app.dashboard', 'app.tasks', 'app.lead', 'app.opportunity', 'app.quotations',
    'app.pipeline', 'app.salesOrder', 'app.invoices', 'app.reports', 'app.projects',
    'app.contractAgreements', 'app.service',
    'master.customer', 'master.contact', 'master.salesTarget', 'master.products',
    'master.category', 'master.leadSource', 'master.partner', 'master.unit', 'master.employee',
    'master.salesTeam', 'master.roles', 'master.moduleStatuses', 'master.jobCode'
  ]::text[];
$$ LANGUAGE sql IMMUTABLE;

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
      "master.partner": ["view"],
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

NOTIFY pgrst, 'reload schema';
