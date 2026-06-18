-- Product gallery images (multiple images per product, separate from main image_url)
-- Docs: PRODUCT-MASTER-FIELDS.md · IMAGE-UPLOAD.md

CREATE TABLE IF NOT EXISTS public.product_gallery_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  image_url text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT product_gallery_images_sort_order_check CHECK (sort_order >= 0)
);

CREATE INDEX IF NOT EXISTS idx_product_gallery_images_product
  ON public.product_gallery_images (product_id, sort_order);

CREATE INDEX IF NOT EXISTS idx_product_gallery_images_org
  ON public.product_gallery_images (org_id, product_id);

ALTER TABLE public.product_gallery_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY product_gallery_images_select ON public.product_gallery_images FOR SELECT
  USING (
    org_id = public.current_org_id()
    AND public.is_active_user()
  );

GRANT SELECT ON public.product_gallery_images TO authenticated;

CREATE OR REPLACE FUNCTION public.product_validate_gallery_product(p_product_id uuid)
RETURNS void AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.products p
    WHERE p.id = p_product_id
      AND p.org_id = public.current_org_id()
      AND p.deleted_at IS NULL
  ) THEN
    RAISE EXCEPTION 'Product not found';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.add_product_gallery_image(
  p_product_id uuid,
  p_image_id uuid,
  p_image_url text
)
RETURNS uuid AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_sort integer;
  v_count integer;
  v_url text := NULLIF(btrim(p_image_url), '');
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  IF p_image_id IS NULL THEN
    RAISE EXCEPTION 'Image id required';
  END IF;

  IF v_url IS NULL THEN
    RAISE EXCEPTION 'Image URL required';
  END IF;

  PERFORM public.product_validate_gallery_product(p_product_id);

  SELECT count(*)::integer INTO v_count
  FROM public.product_gallery_images gi
  WHERE gi.product_id = p_product_id
    AND gi.org_id = v_org_id;

  IF v_count >= 20 THEN
    RAISE EXCEPTION 'Gallery image limit reached';
  END IF;

  SELECT coalesce(max(gi.sort_order), -1) + 1 INTO v_sort
  FROM public.product_gallery_images gi
  WHERE gi.product_id = p_product_id
    AND gi.org_id = v_org_id;

  INSERT INTO public.product_gallery_images (
    id,
    org_id,
    product_id,
    image_url,
    sort_order
  ) VALUES (
    p_image_id,
    v_org_id,
    p_product_id,
    v_url,
    v_sort
  );

  RETURN p_image_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.remove_product_gallery_image(p_image_id uuid)
RETURNS text AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_url text;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  SELECT gi.image_url INTO v_url
  FROM public.product_gallery_images gi
  WHERE gi.id = p_image_id
    AND gi.org_id = v_org_id;

  IF v_url IS NULL THEN
    RAISE EXCEPTION 'Gallery image not found';
  END IF;

  DELETE FROM public.product_gallery_images gi
  WHERE gi.id = p_image_id
    AND gi.org_id = v_org_id;

  RETURN v_url;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.reorder_product_gallery_images(
  p_product_id uuid,
  p_image_ids uuid[]
)
RETURNS void AS $$
DECLARE
  v_org_id uuid := public.current_org_id();
  v_expected integer;
  v_actual integer;
BEGIN
  IF v_org_id IS NULL THEN
    RAISE EXCEPTION 'No organization context';
  END IF;

  IF public.is_readonly() OR NOT public.is_active_user() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  PERFORM public.product_validate_gallery_product(p_product_id);

  SELECT count(*)::integer INTO v_expected
  FROM public.product_gallery_images gi
  WHERE gi.product_id = p_product_id
    AND gi.org_id = v_org_id;

  SELECT count(*)::integer INTO v_actual
  FROM unnest(p_image_ids) AS image_id(id)
  JOIN public.product_gallery_images gi
    ON gi.id = image_id.id
   AND gi.product_id = p_product_id
   AND gi.org_id = v_org_id;

  IF v_expected <> v_actual OR v_expected <> coalesce(array_length(p_image_ids, 1), 0) THEN
    RAISE EXCEPTION 'Invalid gallery image order';
  END IF;

  UPDATE public.product_gallery_images gi
  SET
    sort_order = ord.idx - 1,
    updated_at = now()
  FROM unnest(p_image_ids) WITH ORDINALITY AS ord(id, idx)
  WHERE gi.id = ord.id
    AND gi.product_id = p_product_id
    AND gi.org_id = v_org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.add_product_gallery_image(uuid, uuid, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_product_gallery_image(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.reorder_product_gallery_images(uuid, uuid[]) TO authenticated;

NOTIFY pgrst, 'reload schema';
