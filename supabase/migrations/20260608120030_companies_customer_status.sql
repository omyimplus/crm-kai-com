-- Customer lifecycle status — 5 values (manual ใน UI Phase 1)
-- อ้างอิง docs/06-crm-schema/CUSTOMER-MASTER-FIELDS.md §4

ALTER TABLE companies
  DROP CONSTRAINT IF EXISTS companies_status_check;

ALTER TABLE companies
  ADD CONSTRAINT companies_status_check
  CHECK (status IN ('active', 'inactive', 'prospect', 'churned', 'pending'));
