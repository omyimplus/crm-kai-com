import type { OrgUser, OrgUserCreate, OrgUserUpdate, ProfileRole } from '~/types/crm'

export function useSystemUsers() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()

  const canManage = computed(() =>
    profile.value?.role === 'owner' || profile.value?.role === 'admin'
  )

  async function list(): Promise<OrgUser[]> {
    const { data, error } = await supabase.rpc('list_org_users')
    if (error) throw error
    return (data ?? []) as OrgUser[]
  }

  async function create(payload: OrgUserCreate) {
    const { error } = await supabase.rpc('admin_create_org_user', {
      p_email: payload.email.trim(),
      p_username: payload.username.trim(),
      p_password: payload.password,
      p_full_name: payload.full_name.trim(),
      p_role: payload.role,
      p_is_active: payload.is_active,
      p_org_role_id: payload.org_role_id ?? null
    })
    if (error) throw error
  }

  async function update(userId: string, payload: OrgUserUpdate) {
    const { error } = await supabase.rpc('admin_update_org_user', {
      p_user_id: userId,
      p_full_name: payload.full_name ?? null,
      p_username: payload.username ?? null,
      p_email: payload.email ?? null,
      p_password: payload.password?.trim() ? payload.password : null,
      p_role: payload.role ?? null,
      p_is_active: payload.is_active ?? null,
      p_org_role_id: payload.org_role_id ?? null,
      p_set_org_role: true
    })
    if (error) throw error
  }

  function assignableRoles(currentUserRole: ProfileRole | undefined): ProfileRole[] {
    if (currentUserRole === 'owner') {
      return ['owner', 'admin', 'sales', 'readonly']
    }
    if (currentUserRole === 'admin') {
      return ['admin', 'sales', 'readonly']
    }
    return []
  }

  return { canManage, list, create, update, assignableRoles }
}
