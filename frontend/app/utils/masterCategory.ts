import type { Category } from '~/types/crm'
import {
  CATEGORY_MODULE_KEY,
  CATEGORY_STATUSES,
  type CategoryStatus
} from '~/config/masterCategory'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'

export interface MasterCategoryFormInput {
  category_code: string
  name: string
  description: string
  parent_id: string | null
  sort_order: number
  color: string
  status: CategoryStatus
  notes: string
}

export function defaultMasterCategoryFormInput(): MasterCategoryFormInput {
  return {
    category_code: '',
    name: '',
    description: '',
    parent_id: null,
    sort_order: 0,
    color: '',
    status: 'active',
    notes: ''
  }
}

function parseStatus(value: string | null | undefined): CategoryStatus {
  if (value && (CATEGORY_STATUSES as readonly string[]).includes(value)) {
    return value as CategoryStatus
  }
  return 'active'
}

export function categoryToFormInput(category: Category): MasterCategoryFormInput {
  return {
    category_code: category.category_code,
    name: category.name,
    description: category.description ?? '',
    parent_id: normalizeSelectValue(category.parent_id),
    sort_order: category.sort_order ?? 0,
    color: category.color ?? '',
    status: parseStatus(category.status),
    notes: category.notes ?? ''
  }
}

export function formToCategoryPayload(form: MasterCategoryFormInput) {
  return {
    module_key: CATEGORY_MODULE_KEY,
    category_code: form.category_code.trim(),
    name: form.name.trim(),
    description: form.description.trim() || null,
    parent_id: normalizeSelectValue(form.parent_id),
    sort_order: form.sort_order ?? 0,
    color: form.color.trim() || null,
    status: form.status,
    notes: form.notes.trim() || null
  }
}

export type MasterCategoryValidationKey =
  | 'codeRequired'
  | 'nameRequired'
  | 'sortOrderInvalid'
  | 'colorInvalid'

const HEX_COLOR_RE = /^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$/

export function validateMasterCategoryForm(
  form: MasterCategoryFormInput
): MasterCategoryValidationKey | null {
  if (!form.category_code.trim()) return 'codeRequired'
  if (!form.name.trim()) return 'nameRequired'
  if (form.sort_order < 0) return 'sortOrderInvalid'
  if (form.color.trim() && !HEX_COLOR_RE.test(form.color.trim())) return 'colorInvalid'
  return null
}

export function categoryDisplayLabel(category: Pick<Category, 'category_code' | 'name'>) {
  return `${category.category_code} · ${category.name}`
}

export function categorySaveErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.saveFailed'))
  if (message.includes('Duplicate category code')) {
    return t('masterData.category.validation.duplicateCode')
  }
  if (message.includes('Category has child categories')) {
    return t('masterData.category.validation.hasChildren')
  }
  if (message.includes('Parent category is deleted')) {
    return t('masterData.category.validation.parentDeleted')
  }
  if (message.includes('Circular category hierarchy') || message.includes('cannot be its own parent')) {
    return t('masterData.category.validation.circularParent')
  }
  return message || t('common.saveFailed')
}

export function categoryDeleteErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.deleteFailed'))
  if (message.includes('Category has child categories')) {
    return t('masterData.category.validation.hasChildren')
  }
  if (message.includes('Category has products')) {
    return t('masterData.category.validation.hasProducts')
  }
  return message || t('common.deleteFailed')
}

export function parentCategoryOptions(
  categories: Category[],
  excludeId?: string | null
) {
  return categories
    .filter(c => c.id !== excludeId)
    .map(c => ({
      value: c.id,
      label: categoryDisplayLabel(c)
    }))
}
