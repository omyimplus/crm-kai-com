import type { Category, Product, Unit } from '~/types/crm'
import {
  PRODUCT_CURRENCIES,
  PRODUCT_STATUSES,
  type ProductCurrency,
  type ProductStatus
} from '~/config/masterProduct'
import { categoryPathLabel, categorySelectOptions } from '~/utils/masterCategory'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

export interface MasterProductFormInput {
  product_code: string
  name: string
  description: string
  category_id: string | null
  unit_id: string | null
  list_price: number | null
  cost_price: number | null
  currency: ProductCurrency
  barcode: string
  status: ProductStatus
  is_sellable: boolean
  notes: string
}

export function defaultMasterProductFormInput(): MasterProductFormInput {
  return {
    product_code: '',
    name: '',
    description: '',
    category_id: null,
    unit_id: null,
    list_price: 0,
    cost_price: null,
    currency: 'THB',
    barcode: '',
    status: 'active',
    is_sellable: true,
    notes: ''
  }
}

function parseStatus(value: string | null | undefined): ProductStatus {
  if (value && (PRODUCT_STATUSES as readonly string[]).includes(value)) {
    return value as ProductStatus
  }
  return 'active'
}

function parseCurrency(value: string | null | undefined): ProductCurrency {
  if (value && (PRODUCT_CURRENCIES as readonly string[]).includes(value)) {
    return value as ProductCurrency
  }
  return 'THB'
}

function parseNumber(value: number | string | null | undefined): number | null {
  if (value === null || value === undefined || value === '') return null
  const n = typeof value === 'number' ? value : Number(value)
  return Number.isFinite(n) ? n : null
}

export function productToFormInput(product: Product): MasterProductFormInput {
  return {
    product_code: product.product_code,
    name: product.name,
    description: product.description ?? '',
    category_id: normalizeSelectValue(product.category_id),
    unit_id: normalizeSelectValue(product.unit_id),
    list_price: parseNumber(product.list_price) ?? 0,
    cost_price: parseNumber(product.cost_price),
    currency: parseCurrency(product.currency),
    barcode: product.barcode ?? '',
    status: parseStatus(product.status),
    is_sellable: product.is_sellable ?? true,
    notes: product.notes ?? ''
  }
}

export function formToProductPayload(form: MasterProductFormInput) {
  return {
    product_code: form.product_code.trim(),
    name: form.name.trim(),
    description: form.description.trim() || null,
    category_id: normalizeSelectValue(form.category_id),
    unit_id: normalizeSelectValue(form.unit_id),
    list_price: form.list_price ?? 0,
    cost_price: form.cost_price,
    currency: form.currency,
    barcode: form.barcode.trim() || null,
    status: form.status,
    is_sellable: form.is_sellable,
    notes: form.notes.trim() || null
  }
}

export type MasterProductValidationKey =
  | 'codeRequired'
  | 'nameRequired'
  | 'listPriceInvalid'
  | 'costPriceInvalid'

export function validateMasterProductForm(
  form: MasterProductFormInput
): MasterProductValidationKey | null {
  if (!form.product_code.trim()) return 'codeRequired'
  if (!form.name.trim()) return 'nameRequired'
  if (form.list_price !== null && form.list_price < 0) return 'listPriceInvalid'
  if (form.cost_price !== null && form.cost_price < 0) return 'costPriceInvalid'
  return null
}

export function productDisplayLabel(product: Pick<Product, 'product_code' | 'name'>) {
  return `${product.product_code} · ${product.name}`
}

export function productCategoryOptions(categories: Category[]) {
  return categorySelectOptions(categories, { leafOnly: true })
}

export function productCategoryLabel(
  categoryId: string | null | undefined,
  categories: Category[]
): string | null {
  if (!categoryId) return null
  const path = categoryPathLabel(categories, categoryId)
  return path || null
}

export function productUnitOptions(units: Unit[]) {
  return units.map(u => ({
    value: u.id,
    label: u.name
  }))
}

export function productUnitLabel(
  unitId: string | null | undefined,
  units: Unit[]
): string | null {
  if (!unitId) return null
  const unit = units.find(u => u.id === unitId)
  return unit ? unit.name : null
}

export function productSaveErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.saveFailed'))
  if (message.includes('Duplicate product code')) {
    return t('masterData.products.validation.duplicateCode')
  }
  if (message.includes('Category not found')) {
    return t('masterData.products.validation.categoryNotFound')
  }
  if (message.includes('Unit not found')) {
    return t('masterData.products.validation.unitNotFound')
  }
  return message || t('common.saveFailed')
}
