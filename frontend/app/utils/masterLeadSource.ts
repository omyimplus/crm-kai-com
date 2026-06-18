import type { LeadSource } from '~/types/crm'
import {
  LEAD_SOURCE_STATUSES,
  type LeadSourceStatus
} from '~/config/masterLeadSource'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

export interface MasterLeadSourceFormInput {
  source_code: string
  name: string
  description: string
  sort_order: number
  status: LeadSourceStatus
  notes: string
}

export function defaultMasterLeadSourceFormInput(): MasterLeadSourceFormInput {
  return {
    source_code: '',
    name: '',
    description: '',
    sort_order: 0,
    status: 'active',
    notes: ''
  }
}

function parseStatus(value: string | null | undefined): LeadSourceStatus {
  if (value && (LEAD_SOURCE_STATUSES as readonly string[]).includes(value)) {
    return value as LeadSourceStatus
  }
  return 'active'
}

export function leadSourceToFormInput(source: LeadSource): MasterLeadSourceFormInput {
  return {
    source_code: source.source_code,
    name: source.name,
    description: source.description ?? '',
    sort_order: source.sort_order ?? 0,
    status: parseStatus(source.status),
    notes: source.notes ?? ''
  }
}

export function formToLeadSourcePayload(form: MasterLeadSourceFormInput) {
  return {
    source_code: form.source_code.trim(),
    name: form.name.trim(),
    description: form.description.trim() || null,
    sort_order: form.sort_order ?? 0,
    status: form.status,
    notes: form.notes.trim() || null
  }
}

export type MasterLeadSourceValidationKey =
  | 'codeRequired'
  | 'nameRequired'
  | 'sortOrderInvalid'

export function validateMasterLeadSourceForm(
  form: MasterLeadSourceFormInput
): MasterLeadSourceValidationKey | null {
  if (!form.source_code.trim()) return 'codeRequired'
  if (!form.name.trim()) return 'nameRequired'
  if (form.sort_order < 0) return 'sortOrderInvalid'
  return null
}

export function leadSourceDisplayLabel(source: Pick<LeadSource, 'name'>) {
  return source.name
}

export function leadSourceSaveErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.saveFailed'))
  if (message.includes('Duplicate lead source code')) {
    return t('masterData.leadSource.validation.duplicateCode')
  }
  return message || t('common.saveFailed')
}

export function leadSourceDeleteErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.deleteFailed'))
  return message || t('common.deleteFailed')
}
