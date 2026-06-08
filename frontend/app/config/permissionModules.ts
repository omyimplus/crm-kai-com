import { appMenuItems, type AppMenuKey } from '~/config/appMenu'
import { masterDataMenuItems, type MasterDataMenuKey } from '~/config/masterDataMenu'

export const PERMISSION_ACTIONS = ['view', 'create', 'edit', 'delete', 'export'] as const
export type PermissionAction = typeof PERMISSION_ACTIONS[number]

export type PermissionGroup = 'app' | 'master'

export interface PermissionModule {
  key: string
  group: PermissionGroup
  menuKey: AppMenuKey | MasterDataMenuKey
  actions: PermissionAction[]
}

const APP_ACTIONS: PermissionAction[] = ['view', 'create', 'edit', 'delete']
const APP_REPORTS_ACTIONS: PermissionAction[] = [...APP_ACTIONS, 'export']
const MASTER_ACTIONS: PermissionAction[] = ['view', 'create', 'edit', 'delete']

export const permissionModuleGroups: { group: PermissionGroup, i18nKey: string }[] = [
  { group: 'app', i18nKey: 'appMenu.section' },
  { group: 'master', i18nKey: 'masterData.section' }
]

export const permissionModules: PermissionModule[] = [
  ...appMenuItems.map(item => ({
    key: `app.${item.key}`,
    group: 'app' as const,
    menuKey: item.key,
    actions: item.key === 'reports' ? APP_REPORTS_ACTIONS : APP_ACTIONS
  })),
  ...masterDataMenuItems.map(item => ({
    key: `master.${item.key}`,
    group: 'master' as const,
    menuKey: item.key,
    actions: MASTER_ACTIONS
  }))
]

export const permissionModuleKeys = permissionModules.map(module => module.key)
