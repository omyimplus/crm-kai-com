-- Current user's org role permissions — for sidebar menu filtering
-- Docs: docs/06-crm-schema/ORG-ROLE-PERMISSIONS.md

CREATE OR REPLACE FUNCTION public.get_my_org_role_permissions()
RETURNS jsonb AS $$
  SELECT public.normalize_org_role_permissions(r.permissions)
  FROM public.profiles p
  JOIN public.org_roles r ON r.id = p.org_role_id
  WHERE p.id = auth.uid()
    AND r.is_active = true;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_my_org_role_permissions() TO authenticated;
