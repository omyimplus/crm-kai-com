export type AppMenuKey =
  | 'dashboard'
  | 'tasks'
  | 'lead'
  | 'opportunity'
  | 'quotations'
  | 'pipeline'
  | 'salesOrder'
  | 'invoices'
  | 'reports'
  | 'projects'
  | 'contractAgreements'
  | 'service'

export interface AppMenuItem {
  key: AppMenuKey
  to: string
  icon: string
}

export const appMenuItems: AppMenuItem[] = [
  { key: 'dashboard', to: '/app', icon: 'i-lucide-layout-dashboard' },
  { key: 'tasks', to: '/app/tasks', icon: 'i-lucide-list-checks' },
  { key: 'lead', to: '/app/leads', icon: 'i-lucide-user-plus' },
  { key: 'opportunity', to: '/app/opportunities', icon: 'i-lucide-sparkles' },
  { key: 'quotations', to: '/app/quotations', icon: 'i-lucide-file-text' },
  { key: 'pipeline', to: '/app/pipeline', icon: 'i-lucide-kanban' },
  { key: 'salesOrder', to: '/app/sales-orders', icon: 'i-lucide-shopping-cart' },
  { key: 'invoices', to: '/app/invoices', icon: 'i-lucide-receipt' },
  { key: 'reports', to: '/app/reports', icon: 'i-lucide-bar-chart-3' },
  { key: 'projects', to: '/app/projects', icon: 'i-lucide-folder-kanban' },
  { key: 'contractAgreements', to: '/app/contract-agreements', icon: 'i-lucide-file-signature' },
  { key: 'service', to: '/app/service', icon: 'i-lucide-headphones' }
]
