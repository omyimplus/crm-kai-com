import type { Category } from '~/types/crm'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'
import {
  CATEGORY_MODULE_KEY,
  CATEGORY_STATUSES,
  type CategoryModuleKey,
  type CategoryStatus
} from '~/config/masterCategory'

export interface MasterCategoryFormInput {
  module_key: CategoryModuleKey
  category_code: string
  name: string
  description: string
  parent_id: string | null
  sort_order: number
  color: string
  status: CategoryStatus
  notes: string
}

export function defaultMasterCategoryFormInput(
  moduleKey: CategoryModuleKey = CATEGORY_MODULE_KEY
): MasterCategoryFormInput {
  return {
    module_key: moduleKey,
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

export function categoriesById(categories: Category[]): Map<string, Category> {
  return new Map(categories.map(category => [category.id, category]))
}

/** Full path e.g. "ลูกค้าโครงการ › โน๊ตบุค › Dell" */
export function categoryPathLabel(
  categories: Category[],
  categoryId: string | null | undefined,
  separator = ' › '
): string {
  if (!categoryId) return ''

  const map = categoriesById(categories)
  const parts: string[] = []
  const seen = new Set<string>()
  let current = map.get(categoryId)

  while (current) {
    if (seen.has(current.id)) break
    seen.add(current.id)
    parts.unshift(current.name.trim())
    current = current.parent_id ? map.get(current.parent_id) : undefined
  }

  return parts.join(separator)
}

export function categoryDepth(categories: Category[], categoryId: string): number {
  const map = categoriesById(categories)
  let depth = 0
  const seen = new Set<string>()
  let current = map.get(categoryId)

  while (current?.parent_id) {
    if (seen.has(current.id)) break
    seen.add(current.id)
    depth += 1
    current = map.get(current.parent_id)
  }

  return depth
}

export function categoryDescendantIds(categories: Category[], rootId: string): Set<string> {
  const childrenByParent = new Map<string, Category[]>()

  for (const category of categories) {
    if (!category.parent_id) continue
    const siblings = childrenByParent.get(category.parent_id) ?? []
    siblings.push(category)
    childrenByParent.set(category.parent_id, siblings)
  }

  const result = new Set<string>()
  const stack = [rootId]

  while (stack.length) {
    const id = stack.pop()
    if (!id) continue
    for (const child of childrenByParent.get(id) ?? []) {
      result.add(child.id)
      stack.push(child.id)
    }
  }

  return result
}

/** Leaf categories — no active children (typical attach point for products). */
export function leafCategories(categories: Category[]): Category[] {
  const parentIds = new Set(
    categories
      .map(category => category.parent_id)
      .filter((id): id is string => Boolean(id))
  )

  return categories.filter(category => !parentIds.has(category.id))
}

export interface CategoryTreeNode {
  category: Category
  children: CategoryTreeNode[]
}

export type CategoryLevelKey = 'client' | 'type' | 'brand' | 'other'

export function categoryLevelKey(depth: number): CategoryLevelKey {
  if (depth <= 0) return 'client'
  if (depth === 1) return 'type'
  if (depth === 2) return 'brand'
  return 'other'
}

function sortCategoriesForTree(categories: Category[]) {
  return [...categories].sort(
    (a, b) => a.sort_order - b.sort_order || a.name.localeCompare(b.name, 'th')
  )
}

export function buildCategoryTree(categories: Category[]): CategoryTreeNode[] {
  const childrenByParent = new Map<string | null, Category[]>()

  for (const category of categories) {
    const key = category.parent_id
    const siblings = childrenByParent.get(key) ?? []
    siblings.push(category)
    childrenByParent.set(key, siblings)
  }

  function build(parentId: string | null): CategoryTreeNode[] {
    return sortCategoriesForTree(childrenByParent.get(parentId) ?? []).map(category => ({
      category,
      children: build(category.id)
    }))
  }

  return build(null)
}

export function collectCategoryTreeIds(nodes: CategoryTreeNode[]): string[] {
  const ids: string[] = []

  function walk(list: CategoryTreeNode[]) {
    for (const node of list) {
      ids.push(node.category.id)
      if (node.children.length) walk(node.children)
    }
  }

  walk(nodes)
  return ids
}

export function filterCategoriesWithAncestors(
  categories: Category[],
  predicate: (category: Category) => boolean
): Category[] {
  const map = categoriesById(categories)
  const included = new Set<string>()

  for (const category of categories) {
    if (!predicate(category)) continue

    let current: Category | undefined = category
    const seen = new Set<string>()
    while (current) {
      if (seen.has(current.id)) break
      seen.add(current.id)
      included.add(current.id)
      current = current.parent_id ? map.get(current.parent_id) : undefined
    }
  }

  return categories.filter(category => included.has(category.id))
}

export function categoryToFormInput(category: Category): MasterCategoryFormInput {
  return {
    module_key: category.module_key === 'service' ? 'service' : 'product',
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
    module_key: form.module_key,
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
  const excluded = new Set<string>()
  if (excludeId) {
    excluded.add(excludeId)
    for (const id of categoryDescendantIds(categories, excludeId)) {
      excluded.add(id)
    }
  }

  return categories
    .filter(category => !excluded.has(category.id))
    .map(category => ({
      value: category.id,
      label: categoryPathLabel(categories, category.id)
    }))
    .sort((a, b) => a.label.localeCompare(b.label, 'th'))
}

export function categorySelectOptions(
  categories: Category[],
  { leafOnly = false }: { leafOnly?: boolean } = {}
) {
  const rows = leafOnly ? leafCategories(categories) : categories

  return rows
    .map(category => ({
      value: category.id,
      label: categoryPathLabel(categories, category.id)
    }))
    .sort((a, b) => a.label.localeCompare(b.label, 'th'))
}
