-- WHT rate slugs on companies.tax_vat (UI: ภาษีหัก ณ ที่จ่าย)
-- Docs: docs/06-crm-schema/CUSTOMER-MASTER-FIELDS.md §6.5

UPDATE public.companies
SET tax_vat = NULL, updated_at = now()
WHERE tax_vat IS NOT NULL
  AND tax_vat NOT IN (
    'none', 'wht_3', 'wht_5', 'wht_0_5', 'wht_0_75',
    'wht_1', 'wht_1_5', 'wht_2', 'wht_10', 'wht_15'
  );

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_tax_vat_check;
ALTER TABLE public.companies
  ADD CONSTRAINT companies_tax_vat_check
  CHECK (tax_vat IS NULL OR tax_vat IN (
    'none', 'wht_3', 'wht_5', 'wht_0_5', 'wht_0_75',
    'wht_1', 'wht_1_5', 'wht_2', 'wht_10', 'wht_15'
  ));
