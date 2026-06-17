-- Ship To: default address ต่อ company (ใช้ในโมดูลอื่น)
-- Docs: docs/06-crm-schema/CUSTOMER-MASTER-FIELDS.md §7

ALTER TABLE public.company_ship_addresses
  ADD COLUMN IF NOT EXISTS is_default boolean NOT NULL DEFAULT false;

CREATE UNIQUE INDEX IF NOT EXISTS idx_company_ship_addresses_one_default
  ON public.company_ship_addresses (company_id)
  WHERE is_default = true;

CREATE INDEX IF NOT EXISTS idx_company_ship_addresses_default_lookup
  ON public.company_ship_addresses (company_id, sort_order)
  WHERE is_default = true;

-- โมดูลอื่นเรียกใช้: default ก่อน แล้ว fallback แถวแรกตาม sort_order
CREATE OR REPLACE FUNCTION public.get_company_default_ship_address(p_company_id uuid)
RETURNS public.company_ship_addresses AS $$
  SELECT s.*
  FROM public.company_ship_addresses s
  WHERE s.company_id = p_company_id
    AND s.org_id = public.current_org_id()
  ORDER BY s.is_default DESC, s.sort_order ASC, s.created_at ASC
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_company_default_ship_address(uuid) TO authenticated;
