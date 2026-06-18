import type { ComposerTranslation } from 'vue-i18n'
import type { DataChangeAction } from '~/types/crm'

export interface DataChangeDisplayRow {
  key: string
  label: string
  before: string | null
  after: string | null
  changed: boolean
}

const HIDDEN_KEYS = new Set(['id', 'org_id', 'org_role_ids'])

const ENUM_FIELD_I18N: Record<string, string> = {
  contact_role: 'masterData.contact.options.role',
  customer_type: 'masterData.customer.options.customerType',
  status: 'masterData.customer.options.status',
  industry: 'masterData.customer.options.industry',
  industry_segment: 'masterData.customer.options.industrySegment',
  sales_grade: 'masterData.customer.options.salesGrade',
  role: 'profile.roles',
  period_type: 'masterData.salesTarget.options.periodType'
}

function humanizeKey(key: string): string {
  return key
    .replace(/_/g, ' ')
    .replace(/\b\w/g, char => char.toUpperCase())
}

function valuesEqual(a: unknown, b: unknown): boolean {
  if (a === b) return true
  if (a == null && b == null) return true
  if (typeof a === 'object' || typeof b === 'object') {
    return JSON.stringify(a) === JSON.stringify(b)
  }
  return false
}

function collectKeys(
  oldData: Record<string, unknown> | null,
  newData: Record<string, unknown> | null
): string[] {
  const keys = new Set<string>()
  for (const key of Object.keys(oldData ?? {})) keys.add(key)
  for (const key of Object.keys(newData ?? {})) keys.add(key)
  return [...keys].sort((a, b) => a.localeCompare(b))
}

function formatPermissions(value: unknown, t: ComposerTranslation): string {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return formatPrimitive(value, t, 'permissions')
  }

  const lines: string[] = []
  for (const [moduleKey, actions] of Object.entries(value as Record<string, unknown>)) {
    if (!actions || typeof actions !== 'object' || Array.isArray(actions)) continue
    const enabled = Object.entries(actions as Record<string, boolean>)
      .filter(([, on]) => on)
      .map(([action]) => t(`setup.roles.permissions.actions.${action}`, action))
    if (enabled.length) {
      lines.push(`${moduleKey}: ${enabled.join(', ')}`)
    }
  }

  return lines.length
    ? lines.join('\n')
    : t('setup.userActivity.fieldValues.empty')
}

function formatPrimitive(
  value: unknown,
  t: ComposerTranslation,
  key: string
): string {
  if (value == null || value === '') {
    return t('setup.userActivity.fieldValues.empty')
  }

  if (typeof value === 'boolean') {
    return value
      ? t('setup.userActivity.fieldValues.yes')
      : t('setup.userActivity.fieldValues.no')
  }

  if (Array.isArray(value)) {
    if (!value.length) return t('setup.userActivity.fieldValues.empty')
    return value.map(item => formatPrimitive(item, t, key)).join(', ')
  }

  if (key === 'permissions') {
    return formatPermissions(value, t)
  }

  if (typeof value === 'string') {
    const enumBase = ENUM_FIELD_I18N[key]
    if (enumBase) {
      return t(`${enumBase}.${value}`, value)
    }
    if (/^\d{4}-\d{2}-\d{2}T/.test(value)) {
      const date = new Date(value)
      if (!Number.isNaN(date.getTime())) {
        return date.toLocaleString()
      }
    }
    if (/^[0-9a-f-]{36}$/i.test(value)) {
      return value.slice(0, 8) + '…'
    }
    return value
  }

  if (typeof value === 'number') {
    return String(value)
  }

  if (typeof value === 'object') {
    return JSON.stringify(value, null, 2)
  }

  return String(value)
}

export function fieldLabel(key: string, t: ComposerTranslation): string {
  return t(`setup.userActivity.fields.${key}`, humanizeKey(key))
}

export function formatDataChangeValue(
  key: string,
  value: unknown,
  t: ComposerTranslation
): string {
  return formatPrimitive(value, t, key)
}

export function buildDataChangeDisplayRows(
  action: DataChangeAction,
  oldData: Record<string, unknown> | null,
  newData: Record<string, unknown> | null,
  t: ComposerTranslation
): DataChangeDisplayRow[] {
  const keys = collectKeys(oldData, newData).filter(key => !HIDDEN_KEYS.has(key))

  if (action === 'create' && newData) {
    return keys.map(key => ({
      key,
      label: fieldLabel(key, t),
      before: null,
      after: formatDataChangeValue(key, newData[key], t),
      changed: true
    }))
  }

  if (action === 'delete' && oldData) {
    return keys.map(key => ({
      key,
      label: fieldLabel(key, t),
      before: formatDataChangeValue(key, oldData[key], t),
      after: null,
      changed: true
    }))
  }

  return keys
    .map(key => {
      const before = oldData ? formatDataChangeValue(key, oldData[key], t) : null
      const after = newData ? formatDataChangeValue(key, newData[key], t) : null
      const changed = !valuesEqual(oldData?.[key], newData?.[key])
      return {
        key,
        label: fieldLabel(key, t),
        before,
        after,
        changed
      }
    })
    .filter(row => row.changed)
}

export interface DataChangeMetadataTag {
  key: string
  label: string
}

export function buildMetadataTags(
  metadata: Record<string, unknown> | null | undefined,
  t: ComposerTranslation
): DataChangeMetadataTag[] {
  if (!metadata) return []

  const tags: DataChangeMetadataTag[] = []

  if (metadata.cascade === true) {
    tags.push({ key: 'cascade', label: t('setup.userActivity.metadata.cascade') })
  }
  if (metadata.restore === true) {
    tags.push({ key: 'restore', label: t('setup.userActivity.metadata.restore') })
  }
  if (metadata.soft_delete === true) {
    tags.push({ key: 'soft_delete', label: t('setup.userActivity.metadata.softDelete') })
  }
  if (metadata.password_changed === true) {
    tags.push({ key: 'password_changed', label: t('setup.userActivity.metadata.passwordChanged') })
  }

  return tags
}
