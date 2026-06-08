import type { AppMenuKey } from '~/config/appMenu'
import type { MasterDataMenuKey } from '~/config/masterDataMenu'
import type { OrgRolePermissions, ProfileRole } from '~/types/crm'
import { hasModuleAction, normalizePermissions } from '~/utils/orgRolePermissions'

const PLATFORM_CRM_ROLES: ProfileRole[] = ['employee']

export function usePermissions() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()
  const permissions = useState<OrgRolePermissions | null>('orgRolePermissions', () => null)
  const permissionsLoaded = useState('orgRolePermissionsLoaded', () => false)

  const platformRole = computed(() => profile.value?.role)

  const isAdmin = computed(() =>
    platformRole.value === 'owner' || platformRole.value === 'admin'
  )

  const isPlatformMember = computed(() =>
    platformRole.value != null && PLATFORM_CRM_ROLES.includes(platformRole.value)
  )

  async function loadPermissions() {
    if (!profile.value || !profile.value.is_active) {
      permissions.value = null
      permissionsLoaded.value = true
      return
    }

    if (isAdmin.value) {
      permissions.value = null
      permissionsLoaded.value = true
      return
    }

    const { data, error } = await supabase.rpc('get_my_org_role_permissions')
    if (error) throw error
    const normalized = data
      ? normalizePermissions(data as OrgRolePermissions)
      : null
    permissions.value = normalized && Object.keys(normalized).length > 0
      ? normalized
      : null
    permissionsLoaded.value = true
  }

  async function ensurePermissions() {
    if (!permissionsLoaded.value) {
      await loadPermissions()
    }
  }

  const hasOrgRole = computed(() =>
    Boolean(permissions.value && Object.keys(permissions.value).length > 0)
  )

  function canViewModule(moduleKey: string): boolean {
    if (!profile.value?.is_active) return false
    if (isAdmin.value) return true
    if (!isPlatformMember.value) return false
    if (!hasOrgRole.value || !permissions.value) {
      return moduleKey === 'app.dashboard'
    }
    return hasModuleAction(permissions.value, moduleKey, 'view')
  }

  function canViewAppMenu(key: AppMenuKey): boolean {
    if (key === 'dashboard') return true
    if (isAdmin.value) return true
    if (!isPlatformMember.value) return false
    if (!hasOrgRole.value || !permissions.value) return false
    return canViewModule(`app.${key}`)
  }

  function canViewMasterData(key: MasterDataMenuKey): boolean {
    if (isAdmin.value) return true
    if (!isPlatformMember.value) return false
    if (!hasOrgRole.value || !permissions.value) return false
    return canViewModule(`master.${key}`)
  }

  function canWriteModule(moduleKey: string): boolean {
    if (isAdmin.value) return true
    if (!hasOrgRole.value || !permissions.value) return false
    const perms = permissions.value
    return ['create', 'edit', 'delete'].some(action =>
      hasModuleAction(perms, moduleKey, action as 'create' | 'edit' | 'delete')
    )
  }

  const canAccessSetup = computed(() => isAdmin.value)

  async function reloadPermissions() {
    permissionsLoaded.value = false
    await loadPermissions()
  }

  return {
    permissions,
    permissionsLoaded,
    platformRole,
    isAdmin,
    isPlatformMember,
    canAccessSetup,
    loadPermissions,
    reloadPermissions,
    ensurePermissions,
    canViewModule,
    canViewAppMenu,
    canViewMasterData,
    canWriteModule
  }
}
