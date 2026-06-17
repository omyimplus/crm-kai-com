import type { Contact } from '~/types/crm'
import { CONTACT_ROLES, type ContactRole } from '~/config/masterContact'

export interface MasterContactFormInput {
  first_name: string
  last_name: string
  email: string
  phone: string
  mobile: string
  company_id: string | null
  job_title: string
  department: string
  contact_role: ContactRole
  is_main_contact: boolean
  notes: string
}

export function defaultMasterContactFormInput(): MasterContactFormInput {
  return {
    first_name: '',
    last_name: '',
    email: '',
    phone: '',
    mobile: '',
    company_id: null,
    job_title: '',
    department: '',
    contact_role: 'other',
    is_main_contact: false,
    notes: ''
  }
}

function parseRole(value: string | null | undefined): ContactRole {
  if (value && (CONTACT_ROLES as readonly string[]).includes(value)) {
    return value as ContactRole
  }
  return 'other'
}

export function contactToFormInput(contact: Contact): MasterContactFormInput {
  return {
    first_name: contact.first_name,
    last_name: contact.last_name ?? '',
    email: contact.email ?? '',
    phone: contact.phone ?? '',
    mobile: contact.mobile ?? '',
    company_id: contact.company_id,
    job_title: contact.job_title ?? '',
    department: contact.department ?? '',
    contact_role: parseRole(contact.contact_role),
    is_main_contact: contact.is_main_contact ?? false,
    notes: contact.notes ?? ''
  }
}

export function formToContactPayload(form: MasterContactFormInput) {
  return {
    first_name: form.first_name.trim(),
    last_name: form.last_name.trim() || null,
    email: form.email.trim() || null,
    phone: form.phone.trim() || null,
    mobile: form.mobile.trim() || null,
    company_id: form.company_id,
    job_title: form.job_title.trim() || null,
    department: form.department.trim() || null,
    contact_role: form.contact_role,
    is_main_contact: form.is_main_contact,
    notes: form.notes.trim() || null
  }
}

export type MasterContactValidationKey =
  | 'firstNameRequired'
  | 'emailRequired'
  | 'phoneRequired'
  | 'customerRequired'

export function validateMasterContactForm(
  form: MasterContactFormInput
): MasterContactValidationKey | null {
  if (!form.first_name.trim()) return 'firstNameRequired'
  if (!form.email.trim()) return 'emailRequired'
  if (!form.phone.trim()) return 'phoneRequired'
  if (!form.company_id) return 'customerRequired'
  return null
}

export function contactDisplayName(contact: Pick<Contact, 'first_name' | 'last_name'>) {
  return [contact.first_name, contact.last_name].filter(Boolean).join(' ')
}
