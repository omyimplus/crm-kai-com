-- Products: link to categories via category_id (replace legacy text category)
-- Docs: PRODUCT-MASTER-FIELDS.md · CATEGORY-MASTER-FIELDS.md

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES public.categories(id) ON DELETE SET NULL;

UPDATE public.products p
SET category_id = c.id
FROM public.categories c
WHERE p.category_id IS NULL
  AND p.category IS NOT NULL
  AND btrim(p.category) <> ''
  AND c.org_id = p.org_id
  AND c.module_key = 'product'
  AND c.deleted_at IS NULL
  AND (
    lower(btrim(c.category_code)) = lower(btrim(p.category))
    OR lower(btrim(c.name)) = lower(btrim(p.category))
  );

ALTER TABLE public.products
  DROP COLUMN IF EXISTS category;

CREATE INDEX IF NOT EXISTS idx_products_org_category
  ON public.products (org_id, category_id)
  WHERE deleted_at IS NULL;

CREATE OR REPLACE FUNCTION public.product_validate_category(p_category_id uuid)
RETURNS void AS $$
BEGIN
  IF p_category_id IS NULL THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.categories c
    WHERE c.id = p_category_id
      AND c.org_id = public.current_org_id()
      AND c.module_key = 'product'
      AND c.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Category not found';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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

CREATE OR REPLACE FUNCTION public.soft_delete_category(p_category_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.category_log_snapshot(p_category_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Category not found';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.categories c
    WHERE c.parent_id = p_category_id
      AND c.org_id = v_org_id
      AND c.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Category has child categories';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.products p
    WHERE p.category_id = p_category_id
      AND p.org_id = v_org_id
      AND p.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Category has products';
  END IF;

  UPDATE public.categories
  SET
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_category_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Category not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'categories',
    p_category_id,
    'Soft deleted category',
    v_old_data,
    jsonb_build_object('deleted_at', now()),
    jsonb_build_object('source', 'soft_delete_category', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

NOTIFY pgrst, 'reload schema';
