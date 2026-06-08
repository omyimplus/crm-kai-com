export type SettingsTabKey =
  | 'companyInfo'
  | 'notifications'
  | 'email'
  | 'authProviders'

export interface SettingsTabItem {
  key: SettingsTabKey
  icon: string
  ready: boolean
}

export const settingsTabs: SettingsTabItem[] = [
  { key: 'companyInfo', icon: 'i-lucide-building-2', ready: true },
  { key: 'notifications', icon: 'i-lucide-bell', ready: true },
  { key: 'email', icon: 'i-lucide-mail', ready: true },
  { key: 'authProviders', icon: 'i-lucide-key-round', ready: true }
]
