-- Tax VAT — slug dropdown (Phase 1)
-- Docs: docs/06-crm-schema/CUSTOMER-MASTER-FIELDS.md §6.5

UPDATE public.companies
SET tax_vat = NULL, updated_at = now()
WHERE tax_vat IS NOT NULL
  AND tax_vat NOT IN ('vat_7', 'vat_0', 'exempt', 'no_vat');

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_tax_vat_check;
ALTER TABLE public.companies
  ADD CONSTRAINT companies_tax_vat_check
  CHECK (tax_vat IS NULL OR tax_vat IN ('vat_7', 'vat_0', 'exempt', 'no_vat'));
