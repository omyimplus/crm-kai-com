-- Remove master.roles from org role permission keys (Roles moved to Setup — not org-permission gated)

CREATE OR REPLACE FUNCTION public.org_role_permission_keys()
RETURNS text[] AS $$
  SELECT ARRAY[
    'app.dashboard', 'app.tasks', 'app.lead', 'app.opportunity', 'app.quotations',
    'app.pipeline', 'app.salesOrder', 'app.invoices', 'app.reports', 'app.projects',
    'app.contractAgreements', 'app.service',
    'master.customer', 'master.contact', 'master.salesTarget', 'master.products',
    'master.category', 'master.leadSource', 'master.unit', 'master.employee',
    'master.salesTeam', 'master.moduleStatuses', 'master.jobCode'
  ]::text[];
$$ LANGUAGE sql IMMUTABLE;

UPDATE public.org_roles
SET permissions = public.normalize_org_role_permissions(permissions);
