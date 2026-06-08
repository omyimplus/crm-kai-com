import type { OrgRole, OrgRoleCreate, OrgRolePermissions, OrgRoleUpdate } from '~/types/crm'
import { buildDefaultPermissions, normalizePermissions } from '~/utils/orgRolePermissions'

export function useOrgRoles() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()

  const canManage = computed(() =>
    profile.value?.role === 'owner' || profile.value?.role === 'admin'
  )

  function mapRole(row: OrgRole): OrgRole {
    return {
      ...row,
      permissions: normalizePermissions(row.permissions)
    }
  }

  async function list(): Promise<OrgRole[]> {
    const { data, error } = await supabase.rpc('list_org_roles')
    if (error) throw error
    return ((data ?? []) as OrgRole[]).map(mapRole)
  }

  async function get(roleId: string): Promise<OrgRole | null> {
    const { data, error } = await supabase.rpc('get_org_role', { p_role_id: roleId })
    if (error) throw error
    const row = (data as OrgRole[] | null)?.[0]
    return row ? mapRole(row) : null
  }

  async function create(payload: OrgRoleCreate): Promise<string> {
    const { data, error } = await supabase.rpc('create_org_role', {
      p_code: payload.code.trim().toLowerCase(),
      p_label: payload.label.trim(),
      p_description: payload.description?.trim() || null,
      p_permissions: payload.permissions ?? buildDefaultPermissions()
    })
    if (error) throw error
    return data as string
  }

  async function update(roleId: string, payload: OrgRoleUpdate) {
    const { error } = await supabase.rpc('update_org_role', {
      p_role_id: roleId,
      p_label: payload.label ?? null,
      p_description: payload.description ?? null,
      p_permissions: payload.permissions ?? null,
      p_is_active: payload.is_active ?? null
    })
    if (error) throw error
  }

  async function updatePermissions(roleId: string, permissions: OrgRolePermissions) {
    await update(roleId, { permissions: normalizePermissions(permissions) })
  }

  async function remove(roleId: string) {
    const { error } = await supabase.rpc('delete_org_role', { p_role_id: roleId })
    if (error) throw error
  }

  function activeRoles(roles: OrgRole[]) {
    return roles.filter(role => role.is_active)
  }

  return {
    canManage,
    list,
    get,
    create,
    update,
    updatePermissions,
    remove,
    activeRoles,
    buildDefaultPermissions
  }
}
