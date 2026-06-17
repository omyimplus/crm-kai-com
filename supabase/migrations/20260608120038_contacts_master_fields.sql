-- Contact master fields + customer relation (company_id)
-- Docs: docs/06-crm-schema/CONTACT-MASTER-FIELDS.md

ALTER TABLE public.contacts
  ADD COLUMN IF NOT EXISTS mobile text,
  ADD COLUMN IF NOT EXISTS department text,
  ADD COLUMN IF NOT EXISTS contact_role text DEFAULT 'other',
  ADD COLUMN IF NOT EXISTS is_main_contact boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS notes text;

UPDATE public.contacts
SET contact_role = 'other'
WHERE contact_role IS NULL;

ALTER TABLE public.contacts DROP CONSTRAINT IF EXISTS contacts_contact_role_check;
ALTER TABLE public.contacts
  ADD CONSTRAINT contacts_contact_role_check
  CHECK (contact_role IS NULL OR contact_role IN (
    'decision_maker', 'influencer', 'user', 'gatekeeper', 'other'
  ));

CREATE INDEX IF NOT EXISTS idx_contacts_company_id ON public.contacts(company_id)
  WHERE deleted_at IS NULL;
