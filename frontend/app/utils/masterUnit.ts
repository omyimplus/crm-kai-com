import type { Unit } from '~/types/crm'
import { UNIT_STATUSES, type UnitStatus } from '~/config/masterUnit'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

export interface MasterUnitFormInput {
  unit_code: string
  name: string
  description: string
  sort_order: number
  status: UnitStatus
  notes: string
}

export function defaultMasterUnitFormInput(): MasterUnitFormInput {
  return {
    unit_code: '',
    name: '',
    description: '',
    sort_order: 0,
    status: 'active',
    notes: ''
  }
}

function parseStatus(value: string | null | undefined): UnitStatus {
  if (value && (UNIT_STATUSES as readonly string[]).includes(value)) {
    return value as UnitStatus
  }
  return 'active'
}

export function unitToFormInput(unit: Unit): MasterUnitFormInput {
  return {
    unit_code: unit.unit_code,
    name: unit.name,
    description: unit.description ?? '',
    sort_order: unit.sort_order ?? 0,
    status: parseStatus(unit.status),
    notes: unit.notes ?? ''
  }
}

export function formToUnitPayload(form: MasterUnitFormInput) {
  return {
    unit_code: form.unit_code.trim(),
    name: form.name.trim(),
    description: form.description.trim() || null,
    sort_order: form.sort_order ?? 0,
    status: form.status,
    notes: form.notes.trim() || null
  }
}

export type MasterUnitValidationKey =
  | 'codeRequired'
  | 'nameRequired'
  | 'sortOrderInvalid'

export function validateMasterUnitForm(
  form: MasterUnitFormInput
): MasterUnitValidationKey | null {
  if (!form.unit_code.trim()) return 'codeRequired'
  if (!form.name.trim()) return 'nameRequired'
  if (form.sort_order < 0) return 'sortOrderInvalid'
  return null
}

export function unitDisplayLabel(unit: Pick<Unit, 'name'>) {
  return unit.name
}

export function unitSaveErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.saveFailed'))
  if (message.includes('Duplicate unit code')) {
    return t('masterData.unit.validation.duplicateCode')
  }
  return message || t('common.saveFailed')
}

export function unitDeleteErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.deleteFailed'))
  if (message.includes('Unit has products')) {
    return t('masterData.unit.validation.hasProducts')
  }
  return message || t('common.deleteFailed')
}
