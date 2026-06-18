-- agriculture · construction · education · finance · healthcare ·
-- hospitality · manufacturing · retail · technology · transportation
-- Docs: CUSTOMER-MASTER-FIELDS.md §1
--
-- 1) Relax / drop old constraint first (enterprise/sme/startup/individual)
--
ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_industry_segment_check;

--
-- 2) Data migration — update existing rows without constraint blocking
--
UPDATE public.companies
SET
  industry_segment = industry,
  industry = industry,
  updated_at = now()
WHERE industry IS NOT NULL
  AND industry IN (
    'agriculture', 'construction', 'education', 'finance', 'healthcare',
    'hospitality', 'manufacturing', 'retail', 'technology', 'transportation'
  )
  AND (
    industry_segment IS NULL
    OR industry_segment IN ('enterprise', 'sme', 'startup', 'individual')
  );

UPDATE public.companies
SET
  industry_segment = NULL,
  updated_at = now()
WHERE industry_segment IN ('enterprise', 'sme', 'startup', 'individual');

UPDATE public.companies
SET
  industry = industry_segment,
  updated_at = now()
WHERE industry_segment IS NOT NULL
  AND industry_segment IN (
    'agriculture', 'construction', 'education', 'finance', 'healthcare',
    'hospitality', 'manufacturing', 'retail', 'technology', 'transportation'
  )
  AND industry IS DISTINCT FROM industry_segment;

UPDATE public.leads
SET
  industry_segment = NULL,
  updated_at = now()
WHERE industry_segment IN ('enterprise', 'sme', 'startup', 'individual');

--
-- 3) Recreate constraint with new allowed values + drop default
--
ALTER TABLE public.companies
  ADD CONSTRAINT companies_industry_segment_check
  CHECK (industry_segment IS NULL OR industry_segment IN (
    'agriculture', 'construction', 'education', 'finance', 'healthcare',
    'hospitality', 'manufacturing', 'retail', 'technology', 'transportation'
  ));

ALTER TABLE public.companies
  ALTER COLUMN industry_segment DROP DEFAULT;
