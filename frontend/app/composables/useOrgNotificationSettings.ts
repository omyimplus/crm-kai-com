import type { OrgNotificationSettings } from '~/config/orgNotificationSettings'
import {
  mergeOrgNotificationSettings,
  orgNotificationSettingsToPayload
} from '~/utils/orgNotificationSettings'

export function useOrgNotificationSettings() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()

  const canManage = computed(() =>
    profile.value?.role === 'owner' || profile.value?.role === 'admin'
  )

  async function get(): Promise<OrgNotificationSettings> {
    const { data, error } = await supabase.rpc('get_org_notification_settings')
    if (error) throw error
    return mergeOrgNotificationSettings(data as Record<string, unknown>)
  }

  async function update(settings: OrgNotificationSettings) {
    const { error } = await supabase.rpc('update_org_notification_settings', {
      p_notifications: orgNotificationSettingsToPayload(settings)
    })
    if (error) throw error
  }

  async function sendTestEmail() {
    const { error } = await supabase.rpc('send_org_notification_email')
    if (error) throw error
  }

  return {
    canManage,
    get,
    update,
    sendTestEmail
  }
}
