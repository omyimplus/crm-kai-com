-- List data change logs for Setup → User Activity (กฎเหล็ก §13)
-- Docs: docs/06-crm-schema/DATA-CHANGE-LOG.md

CREATE OR REPLACE FUNCTION public.list_data_change_logs(
  p_limit integer DEFAULT 100,
  p_offset integer DEFAULT 0,
  p_entity_type text DEFAULT NULL,
  p_action text DEFAULT NULL
)
RETURNS TABLE (
  id uuid,
  actor_id uuid,
  actor_name text,
  action text,
  entity_type text,
  entity_id uuid,
  summary text,
  old_data jsonb,
  new_data jsonb,
  metadata jsonb,
  created_at timestamptz
) AS $$
BEGIN
  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  RETURN QUERY
  SELECT
    l.id,
    l.actor_id,
    COALESCE(p.full_name, p.username, u.email::text, '—') AS actor_name,
    l.action,
    l.entity_type,
    l.entity_id,
    l.summary,
    l.old_data,
    l.new_data,
    l.metadata,
    l.created_at
  FROM public.data_change_logs l
  LEFT JOIN public.profiles p ON p.id = l.actor_id
  LEFT JOIN auth.users u ON u.id = l.actor_id
  WHERE l.org_id = public.current_org_id()
    AND (p_entity_type IS NULL OR l.entity_type = p_entity_type)
    AND (p_action IS NULL OR l.action = p_action)
  ORDER BY l.created_at DESC
  LIMIT GREATEST(1, LEAST(COALESCE(p_limit, 100), 500))
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public, auth;

GRANT EXECUTE ON FUNCTION public.list_data_change_logs(integer, integer, text, text) TO authenticated;
