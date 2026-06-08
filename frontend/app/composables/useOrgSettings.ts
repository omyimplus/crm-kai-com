import type { OrgSettingsRow } from '~/types/crm'

/** Org-level settings row (timezone, currency in settings jsonb) */
export function useOrgSettings() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()

  const canManage = computed(() =>
    profile.value?.role === 'owner' || profile.value?.role === 'admin'
  )

  async function get(): Promise<OrgSettingsRow> {
    const { data, error } = await supabase.rpc('get_org_settings')
    if (error) throw error
    const row = (data as OrgSettingsRow[] | null)?.[0]
    if (!row) {
      throw new Error('Organization not found')
    }
    return row
  }

  return {
    canManage,
    get
  }
}
