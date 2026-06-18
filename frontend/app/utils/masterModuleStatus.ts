import type { ModuleStatus } from '~/types/crm'
import {
  MODULE_STATUS_MODULE_KEYS,
  MODULE_STATUS_RECORD_STATUSES,
  type ModuleStatusModuleKey,
  type ModuleStatusRecordStatus
} from '~/config/masterModuleStatus'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'
import {
  moduleStatusCodeValidationKey,
  normalizeModuleStatusCode,
  validateModuleStatusCode
} from '~/utils/moduleStatusCode'

const HEX_COLOR_RE = /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/

export interface MasterModuleStatusFormInput {
  module_key: ModuleStatusModuleKey | null
  status_code: string
  name: string
  description: string
  color: string
  sort_order: number
  is_default: boolean
  status: ModuleStatusRecordStatus
  notes: string
}

export function defaultMasterModuleStatusFormInput(): MasterModuleStatusFormInput {
  return {
    module_key: null,
    status_code: '',
    name: '',
    description: '',
    color: '',
    sort_order: 0,
    is_default: false,
    status: 'active',
    notes: ''
  }
}

function parseModuleKey(value: string | null | undefined): ModuleStatusModuleKey | null {
  if (value && (MODULE_STATUS_MODULE_KEYS as readonly string[]).includes(value)) {
    return value as ModuleStatusModuleKey
  }
  return null
}

export function isModuleStatusModuleKey(value: string | null | undefined): value is ModuleStatusModuleKey {
  return parseModuleKey(value) !== null
}

function parseRecordStatus(value: string | null | undefined): ModuleStatusRecordStatus {
  if (value && (MODULE_STATUS_RECORD_STATUSES as readonly string[]).includes(value)) {
    return value as ModuleStatusRecordStatus
  }
  return 'active'
}

export function moduleStatusToFormInput(row: ModuleStatus): MasterModuleStatusFormInput {
  return {
    module_key: parseModuleKey(row.module_key),
    status_code: row.status_code,
    name: row.name,
    description: row.description ?? '',
    color: row.color ?? '',
    sort_order: row.sort_order ?? 0,
    is_default: row.is_default ?? false,
    status: parseRecordStatus(row.status),
    notes: row.notes ?? ''
  }
}

export function formToModuleStatusPayload(form: MasterModuleStatusFormInput) {
  return {
    module_key: form.module_key,
    status_code: normalizeModuleStatusCode(form.status_code),
    name: form.name.trim(),
    description: form.description.trim() || null,
    color: form.color.trim() || null,
    sort_order: form.sort_order ?? 0,
    is_default: form.is_default ?? false,
    status: form.status,
    notes: form.notes.trim() || null
  }
}

export type MasterModuleStatusValidationKey =
  | 'moduleRequired'
  | 'codeRequired'
  | 'codeNoSpaces'
  | 'codeInvalidChars'
  | 'codeMustStartLetter'
  | 'codeTooShort'
  | 'codeTooLong'
  | 'nameRequired'
  | 'sortOrderInvalid'
  | 'colorInvalid'

export function validateMasterModuleStatusForm(
  form: MasterModuleStatusFormInput
): MasterModuleStatusValidationKey | null {
  if (!form.module_key) return 'moduleRequired'

  const codeResult = validateModuleStatusCode(form.status_code)
  if (!codeResult.ok && codeResult.errorId) {
    return moduleStatusCodeValidationKey(codeResult.errorId)
  }

  if (!form.name.trim()) return 'nameRequired'
  if (form.sort_order < 0) return 'sortOrderInvalid'
  if (form.color.trim() && !HEX_COLOR_RE.test(form.color.trim())) return 'colorInvalid'
  return null
}

export function moduleStatusDisplayLabel(row: Pick<ModuleStatus, 'name'>) {
  return row.name
}

export function moduleStatusModuleLabel(
  moduleKey: string,
  t: (key: string) => string
) {
  const key = `masterData.moduleStatuses.options.module.${moduleKey}`
  const translated = t(key)
  return translated === key ? moduleKey : translated
}

export interface ModuleStatusSelectOption {
  value: string
  label: string
  id: string
  status_code: string
  color: string | null
  is_default: boolean
}

/** Options for CRM status dropdown — value = status_code, label = org-defined name */
export function moduleStatusSelectOptions(rows: ModuleStatus[]): ModuleStatusSelectOption[] {
  return rows
    .filter(row => row.status === 'active')
    .sort((a, b) => a.sort_order - b.sort_order || a.name.localeCompare(b.name, 'th'))
    .map(row => ({
      value: row.status_code,
      label: moduleStatusDisplayLabel(row),
      id: row.id,
      status_code: row.status_code,
      color: row.color,
      is_default: row.is_default
    }))
}

export function moduleStatusListPath(moduleKey: ModuleStatusModuleKey) {
  return `/app/module-status?module=${moduleKey}`
}

export function moduleStatusNewPath(moduleKey: ModuleStatusModuleKey) {
  return `/app/module-status/module/${moduleKey}/new`
}

export function moduleStatusSaveErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.saveFailed'))
  if (message.includes('Duplicate status code')) {
    return t('masterData.moduleStatuses.validation.duplicateCode')
  }
  if (message.includes('Invalid status code format')) {
    return t('masterData.moduleStatuses.validation.codeInvalidChars')
  }
  return message || t('common.saveFailed')
}

export function moduleStatusDeleteErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.deleteFailed'))
  if (message.includes('Module status in use by tasks')) {
    return t('masterData.moduleStatuses.validation.inUseByTasks')
  }
  return message || t('common.deleteFailed')
}

const MODULE_STATUS_FALLBACK_COLOR = '#94a3b8'

/** พื้น subtle + ตัวอักษรสีสถานะ — ใช้กับ UBadge ใน list/card */
export function moduleStatusTintStyle(color: string | null | undefined) {
  const value = color?.trim()
  if (!value) return undefined
  return {
    backgroundColor: `${value}22`,
    color: value
  }
}

export function moduleStatusAccentColor(color: string | null | undefined) {
  return color?.trim() || MODULE_STATUS_FALLBACK_COLOR
}
