-- Bill To (ที่อยู่ออกใบแจ้งหนี้) — หลายรายการ + default ต่อ company
-- Docs: docs/06-crm-schema/CUSTOMER-MASTER-FIELDS.md §8

CREATE TABLE IF NOT EXISTS public.company_bill_addresses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  label text,
  address text NOT NULL,
  is_default boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_company_bill_addresses_one_default
  ON public.company_bill_addresses (company_id)
  WHERE is_default = true;

CREATE INDEX IF NOT EXISTS idx_company_bill_addresses_company
  ON public.company_bill_addresses(company_id);

CREATE INDEX IF NOT EXISTS idx_company_bill_addresses_org
  ON public.company_bill_addresses(org_id);

-- ย้าย companies.address เดิม → แถว bill default (ครั้งเดียว)
INSERT INTO public.company_bill_addresses (org_id, company_id, label, address, is_default, sort_order)
SELECT c.org_id, c.id, NULL, btrim(c.address), true, 0
FROM public.companies c
WHERE c.deleted_at IS NULL
  AND c.address IS NOT NULL
  AND btrim(c.address) <> ''
  AND NOT EXISTS (
    SELECT 1 FROM public.company_bill_addresses b WHERE b.company_id = c.id
  );

DROP TRIGGER IF EXISTS company_bill_addresses_updated_at ON public.company_bill_addresses;
CREATE TRIGGER company_bill_addresses_updated_at
  BEFORE UPDATE ON public.company_bill_addresses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.company_bill_addresses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS company_bill_addresses_select ON public.company_bill_addresses;
CREATE POLICY company_bill_addresses_select ON public.company_bill_addresses
  FOR SELECT
  USING (org_id = public.current_org_id());

DROP POLICY IF EXISTS company_bill_addresses_insert ON public.company_bill_addresses;
CREATE POLICY company_bill_addresses_insert ON public.company_bill_addresses
  FOR INSERT
  WITH CHECK (org_id = public.current_org_id() AND NOT public.is_readonly());

DROP POLICY IF EXISTS company_bill_addresses_update ON public.company_bill_addresses;
CREATE POLICY company_bill_addresses_update ON public.company_bill_addresses
  FOR UPDATE
  USING (org_id = public.current_org_id() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

DROP POLICY IF EXISTS company_bill_addresses_delete ON public.company_bill_addresses;
CREATE POLICY company_bill_addresses_delete ON public.company_bill_addresses
  FOR DELETE
  USING (org_id = public.current_org_id() AND NOT public.is_readonly());

CREATE OR REPLACE FUNCTION public.get_company_default_bill_address(p_company_id uuid)
RETURNS public.company_bill_addresses AS $$
  SELECT b.*
  FROM public.company_bill_addresses b
  WHERE b.company_id = p_company_id
    AND b.org_id = public.current_org_id()
  ORDER BY b.is_default DESC, b.sort_order ASC, b.created_at ASC
  LIMIT 1;
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.get_company_default_bill_address(uuid) TO authenticated;
