import type { Category, OpportunityLineItem, OpportunityLineItemDraft, Product, Service } from '~/types/crm'
import type { OpportunityLineType } from '~/utils/masterCategoryCascade'
import { maxCascadeLevels, pathIdsFromCategory } from '~/utils/masterCategoryCascade'

function emptyToNull(value: string | null | undefined): string | null {
  const trimmed = value?.trim() ?? ''
  return trimmed || null
}

export function defaultOpportunityLineItemDraft(
  lineType: OpportunityLineType = 'product'
): OpportunityLineItemDraft {
  return {
    id: crypto.randomUUID(),
    line_type: lineType,
    category_path: [null, null, null],
    category_id: null,
    product_id: null,
    service_id: null,
    item_name: '',
    line_description: '',
    quantity: '1',
    unit_price: '0',
    line_total: '0'
  }
}

export function computeLineTotal(quantity: string, unitPrice: string): number {
  const qty = Number(quantity)
  const price = Number(unitPrice)
  if (Number.isNaN(qty) || Number.isNaN(price)) return 0
  return Math.round(qty * price * 100) / 100
}

export function syncLineItemTotals(row: OpportunityLineItemDraft): OpportunityLineItemDraft {
  const line_total = String(computeLineTotal(row.quantity, row.unit_price))
  return { ...row, line_total }
}

export function lineItemsToPayload(items: OpportunityLineItemDraft[]) {
  return items.map((row, index) => ({
    line_type: row.line_type,
    category_id: row.category_id,
    category_path: row.category_path.filter((id): id is string => Boolean(id)),
    product_id: row.product_id,
    service_id: row.service_id,
    item_name: row.item_name.trim(),
    line_description: row.line_description.trim(),
    quantity: Number(row.quantity) || 1,
    unit_price: Number(row.unit_price) || 0,
    line_total: computeLineTotal(row.quantity, row.unit_price),
    sort_order: index
  }))
}

export function lineItemsToDrafts(rows: OpportunityLineItem[]): OpportunityLineItemDraft[] {
  return rows.map(row => ({
    id: row.id,
    line_type: row.line_type,
    category_path: pathIdsFromCategory(
      [],
      row.category_id,
      maxCascadeLevels(row.line_type)
    ).map(id => id ?? null),
    category_id: row.category_id,
    product_id: row.product_id,
    service_id: row.service_id,
    item_name: row.item_name?.trim() ?? '',
    line_description: row.line_description?.trim() ?? '',
    quantity: String(row.quantity ?? 1),
    unit_price: String(row.unit_price ?? 0),
    line_total: String(row.line_total ?? 0)
  }))
}

export function opportunityLineItemsToDrafts(
  rows: OpportunityLineItem[],
  categories: Category[] = []
): OpportunityLineItemDraft[] {
  return rows.map((row) => {
    const max = maxCascadeLevels(row.line_type)
    const slots: (string | null)[] = Array.from({ length: max }, () => null)
    const pathIds = Array.isArray(row.category_path)
      ? row.category_path.filter((id): id is string => typeof id === 'string')
      : []

    if (pathIds.length) {
      const offset = Math.max(0, max - pathIds.length)
      pathIds.forEach((id, index) => {
        slots[offset + index] = id
      })
    } else if (row.category_id && categories.length) {
      return {
        id: row.id,
        line_type: row.line_type,
        category_path: pathIdsFromCategory(categories, row.category_id, max),
        category_id: row.category_id,
        product_id: row.product_id,
        service_id: row.service_id,
        item_name: row.item_name?.trim() ?? '',
        line_description: row.line_description?.trim() ?? '',
        quantity: String(row.quantity ?? 1),
        unit_price: String(row.unit_price ?? 0),
        line_total: String(row.line_total ?? 0)
      }
    }

    return {
      id: row.id,
      line_type: row.line_type,
      category_path: slots,
      category_id: row.category_id,
      product_id: row.product_id,
      service_id: row.service_id,
      item_name: row.item_name?.trim() ?? '',
      line_description: row.line_description?.trim() ?? '',
      quantity: String(row.quantity ?? 1),
      unit_price: String(row.unit_price ?? 0),
      line_total: String(row.line_total ?? 0)
    }
  })
}

export function sumLineItemsValue(items: OpportunityLineItemDraft[]): number {
  return items.reduce((sum, row) => sum + computeLineTotal(row.quantity, row.unit_price), 0)
}

export function productSelectOptions(products: Product[], categoryId: string | null) {
  let rows = products.filter(row => row.status === 'active')
  if (categoryId) {
    rows = rows.filter(row => row.category_id === categoryId)
  }
  return rows.map(row => ({
    value: row.id,
    label: `${row.product_code} — ${row.name}`,
    price: row.list_price
  }))
}

export function serviceSelectOptions(services: Service[], categoryId: string | null) {
  let rows = services.filter(row => row.status === 'active')
  if (categoryId) {
    rows = rows.filter(row => row.category_id === categoryId)
  }
  return rows.map(row => ({
    value: row.id,
    label: `${row.service_code} — ${row.name}`,
    price: row.list_price
  }))
}

export function validateOpportunityLineItems(items: OpportunityLineItemDraft[]): string | null {
  if (!items.length) return 'lineItemsRequired'
  for (const row of items) {
    if (!row.category_id) return 'lineItemCategoryRequired'
    if (!row.product_id && !row.service_id && !row.item_name.trim()) {
      return 'lineItemRequired'
    }
  }
  return null
}
