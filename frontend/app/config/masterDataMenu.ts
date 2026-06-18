export type MasterDataMenuKey =
  | 'customer'
  | 'contact'
  | 'salesTarget'
  | 'products'
  | 'category'
  | 'leadSource'
  | 'partner'
  | 'unit'
  | 'salesTeam'
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
  { key: 'customer', to: '/app/customer', icon: 'i-lucide-building', ready: true },
  { key: 'contact', to: '/app/contact', icon: 'i-lucide-contact', ready: true },
  { key: 'salesTarget', to: '/app/sales-target', icon: 'i-lucide-target', ready: true },
  { key: 'products', to: '/app/product', icon: 'i-lucide-package', ready: true },
  { key: 'category', to: '/app/category', icon: 'i-lucide-tags', ready: true },
  { key: 'unit', to: '/app/unit', icon: 'i-lucide-ruler', ready: true },
  { key: 'leadSource', to: '/app/lead-source', icon: 'i-lucide-radar', ready: true },
  { key: 'partner', to: '/app/partner', icon: 'i-lucide-handshake', ready: true },
  { key: 'salesTeam', to: '/app/sales-team', icon: 'i-lucide-users', ready: true },
  { key: 'moduleStatuses', to: '/app/module-status', icon: 'i-lucide-list-tree', ready: true },
  { key: 'jobCode', to: '/app/job-code', icon: 'i-lucide-hash', ready: true }
]
