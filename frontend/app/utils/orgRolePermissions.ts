import {
  PERMISSION_ACTIONS,
  permissionModules,
  type PermissionAction
} from '~/config/permissionModules'
import type { OrgRolePermissions } from '~/types/crm'

const validActions = new Set<string>(PERMISSION_ACTIONS)

export function buildDefaultPermissions(): OrgRolePermissions {
  const permissions: OrgRolePermissions = {}
  for (const module of permissionModules) {
    permissions[module.key] = []
  }
  return permissions
}

export function normalizePermissions(
  input: OrgRolePermissions | Record<string, unknown> | null | undefined
): OrgRolePermissions {
  const defaults = buildDefaultPermissions()
  if (!input || typeof input !== 'object') {
    return defaults
  }

  for (const module of permissionModules) {
    const raw = input[module.key]
    if (!Array.isArray(raw)) {
      continue
    }
    defaults[module.key] = raw.filter(
      (action): action is PermissionAction =>
        typeof action === 'string'
        && validActions.has(action)
        && module.actions.includes(action as PermissionAction)
    )
  }

  return defaults
}

export function hasModuleAction(
  permissions: OrgRolePermissions,
  moduleKey: string,
  action: PermissionAction
): boolean {
  return (permissions[moduleKey] ?? []).includes(action)
}

export function setModuleAction(
  permissions: OrgRolePermissions,
  moduleKey: string,
  action: PermissionAction,
  enabled: boolean
): OrgRolePermissions {
  const next = { ...permissions, [moduleKey]: [...(permissions[moduleKey] ?? [])] }
  const actions = new Set(next[moduleKey])

  if (enabled) {
    actions.add(action)
  } else {
    actions.delete(action)
  }

  next[moduleKey] = [...actions]
  return next
}

export function countGrantedPermissions(permissions: OrgRolePermissions): number {
  return Object.values(permissions).reduce((sum, actions) => sum + actions.length, 0)
}

export function setGroupViewAll(
  permissions: OrgRolePermissions,
  group: 'app' | 'master',
  enabled: boolean
): OrgRolePermissions {
  let next = { ...permissions }
  for (const module of permissionModules.filter(item => item.group === group)) {
    next = setModuleAction(next, module.key, 'view', enabled)
  }
  return next
}
