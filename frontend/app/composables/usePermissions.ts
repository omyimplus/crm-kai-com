import type { AppMenuKey } from '~/config/appMenu'
import type { MasterDataMenuKey } from '~/config/masterDataMenu'
import type { OrgRolePermissions } from '~/types/crm'
import { hasModuleAction, normalizePermissions } from '~/utils/orgRolePermissions'

export function usePermissions() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()
  const permissions = useState<OrgRolePermissions | null>('orgRolePermissions', () => null)
  const permissionsLoaded = useState('orgRolePermissionsLoaded', () => false)

  const isAdmin = computed(() =>
    profile.value?.role === 'owner' || profile.value?.role === 'admin'
  )

  async function loadPermissions() {
    if (!profile.value) {
      permissions.value = null
      permissionsLoaded.value = true
      return
    }

    if (isAdmin.value) {
      permissions.value = null
      permissionsLoaded.value = true
      return
    }

    if (!profile.value.org_role_id) {
      permissions.value = null
      permissionsLoaded.value = true
      return
    }

    const { data, error } = await supabase.rpc('get_my_org_role_permissions')
    if (error) throw error
    permissions.value = data ? normalizePermissions(data as OrgRolePermissions) : null
    permissionsLoaded.value = true
  }

  async function ensurePermissions() {
    if (!permissionsLoaded.value) {
      await loadPermissions()
    }
  }

  const hasOrgRole = computed(() => Boolean(profile.value?.org_role_id))

  function canViewModule(moduleKey: string): boolean {
    if (isAdmin.value) return true
    // ยังไม่มอบ Org role — แสดงเมนู scaffold ตามเดิม (ยกเว้น roles/setup ที่จำกัดแยก)
    if (!hasOrgRole.value || !permissions.value) {
      return moduleKey.startsWith('app.') || moduleKey.startsWith('master.')
    }
    return hasModuleAction(permissions.value, moduleKey, 'view')
  }

  function canViewAppMenu(key: AppMenuKey): boolean {
    if (key === 'dashboard') return true
    if (isAdmin.value) return true
    if (!hasOrgRole.value || !permissions.value) return true
    return canViewModule(`app.${key}`)
  }

  function canViewMasterData(key: MasterDataMenuKey): boolean {
    if (isAdmin.value) return true
    if (!hasOrgRole.value || !permissions.value) return true
    return canViewModule(`master.${key}`)
  }

  const canAccessSetup = computed(() => isAdmin.value)

  async function reloadPermissions() {
    permissionsLoaded.value = false
    await loadPermissions()
  }

  return {
    permissions,
    permissionsLoaded,
    isAdmin,
    canAccessSetup,
    loadPermissions,
    reloadPermissions,
    ensurePermissions,
    canViewModule,
    canViewAppMenu,
    canViewMasterData
  }
}
