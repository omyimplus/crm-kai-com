-- Product categories master data + CRUD RPC + data_change_logs
-- Docs: CATEGORY-MASTER-FIELDS.md · DATA-CHANGE-LOG.md
-- Phase 1: module_key = 'product' only (UI) · ผูก products.category_id ใน migration ถัดไป

CREATE TABLE IF NOT EXISTS public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  module_key text NOT NULL DEFAULT 'product',
  category_code text NOT NULL,
  name text NOT NULL,
  description text,
  parent_id uuid REFERENCES public.categories(id) ON DELETE SET NULL,
  sort_order integer NOT NULL DEFAULT 0,
  color text,
  status text NOT NULL DEFAULT 'active',
  notes text,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT categories_module_key_check CHECK (module_key IN ('product')),
  CONSTRAINT categories_status_check CHECK (status IN ('active', 'inactive')),
  CONSTRAINT categories_sort_order_check CHECK (sort_order >= 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS categories_unique_code_active_idx
  ON public.categories (org_id, module_key, lower(trim(category_code)))
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_categories_org_parent
  ON public.categories (org_id, parent_id)
  WHERE deleted_at IS NULL;

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY categories_select ON public.categories FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND (
      deleted_at IS NULL
      OR public.is_admin_or_owner()
    )
  );

CREATE POLICY categories_insert ON public.categories FOR INSERT
  WITH CHECK (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  );

CREATE POLICY categories_update ON public.categories FOR UPDATE
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
    AND NOT public.is_readonly()
  )
  WITH CHECK (org_id = public.current_org_id());

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
    'notes', c.notes
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
    'deleted_at', c.deleted_at
  )
  FROM public.categories c
  WHERE c.id = p_category_id
    AND c.org_id = public.current_org_id()
    AND c.deleted_at IS NOT NULL;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.category_validate_parent(
  p_category_id uuid,
  p_parent_id uuid,
  p_module_key text DEFAULT 'product'
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_walk uuid;
  v_depth integer := 0;
BEGIN
  IF p_parent_id IS NULL THEN
    RETURN;
  END IF;

  IF p_category_id IS NOT NULL AND p_parent_id = p_category_id THEN
    RAISE EXCEPTION 'Category cannot be its own parent';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.categories c
    WHERE c.id = p_parent_id
      AND c.org_id = v_org_id
      AND c.module_key = p_module_key
      AND c.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Parent category not found';
  END IF;

  v_walk := p_parent_id;
  WHILE v_walk IS NOT NULL LOOP
    v_depth := v_depth + 1;
    IF v_depth > 32 THEN
      RAISE EXCEPTION 'Category hierarchy too deep';
    END IF;

    IF p_category_id IS NOT NULL AND v_walk = p_category_id THEN
      RAISE EXCEPTION 'Circular category hierarchy';
    END IF;

    SELECT c.parent_id
    INTO v_walk
    FROM public.categories c
    WHERE c.id = v_walk
      AND c.org_id = v_org_id
      AND c.deleted_at IS NULL;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.create_category(p_payload jsonb)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_module_key text := coalesce(nullif(trim(p_payload->>'module_key'), ''), 'product');
  v_parent_id uuid;
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

CREATE OR REPLACE FUNCTION public.restore_category(p_category_id uuid)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_old_data jsonb;
  v_new_data jsonb;
  v_module_key text;
  v_parent_id uuid;
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

  v_old_data := public.category_deleted_snapshot(p_category_id);
  IF v_old_data IS NULL THEN
    RAISE EXCEPTION 'Category not found or not deleted';
  END IF;

  v_module_key := coalesce(v_old_data->>'module_key', 'product');
  v_parent_id := NULLIF(v_old_data->>'parent_id', '')::uuid;

  IF v_parent_id IS NOT NULL AND NOT EXISTS (
    SELECT 1
    FROM public.categories c
    WHERE c.id = v_parent_id
      AND c.org_id = v_org_id
      AND c.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Parent category is deleted — restore parent first';
  END IF;

  UPDATE public.categories
  SET
    deleted_at = NULL,
    updated_at = now()
  WHERE id = p_category_id
    AND org_id = v_org_id
    AND deleted_at IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Category not found or not deleted';
  END IF;

  v_new_data := public.category_log_snapshot(p_category_id);

  PERFORM public.write_data_change_log(
    'update',
    'categories',
    p_category_id,
    'Restored category',
    v_old_data,
    v_new_data,
    jsonb_build_object('source', 'restore_category', 'restore', true)
  );
EXCEPTION
  WHEN unique_violation THEN
    RAISE EXCEPTION 'Duplicate category code';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
