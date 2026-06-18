-- Product main image: image_url column + org-images/products storage policies

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS image_url text;

CREATE OR REPLACE FUNCTION public.product_log_snapshot(p_product_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', p.id,
    'product_code', p.product_code,
    'name', p.name,
    'description', p.description,
    'category_id', p.category_id,
    'category_label', (
      SELECT c.category_code || ' · ' || c.name
      FROM public.categories c
      WHERE c.id = p.category_id
    ),
    'image_url', p.image_url,
    'unit', p.unit,
    'list_price', p.list_price,
    'cost_price', p.cost_price,
    'currency', p.currency,
    'barcode', p.barcode,
    'status', p.status,
    'is_sellable', p.is_sellable,
    'notes', p.notes
  )
  FROM public.products p
  WHERE p.id = p_product_id
    AND p.org_id = public.current_org_id()
    AND p.deleted_at IS NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.product_deleted_snapshot(p_product_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', p.id,
    'product_code', p.product_code,
    'name', p.name,
    'description', p.description,
    'category_id', p.category_id,
    'category_label', (
      SELECT c.category_code || ' · ' || c.name
      FROM public.categories c
      WHERE c.id = p.category_id
    ),
    'image_url', p.image_url,
    'unit', p.unit,
    'list_price', p.list_price,
    'cost_price', p.cost_price,
    'currency', p.currency,
    'barcode', p.barcode,
    'status', p.status,
    'is_sellable', p.is_sellable,
    'notes', p.notes,
    'deleted_at', p.deleted_at
  )
  FROM public.products p
  WHERE p.id = p_product_id
    AND p.org_id = public.current_org_id()
    AND p.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_product(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_id uuid;
  v_new_data jsonb;
  v_code text;
  v_category_id uuid;
  v_image_url text := NULLIF(btrim(p_payload->>'image_url'), '');
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_code := trim(p_payload->>'product_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Product code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Product name required';
  END IF;

  v_category_id := NULLIF(trim(p_payload->>'category_id'), '')::uuid;
  PERFORM public.product_validate_category(v_category_id);

  INSERT INTO public.products (
    org_id,
    product_code,
    name,
    description,
    category_id,
    image_url,
    unit,
    list_price,
    cost_price,
    currency,
    barcode,
    status,
    is_sellable,
    notes,
    created_by
  ) VALUES (
    v_org_id,
    v_code,
    trim(p_payload->>'name'),
    nullif(trim(p_payload->>'description'), ''),
    v_category_id,
    v_image_url,
    nullif(trim(p_payload->>'unit'), ''),
    coalesce((p_payload->>'list_price')::numeric, 0),
    nullif(trim(p_payload->>'cost_price'), '')::numeric,
    coalesce(nullif(trim(p_payload->>'currency'), ''), 'THB'),
    nullif(trim(p_payload->>'barcode'), ''),
    coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    coalesce((p_payload->>'is_sellable')::boolean, true),
    nullif(trim(p_payload->>'notes'), ''),
    auth.uid()
  )
  RETURNING id INTO v_id;

  v_new_data := public.product_log_snapshot(v_id);

  PERFORM public.write_data_change_log(
    'create',
    'products',
    v_id,
    'Created product',
    NULL,
    v_new_data,
    jsonb_build_object('source', 'create_product')
  );

  RETURN v_id;
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate product code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.update_product(
  p_product_id uuid,
  p_payload jsonb
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_code text;
  v_category_id uuid;
  v_set_image boolean := coalesce((p_payload->>'set_image')::boolean, false);
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_code := trim(p_payload->>'product_code');
  IF coalesce(v_code, '') = '' THEN
    RAISE EXCEPTION 'Product code required';
  END IF;

  IF coalesce(trim(p_payload->>'name'), '') = '' THEN
    RAISE EXCEPTION 'Product name required';
  END IF;

  v_old_data := public.product_log_snapshot(p_product_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  v_category_id := NULLIF(trim(p_payload->>'category_id'), '')::uuid;
  PERFORM public.product_validate_category(v_category_id);

  UPDATE public.products
  SET
    product_code = v_code,
    name = trim(p_payload->>'name'),
    description = nullif(trim(p_payload->>'description'), ''),
    category_id = v_category_id,
    image_url = CASE
      WHEN v_set_image THEN NULLIF(btrim(p_payload->>'image_url'), '')
      ELSE image_url
    END,
    unit = nullif(trim(p_payload->>'unit'), ''),
    list_price = coalesce((p_payload->>'list_price')::numeric, 0),
    cost_price = nullif(trim(p_payload->>'cost_price'), '')::numeric,
    currency = coalesce(nullif(trim(p_payload->>'currency'), ''), 'THB'),
    barcode = nullif(trim(p_payload->>'barcode'), ''),
    status = coalesce(nullif(trim(p_payload->>'status'), ''), 'active'),
    is_sellable = coalesce((p_payload->>'is_sellable')::boolean, true),
    notes = nullif(trim(p_payload->>'notes'), ''),
    updated_at = now()
  WHERE id = p_product_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  v_new_data := public.product_log_snapshot(p_product_id);

  PERFORM public.write_data_change_log(
    'update',
    'products',
    p_product_id,
    'Updated product',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'update_product')
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate product code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP POLICY IF EXISTS "Org members can upload product images" ON storage.objects;
CREATE POLICY "Org members can upload product images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'org-images'
  AND public.is_active_user()
  AND NOT public.is_readonly()
  AND (storage.foldername(name))[1] = public.current_org_id()::text
  AND (storage.foldername(name))[2] = 'products'
);

DROP POLICY IF EXISTS "Org members can update product images" ON storage.objects;
CREATE POLICY "Org members can update product images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'org-images'
  AND public.is_active_user()
  AND NOT public.is_readonly()
  AND (storage.foldername(name))[1] = public.current_org_id()::text
  AND (storage.foldername(name))[2] = 'products'
);

DROP POLICY IF EXISTS "Org members can delete product images" ON storage.objects;
CREATE POLICY "Org members can delete product images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'org-images'
  AND public.is_active_user()
  AND NOT public.is_readonly()
  AND (storage.foldername(name))[1] = public.current_org_id()::text
  AND (storage.foldername(name))[2] = 'products'
);

NOTIFY pgrst, 'reload schema';
