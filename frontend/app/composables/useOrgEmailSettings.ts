import type { OrgEmailSettings, OrgEmailSettingsForm } from '~/config/orgEmailSettings'
import {
  mergeOrgEmailSettings,
  orgEmailSettingsToPayload
} from '~/utils/orgEmailSettings'

export function useOrgEmailSettings() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()

  const canManage = computed(() =>
    profile.value?.role === 'owner' || profile.value?.role === 'admin'
  )

  async function get(): Promise<OrgEmailSettings> {
    const { data, error } = await supabase.rpc('get_org_email_settings')
    if (error) throw error
    const row = data as Record<string, unknown>
    return mergeOrgEmailSettings(row, Boolean(row.hasPassword))
  }

  async function update(form: OrgEmailSettingsForm) {
    const { error } = await supabase.rpc('update_org_email_settings', {
      p_payload: orgEmailSettingsToPayload(form)
    })
    if (error) throw error
  }

  async function testConnection(testRecipient?: string) {
    const { error } = await supabase.rpc('test_org_email_connection', {
      p_test_recipient: testRecipient?.trim() || null
    })
    if (error) throw error
  }

  return {
    canManage,
    get,
    update,
    testConnection
  }
}
