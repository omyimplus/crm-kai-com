-- Fix list_org_roles when migration 19 partially applied or schema cache stale
-- Safe to re-run (idempotent)

CREATE TABLE IF NOT EXISTS public.profile_org_roles (
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  org_role_id uuid NOT NULL REFERENCES public.org_roles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (profile_id, org_role_id)
);

CREATE INDEX IF NOT EXISTS idx_profile_org_roles_org_role_id
  ON public.profile_org_roles (org_role_id);

INSERT INTO public.profile_org_roles (profile_id, org_role_id)
SELECT p.id, p.org_role_id
FROM public.profiles p
WHERE p.org_role_id IS NOT NULL
ON CONFLICT DO NOTHING;

ALTER TABLE public.profile_org_roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profile_org_roles_select ON public.profile_org_roles;

CREATE POLICY profile_org_roles_select ON public.profile_org_roles FOR SELECT
  USING (
    profile_id = auth.uid()
    OR public.is_admin_or_owner()
  );

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
    (
      SELECT COUNT(DISTINCT x.profile_id)
      FROM (
        SELECT por.profile_id
        FROM public.profile_org_roles por
        WHERE por.org_role_id = r.id
        UNION
        SELECT p.id
        FROM public.profiles p
        WHERE p.org_role_id = r.id
      ) x
    ) AS user_count,
    r.created_at,
    r.updated_at
  FROM public.org_roles r
  WHERE r.org_id = public.current_org_id()
  ORDER BY r.is_system DESC, r.label ASC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.list_org_roles() TO authenticated;

NOTIFY pgrst, 'reload schema';
