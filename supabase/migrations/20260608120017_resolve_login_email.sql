-- Login: accept username (profiles) or email — resolve to auth.users.email before signInWithPassword

CREATE OR REPLACE FUNCTION public.resolve_login_email(p_identifier text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_id text := lower(btrim(p_identifier));
  v_email text;
  v_count bigint;
BEGIN
  IF v_id IS NULL OR v_id = '' THEN
    RETURN NULL;
  END IF;

  IF position('@' in v_id) > 0 THEN
    SELECT u.email::text
    INTO v_email
    FROM auth.users u
    WHERE lower(u.email::text) = v_id
    LIMIT 1;

    RETURN v_email;
  END IF;

  SELECT count(*), min(u.email::text)
  INTO v_count, v_email
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE lower(p.username) = v_id
    AND p.username IS NOT NULL
    AND btrim(p.username) <> '';

  IF v_count = 1 THEN
    RETURN v_email;
  END IF;

  RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.resolve_login_email(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_login_email(text) TO anon, authenticated;
