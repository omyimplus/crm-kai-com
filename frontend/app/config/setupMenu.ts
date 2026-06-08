export type SetupMenuKey =
  | 'systemUsers'
  | 'dataManagement'
  | 'userActivity'
  | 'activeSessions'
  | 'userApprovals'
  | 'settings'

export interface SetupMenuItem {
  key: SetupMenuKey
  to: string
  icon: string
  /** หน้าพร้อมใช้งาน — ไม่แสดง badge เร็ว ๆ นี้ */
  ready?: boolean
}

export const setupMenuItems: SetupMenuItem[] = [
  { key: 'systemUsers', to: '/app/setup/system-users', icon: 'i-lucide-users-round', ready: true },
  { key: 'dataManagement', to: '/app/setup/data-management', icon: 'i-lucide-file-spreadsheet' },
  { key: 'userActivity', to: '/app/setup/user-activity', icon: 'i-lucide-activity', ready: true },
  { key: 'activeSessions', to: '/app/setup/active-sessions', icon: 'i-lucide-monitor-smartphone' },
  { key: 'userApprovals', to: '/app/setup/user-approvals', icon: 'i-lucide-user-check' },
  { key: 'settings', to: '/app/setup/settings', icon: 'i-lucide-settings' }
]
