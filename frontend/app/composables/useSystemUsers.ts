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

  async function create(payload: OrgUserCreate): Promise<string> {
    const { data, error } = await supabase.rpc('admin_create_org_user', {
      p_email: payload.email.trim(),
      p_username: payload.username.trim(),
      p_password: payload.password,
      p_full_name: payload.full_name.trim(),
      p_role: payload.role,
      p_is_active: payload.is_active,
      p_org_role_ids: payload.org_role_ids ?? []
    })
    if (error) throw error
    return data as string
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
      p_org_role_ids: payload.org_role_ids ?? [],
      p_set_org_roles: payload.skip_org_roles !== true,
      p_avatar_url: payload.set_avatar ? (payload.avatar_url ?? null) : null,
      p_set_avatar: payload.set_avatar ?? false
    })
    if (error) throw error
  }

  function assignableRoles(currentUserRole: ProfileRole | undefined): ProfileRole[] {
    if (currentUserRole === 'owner') {
      return ['owner', 'admin', 'employee']
    }
    if (currentUserRole === 'admin') {
      return ['admin', 'employee']
    }
    return []
  }

  return { canManage, list, create, update, assignableRoles }
}
