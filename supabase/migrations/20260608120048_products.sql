-- Products master data + CRUD RPC + data_change_logs
-- Docs: PRODUCT-MASTER-FIELDS.md · DATA-CHANGE-LOG.md

CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  product_code text NOT NULL,
  name text NOT NULL,
  description text,
  category text,
  unit text,
  list_price numeric(15, 2) NOT NULL DEFAULT 0,
  cost_price numeric(15, 2),
  currency text NOT NULL DEFAULT 'THB',
  barcode text,
  status text NOT NULL DEFAULT 'active',
  is_sellable boolean NOT NULL DEFAULT true,
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT products_status_check CHECK (status IN ('active', 'inactive')),
  CONSTRAINT products_list_price_check CHECK (list_price >= 0),
  CONSTRAINT products_cost_price_check CHECK (cost_price IS NULL OR cost_price >= 0),
  CONSTRAINT products_currency_check CHECK (currency IN ('THB', 'USD'))
);

CREATE UNIQUE INDEX IF NOT EXISTS products_unique_code_active_idx
  ON public.products (org_id, lower(trim(product_code)))
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_products_org_status
  ON public.products (org_id, status)
  WHERE deleted_at IS NULL;

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY products_select ON public.products FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
  );

CREATE POLICY products_insert ON public.products FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

CREATE POLICY products_update ON public.products FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

CREATE OR REPLACE FUNCTION public.product_log_snapshot(p_product_id uuid)
RETURNS jsonb AS $$
  SELECT jsonb_build_object(
    'id', p.id,
    'product_code', p.product_code,
    'name', p.name,
    'description', p.description,
    'category', p.category,
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
    'category', p.category,
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

  INSERT INTO public.products (
    org_id,
    product_code,
    name,
    description,
    category,
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
    nullif(trim(p_payload->>'category'), ''),
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

  UPDATE public.products
  SET
    product_code = v_code,
    name = trim(p_payload->>'name'),
    description = nullif(trim(p_payload->>'description'), ''),
    category = nullif(trim(p_payload->>'category'), ''),
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

CREATE OR REPLACE FUNCTION public.soft_delete_product(p_product_id uuid)
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

  v_old_data := public.product_log_snapshot(p_product_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  UPDATE public.products
  SET
    deleted_at = now(),
    updated_at = now()
  WHERE id = p_product_id
    AND org_id = v_org_id
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product not found';
  END IF;

  PERFORM public.write_data_change_log(
    'delete',
    'products',
    p_product_id,
    'Soft deleted product',
    v_old_data,
    jsonb_build_object('deleted_at', now()),
    jsonb_build_object('source', 'soft_delete_product', 'soft_delete', true)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.restore_product(p_product_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF NOT public.is_admin_or_owner() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  v_old_data := public.product_deleted_snapshot(p_product_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Product not found or not deleted';
  END IF;

  UPDATE public.products
  SET
    deleted_at = NULL,
    updated_at = now()
  WHERE id = p_product_id
    AND org_id = v_org_id
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Product not found or not deleted';
  END IF;

  v_new_data := public.product_log_snapshot(p_product_id);

  PERFORM public.write_data_change_log(
    'update',
    'products',
    p_product_id,
    'Restored product',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'restore_product', 'restore', true)
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate product code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
