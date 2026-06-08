-- Org role permissions — normalize keys, get/delete role, sync on create/delete
-- Keys mirror frontend/app/config/permissionModules.ts

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

CREATE OR REPLACE FUNCTION public.get_org_role(p_role_id uuid)
RETURNS TABLE (
  id uuid,
  org_id uuid,
  code text,
  label text,
  description text,
  permissions jsonb,
  is_system boolean,
  is_active boolean,
  user_count bigint,
  created_at timestamptz,
  updated_at timestamptz
) AS $$
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  RETURN QUERY
  SELECT
    r.id,
    r.org_id,
    r.code,
    r.label,
    r.description,
    public.normalize_org_role_permissions(r.permissions) AS permissions,
    r.is_system,
    r.is_active,
    COUNT(p.id) AS user_count,
    r.created_at,
    r.updated_at
  FROM public.org_roles r
  LEFT JOIN public.profiles p ON p.org_role_id = r.id
  WHERE r.id = p_role_id
    AND r.org_id = public.current_org_id()
  GROUP BY r.id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_org_role(
  p_code text,
  p_label text,
  p_description text DEFAULT NULL,
  p_permissions jsonb DEFAULT '{}'::jsonb
)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_code text := lower(btrim(p_code));
  v_role_id uuid;
  v_permissions jsonb;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF v_code IS NULL OR v_code = '' THEN
    RAISE EXCEPTION 'Code is required';
  END IF;

  IF v_code !~ '^[a-z][a-z0-9_]{1,48}$' THEN
    RAISE EXCEPTION 'Invalid code format';
  END IF;

  IF NULLIF(btrim(p_label), '') IS NULL THEN
    RAISE EXCEPTION 'Label is required';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.org_roles
    WHERE org_id = v_org_id AND code = v_code
  ) THEN
    RAISE EXCEPTION 'Role code already exists';
  END IF;

  v_permissions := public.normalize_org_role_permissions(COALESCE(p_permissions, '{}'::jsonb));

  INSERT INTO public.org_roles (org_id, code, label, description, permissions)
  VALUES (
    v_org_id,
    v_code,
    btrim(p_label),
    NULLIF(btrim(p_description), ''),
    v_permissions
  )
  RETURNING id INTO v_role_id;

  PERFORM public.write_data_change_log(
    'create',
    'org_roles',
    v_role_id,
    'Created org role',
    NULL,
    public.org_role_log_snapshot(v_role_id),
    jsonb_build_object('source', 'create_org_role')
  );

  RETURN v_role_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_org_role(
  p_role_id uuid,
  p_label text DEFAULT NULL,
  p_description text DEFAULT NULL,
  p_permissions jsonb DEFAULT NULL,
  p_is_active boolean DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.org_roles
    WHERE id = p_role_id AND org_id = v_org_id
  ) THEN
    RAISE EXCEPTION 'Role not found';
  END IF;

  v_old_data := public.org_role_log_snapshot(p_role_id);

  UPDATE public.org_roles
  SET
    label = COALESCE(NULLIF(btrim(p_label), ''), label),
    description = CASE
      WHEN p_description IS NULL THEN description
      ELSE NULLIF(btrim(p_description), '')
    END,
    permissions = CASE
      WHEN p_permissions IS NULL THEN permissions
      ELSE public.normalize_org_role_permissions(p_permissions)
    END,
    is_active = COALESCE(p_is_active, is_active),
    updated_at = now()
  WHERE id = p_role_id AND org_id = v_org_id;

  v_new_data := public.org_role_log_snapshot(p_role_id);

  PERFORM public.write_data_change_log(
    'update',
    'org_roles',
    p_role_id,
    'Updated org role',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_org_role')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.delete_org_role(p_role_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_role public.org_roles%ROWTYPE;
  v_old_data jsonb;
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT * INTO v_role
  FROM public.org_roles
  WHERE id = p_role_id AND org_id = v_org_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Role not found';
  END IF;

  IF v_role.is_system THEN
    RAISE EXCEPTION 'Cannot delete system role';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.profiles
    WHERE org_role_id = p_role_id
  ) THEN
    RAISE EXCEPTION 'Role has assigned users';
  END IF;

  v_old_data := public.org_role_log_snapshot(p_role_id);

  DELETE FROM public.org_roles
  WHERE id = p_role_id AND org_id = v_org_id;

  PERFORM public.write_data_change_log(
    'delete',
    'org_roles',
    p_role_id,
    'Deleted org role',
    v_old_data,
    NULL,
    jsonb_build_object('source', 'delete_org_role')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.list_org_roles()
RETURNS TABLE (
  id uuid,
  org_id uuid,
  code text,
  label text,
  description text,
  permissions jsonb,
  is_system boolean,
  is_active boolean,
  user_count bigint,
  created_at timestamptz,
  updated_at timestamptz
) AS $$
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  RETURN QUERY
  SELECT
    r.id,
    r.org_id,
    r.code,
    r.label,
    r.description,
    public.normalize_org_role_permissions(r.permissions) AS permissions,
    r.is_system,
    r.is_active,
    COUNT(p.id) AS user_count,
    r.created_at,
    r.updated_at
  FROM public.org_roles r
  LEFT JOIN public.profiles p ON p.org_role_id = r.id
  WHERE r.org_id = public.current_org_id()
  GROUP BY r.id
  ORDER BY r.is_system DESC, r.label ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- Backfill existing roles with full permission key set
UPDATE public.org_roles
SET permissions = public.normalize_org_role_permissions(permissions),
    updated_at = now()
WHERE permissions IS DISTINCT FROM public.normalize_org_role_permissions(permissions);

GRANT EXECUTE ON FUNCTION public.org_role_permission_keys() TO authenticated;
GRANT EXECUTE ON FUNCTION public.normalize_org_role_permissions(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_org_role(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_org_role(uuid) TO authenticated;
