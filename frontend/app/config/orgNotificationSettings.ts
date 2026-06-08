export const ORG_NOTIFICATION_SETTING_KEYS = [
  'emailNotifications',
  'pushNotifications',
  'taskReminders',
  'paymentAlerts',
  'leadAssignments',
  'weeklyReport'
] as const

export type OrgNotificationSettingKey = (typeof ORG_NOTIFICATION_SETTING_KEYS)[number]

export type OrgNotificationSettings = Record<OrgNotificationSettingKey, boolean>

export const DEFAULT_ORG_NOTIFICATION_SETTINGS: OrgNotificationSettings = {
  emailNotifications: true,
  pushNotifications: true,
  taskReminders: true,
  paymentAlerts: true,
  leadAssignments: true,
  weeklyReport: false
}
