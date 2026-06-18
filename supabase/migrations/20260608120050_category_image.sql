-- Category main image: image_url column + org-images/categories storage policies

ALTER TABLE public.categories
  ADD COLUMN IF NOT EXISTS image_url text;

CREATE OR REPLACE FUNCTION public.category_log_snapshot(p_category_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', c.id,
    'module_key', c.module_key,
    'category_code', c.category_code,
    'name', c.name,
    'description', c.description,
    'parent_id', c.parent_id,
    'sort_order', c.sort_order,
    'color', c.color,
    'status', c.status,
    'notes', c.notes,
    'image_url', c.image_url
  )
  FROM public.categories c
  WHERE c.id = p_category_id
    AND c.org_id = public.current_org_id()
    AND c.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.category_deleted_snapshot(p_category_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', c.id,
    'module_key', c.module_key,
    'category_code', c.category_code,
    'name', c.name,
    'description', c.description,
    'parent_id', c.parent_id,
    'sort_order', c.sort_order,
    'color', c.color,
    'status', c.status,
    'notes', c.notes,
    'image_url', c.image_url,
    'deleted_at', c.deleted_at
  )
  FROM public.categories c
  WHERE c.id = p_category_id
    AND c.org_id = public.current_org_id()
    AND c.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_category(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_module_key text := coalesce(nullif(trim(p_payload->>'module_key'), ''), 'product');
  v_parent_id uuid;
  v_id uuid;
  v_new_data jsonb;
  v_code text;
  v_image_url text := NULLIF(btrim(p_payload->>'image_url'), '');
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_code := trim(p_payload->>'category_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Category code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Category name required';
  END IF;

  v_parent_id := NULLIF(trim(p_payload->>'parent_id'), '')::uuid;
  PERFORM public.category_validate_parent(NULL, v_parent_id, v_module_key);

  INSERT INTO public.categories (
    org_id,
    module_key,
    category_code,
    name,
    description,
    parent_id,
    sort_order,
    color,
    status,
    notes,
    image_url,
    created_by
  ) VALUES (
    v_org_id,
    v_module_key,
    v_code,
    trim(p_payload->>'name'),
    nullif(trim(p_payload->>'description'), ''),
    v_parent_id,
    coalesce((p_payload->>'sort_order')::integer, 0),
    nullif(trim(p_payload->>'color'), ''),
    coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    nullif(trim(p_payload->>'notes'), ''),
    v_image_url,
    auth.uid()
  )
  RETURNING id INTO v_id;

  v_new_data := public.category_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'categories',
    v_id,
    'Created category',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_category')
  );

  RETURN v_id;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate category code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_category(
  p_category_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_module_key text;
  v_parent_id uuid;
  v_old_data jsonb;
  v_new_data jsonb;
  v_code text;
  v_set_image boolean := coalesce((p_payload->>'set_image')::boolean, false);
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_code := trim(p_payload->>'category_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Category code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Category name required';
  END IF;

  v_old_data := public.category_log_snapshot(p_category_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Category not found';
  END IF;

  v_module_key := coalesce(v_old_data->>'module_key', 'product');
  v_parent_id := NULLIF(trim(p_payload->>'parent_id'), '')::uuid;
  PERFORM public.category_validate_parent(p_category_id, v_parent_id, v_module_key);

  UPDATE public.categories
  SET
    category_code = v_code,
    name = trim(p_payload->>'name'),
    description = nullif(trim(p_payload->>'description'), ''),
    parent_id = v_parent_id,
    sort_order = coalesce((p_payload->>'sort_order')::integer, 0),
    color = nullif(trim(p_payload->>'color'), ''),
    status = coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    notes = nullif(trim(p_payload->>'notes'), ''),
    image_url = CASE
      WHEN v_set_image THEN NULLIF(btrim(p_payload->>'image_url'), '')
      ELSE image_url
    END,
    updated_at = now()
  WHERE id = p_category_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Category not found';
  END IF;

  v_new_data := public.category_log_snapshot(p_category_id);

  PERFORM public.write_data_change_log(
    'update',
    'categories',
    p_category_id,
    'Updated category',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_category')
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate category code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP POLICY IF EXISTS "Org members can upload category images" ON storage.objects;
CREATE POLICY "Org members can upload category images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'org-images'
  AND public.is_active_user()
  AND NOT public.is_readonly()
  AND (storage.foldername(name))[1] = public.current_org_id()::text
  AND (storage.foldername(name))[2] = 'categories'
);

DROP POLICY IF EXISTS "Org members can update category images" ON storage.objects;
CREATE POLICY "Org members can update category images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'org-images'
  AND public.is_active_user()
  AND NOT public.is_readonly()
  AND (storage.foldername(name))[1] = public.current_org_id()::text
  AND (storage.foldername(name))[2] = 'categories'
);

DROP POLICY IF EXISTS "Org members can delete category images" ON storage.objects;
CREATE POLICY "Org members can delete category images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'org-images'
  AND public.is_active_user()
  AND NOT public.is_readonly()
  AND (storage.foldername(name))[1] = public.current_org_id()::text
  AND (storage.foldername(name))[2] = 'categories'
);

NOTIFY pgrst, 'reload schema';
