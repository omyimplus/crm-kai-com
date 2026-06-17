-- บุคคลธรรมดา (individual) → industry_segment = individual, industry = NULL
-- Docs: CUSTOMER-MASTER-FIELDS.md §0

UPDATE public.companies
SET
  industry_segment = 'individual',
  industry = NULL,
  updated_at = now()
WHERE customer_type = 'individual'
  AND deleted_at IS NULL
  AND (industry_segment IS DISTINCT FROM 'individual' OR industry IS NOT NULL);

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_individual_type_fields_check;
ALTER TABLE public.companies
  ADD CONSTRAINT companies_individual_type_fields_check
  CHECK (
    customer_type <> 'individual'
    OR (industry_segment = 'individual' AND industry IS NULL)
  );
