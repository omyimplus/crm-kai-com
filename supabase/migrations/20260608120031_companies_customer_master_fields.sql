-- Customer master — companies columns + ship addresses
-- Source: docs/06-crm-schema/CUSTOMER-MASTER-FIELDS.md §1–§6, §7

-- Industry: ข้อมูลเก่าที่ไม่ใช่ slug → NULL ก่อนใส่ CHECK
UPDATE public.companies
SET industry = NULL
WHERE industry IS NOT NULL
  AND industry NOT IN (
    'agriculture', 'construction', 'education', 'finance', 'healthcare',
    'hospitality', 'manufacturing', 'retail', 'technology', 'transportation'
  );

ALTER TABLE public.companies
  ADD COLUMN IF NOT EXISTS customer_type text NOT NULL DEFAULT 'company',
  ADD COLUMN IF NOT EXISTS email text,
  ADD COLUMN IF NOT EXISTS mobile text,
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS industry_segment text DEFAULT 'sme',
  ADD COLUMN IF NOT EXISTS sales_grade text,
  ADD COLUMN IF NOT EXISTS tax_id text,
  ADD COLUMN IF NOT EXISTS tax_branch text,
  ADD COLUMN IF NOT EXISTS tax_vat text,
  ADD COLUMN IF NOT EXISTS vat_currency text NOT NULL DEFAULT 'THB',
  ADD COLUMN IF NOT EXISTS payment_code text,
  ADD COLUMN IF NOT EXISTS credit_term_days integer NOT NULL DEFAULT 30,
  ADD COLUMN IF NOT EXISTS credit_limit numeric(18, 2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS credit_balance numeric(18, 2) NOT NULL DEFAULT 0;

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_customer_type_check;
ALTER TABLE public.companies
  ADD CONSTRAINT companies_customer_type_check
  CHECK (customer_type IN ('company', 'individual'));

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_industry_segment_check;
ALTER TABLE public.companies
  ADD CONSTRAINT companies_industry_segment_check
  CHECK (industry_segment IS NULL OR industry_segment IN (
    'enterprise', 'sme', 'startup', 'individual'
  ));

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_industry_check;
ALTER TABLE public.companies
  ADD CONSTRAINT companies_industry_check
  CHECK (industry IS NULL OR industry IN (
    'agriculture', 'construction', 'education', 'finance', 'healthcare',
    'hospitality', 'manufacturing', 'retail', 'technology', 'transportation'
  ));

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_sales_grade_check;
ALTER TABLE public.companies
  ADD CONSTRAINT companies_sales_grade_check
  CHECK (sales_grade IS NULL OR sales_grade IN (
    'vip', 'a', 'b', 'c', 'prospect'
  ));

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_vat_currency_check;
ALTER TABLE public.companies
  ADD CONSTRAINT companies_vat_currency_check
  CHECK (vat_currency IN ('THB', 'USD'));

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_payment_code_check;
ALTER TABLE public.companies
  ADD CONSTRAINT companies_payment_code_check
  CHECK (payment_code IS NULL OR payment_code IN (
    'transfer', 'credit', 'cash', 'cheque'
  ));

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_credit_term_days_check;
ALTER TABLE public.companies
  ADD CONSTRAINT companies_credit_term_days_check
  CHECK (credit_term_days >= 0);

ALTER TABLE public.companies DROP CONSTRAINT IF EXISTS companies_credit_limit_check;
ALTER TABLE public.companies
  ADD CONSTRAINT companies_credit_limit_check
  CHECK (credit_limit >= 0);

-- Ship-to addresses (1:N ต่อ company)
CREATE TABLE IF NOT EXISTS public.company_ship_addresses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  company_id uuid NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
  label text,
  address text NOT NULL,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_company_ship_addresses_company
  ON public.company_ship_addresses(company_id)
  WHERE company_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_company_ship_addresses_org
  ON public.company_ship_addresses(org_id);

DROP TRIGGER IF EXISTS company_ship_addresses_updated_at ON public.company_ship_addresses;
CREATE TRIGGER company_ship_addresses_updated_at
  BEFORE UPDATE ON public.company_ship_addresses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.company_ship_addresses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS company_ship_addresses_select ON public.company_ship_addresses;
CREATE POLICY company_ship_addresses_select ON public.company_ship_addresses
  FOR SELECT
  USING (org_id = public.current_org_id());

DROP POLICY IF EXISTS company_ship_addresses_insert ON public.company_ship_addresses;
CREATE POLICY company_ship_addresses_insert ON public.company_ship_addresses
  FOR INSERT
  WITH CHECK (org_id = public.current_org_id() AND NOT public.is_readonly());

DROP POLICY IF EXISTS company_ship_addresses_update ON public.company_ship_addresses;
CREATE POLICY company_ship_addresses_update ON public.company_ship_addresses
  FOR UPDATE
  USING (org_id = public.current_org_id() AND NOT public.is_readonly())
  WITH CHECK (org_id = public.current_org_id());

DROP POLICY IF EXISTS company_ship_addresses_delete ON public.company_ship_addresses;
CREATE POLICY company_ship_addresses_delete ON public.company_ship_addresses
  FOR DELETE
  USING (org_id = public.current_org_id() AND NOT public.is_readonly());
