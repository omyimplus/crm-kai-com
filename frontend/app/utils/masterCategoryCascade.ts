import type { Category } from '~/types/crm'
import type { CategoryModuleKey } from '~/config/masterCategory'
import { categoriesById, categoryDepth } from '~/utils/masterCategory'

export type OpportunityLineType = 'product' | 'service'

export function categoryChildren(
  categories: Category[],
  parentId: string | null
): Category[] {
  return categories
    .filter(row => row.parent_id === parentId)
    .sort((a, b) => a.sort_order - b.sort_order || a.name.localeCompare(b.name, 'th'))
}

export function isCategoryLeaf(categories: Category[], categoryId: string): boolean {
  return !categories.some(row => row.parent_id === categoryId)
}

/** สินค้า: ครบ 3 ชั้น + leaf · บริการ: อย่างน้อย 2 ชั้น + leaf */
export function canPickCatalogItem(
  categories: Category[],
  categoryId: string | null,
  lineType: OpportunityLineType
): boolean {
  if (!categoryId) return false
  const depth = categoryDepth(categories, categoryId)
  const leaf = isCategoryLeaf(categories, categoryId)
  if (!leaf) return false
  if (lineType === 'product') return depth >= 2
  return depth >= 1
}

export function maxCascadeLevels(lineType: OpportunityLineType): number {
  return lineType === 'product' ? 3 : 3
}

export function categoriesForModule(
  categories: Category[],
  moduleKey: CategoryModuleKey
): Category[] {
  return categories.filter(row => row.module_key === moduleKey)
}

export function cascadeOptions(
  categories: Category[],
  parentId: string | null
) {
  return categoryChildren(categories, parentId).map(row => ({
    label: row.name,
    value: row.id
  }))
}

export function resolveCategoryPath(
  categories: Category[],
  pathIds: (string | null)[]
): string | null {
  for (let index = pathIds.length - 1; index >= 0; index -= 1) {
    const id = pathIds[index]
    if (id) return id
  }
  return null
}

export function pathIdsFromCategory(
  categories: Category[],
  categoryId: string | null,
  maxLevels: number
): (string | null)[] {
  const map = categoriesById(categories)
  const ids: string[] = []
  let current = categoryId ? map.get(categoryId) : undefined

  while (current) {
    ids.unshift(current.id)
    current = current.parent_id ? map.get(current.parent_id) : undefined
  }

  const slots: (string | null)[] = Array.from({ length: maxLevels }, () => null)
  const offset = Math.max(0, maxLevels - ids.length)
  ids.forEach((id, index) => {
    slots[offset + index] = id
  })
  return slots
}
