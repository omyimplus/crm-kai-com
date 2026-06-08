export type MasterDataMenuKey =
  | 'customer'
  | 'contact'
  | 'salesTarget'
  | 'products'
  | 'category'
  | 'leadSource'
  | 'unit'
  | 'employee'
  | 'salesTeam'
  | 'roles'
  | 'moduleStatuses'
  | 'jobCode'

export interface MasterDataMenuItem {
  key: MasterDataMenuKey
  to: string
  icon: string
  /** หน้าพร้อมใช้งาน — ไม่แสดง badge เร็ว ๆ นี้ */
  ready?: boolean
}

export const masterDataMenuItems: MasterDataMenuItem[] = [
  { key: 'roles', to: '/app/master-data/roles', icon: 'i-lucide-shield-check', ready: true },
  { key: 'customer', to: '/app/master-data/customer', icon: 'i-lucide-building' },
  { key: 'contact', to: '/app/master-data/contact', icon: 'i-lucide-contact' },
  { key: 'salesTarget', to: '/app/master-data/sales-target', icon: 'i-lucide-target' },
  { key: 'products', to: '/app/master-data/products', icon: 'i-lucide-package' },
  { key: 'category', to: '/app/master-data/category', icon: 'i-lucide-tags' },
  { key: 'leadSource', to: '/app/master-data/lead-source', icon: 'i-lucide-radar' },
  { key: 'unit', to: '/app/master-data/unit', icon: 'i-lucide-ruler' },
  { key: 'employee', to: '/app/master-data/employee', icon: 'i-lucide-id-card' },
  { key: 'salesTeam', to: '/app/master-data/sales-team', icon: 'i-lucide-users' },
  { key: 'moduleStatuses', to: '/app/master-data/module-statuses', icon: 'i-lucide-list-tree' },
  { key: 'jobCode', to: '/app/master-data/job-code', icon: 'i-lucide-hash' }
]
