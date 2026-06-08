import {
  DEFAULT_ORG_NOTIFICATION_SETTINGS,
  ORG_NOTIFICATION_SETTING_KEYS,
  type OrgNotificationSettings
} from '~/config/orgNotificationSettings'

export function mergeOrgNotificationSettings(
  stored: Record<string, unknown> | null | undefined
): OrgNotificationSettings {
  const merged = { ...DEFAULT_ORG_NOTIFICATION_SETTINGS }

  if (!stored || typeof stored !== 'object') {
    return merged
  }

  for (const key of ORG_NOTIFICATION_SETTING_KEYS) {
    const value = stored[key]
    if (typeof value === 'boolean') {
      merged[key] = value
    }
  }

  return merged
}

export function orgNotificationSettingsToPayload(
  settings: OrgNotificationSettings
): OrgNotificationSettings {
  const payload = { ...DEFAULT_ORG_NOTIFICATION_SETTINGS }
  for (const key of ORG_NOTIFICATION_SETTING_KEYS) {
    payload[key] = Boolean(settings[key])
  }
  return payload
}
