/** ข้อมูลจำลอง dashboard — ตาม demo KuTo CRM (preview เท่านั้น) */

export interface DashboardMockKpi {
  key: string
  labelKey: string
  value: string
  icon: string
}

export interface DashboardMockCustomerRow {
  id: string
  name: string
  code: string
  industry: string
  customerType: string
  owner: string
  tier: string
  totalRevenue: string
  openPipeline: string
  openTickets: number
  healthScore: number
}

export const dashboardMockKpis: DashboardMockKpi[] = [
  { key: 'salesTarget', labelKey: 'dashboard.mock.kpi.salesTarget', value: '฿48.2M', icon: 'i-lucide-target' },
  { key: 'wonRevenue', labelKey: 'dashboard.mock.kpi.wonRevenue', value: '฿31.6M', icon: 'i-lucide-circle-dollar-sign' },
  { key: 'openPipeline', labelKey: 'dashboard.mock.kpi.openPipeline', value: '฿86.9M', icon: 'i-lucide-trending-up' },
  { key: 'forecastRevenue', labelKey: 'dashboard.mock.kpi.forecastRevenue', value: '฿42.8M', icon: 'i-lucide-trending-up' },
  { key: 'openTickets', labelKey: 'dashboard.mock.kpi.openTickets', value: '284', icon: 'i-lucide-headphones' },
  { key: 'renewalAlert', labelKey: 'dashboard.mock.kpi.renewalAlert', value: '26', icon: 'i-lucide-shield-check' }
]

export const dashboardMockCustomers: DashboardMockCustomerRow[] = [
  {
    id: '1',
    name: 'Siam Cement Group',
    code: 'CUS-1024',
    industry: 'Manufacturing',
    customerType: 'Enterprise',
    owner: 'นิชา',
    tier: 'Platinum',
    totalRevenue: '฿18.2M',
    openPipeline: '฿7.4M',
    openTickets: 6,
    healthScore: 92
  },
  {
    id: '2',
    name: 'CP All',
    code: 'CUS-1098',
    industry: 'Retail',
    customerType: 'Key Account',
    owner: 'ภาคิน',
    tier: 'Gold',
    totalRevenue: '฿15.7M',
    openPipeline: '฿5.1M',
    openTickets: 2,
    healthScore: 86
  },
  {
    id: '3',
    name: 'Bangkok Dusit Medical',
    code: 'CUS-1187',
    industry: 'Healthcare',
    customerType: 'Enterprise',
    owner: 'มินตรา',
    tier: 'Platinum',
    totalRevenue: '฿12.4M',
    openPipeline: '฿3.8M',
    openTickets: 9,
    healthScore: 73
  }
]

export const dashboardMockCustomer360Tabs = [
  'overview',
  'companyInfo',
  'contacts',
  'opportunities',
  'documents',
  'financial'
] as const

export const dashboardMockCustomer360Cards = [
  'customerProfile',
  'revenueSummary',
  'aiRecommendation'
] as const

export type DashboardMockStatusTone = 'emerald' | 'amber' | 'red' | 'blue'

export interface DashboardMockStatusBadge {
  key: string
  labelKey: string
  tone: DashboardMockStatusTone
}

export const dashboardMockStatusBadges: DashboardMockStatusBadge[] = [
  { key: 'active', labelKey: 'dashboard.mock.status.active', tone: 'emerald' },
  { key: 'prospect', labelKey: 'dashboard.mock.status.prospect', tone: 'emerald' },
  { key: 'atRisk', labelKey: 'dashboard.mock.status.atRisk', tone: 'red' },
  { key: 'approved', labelKey: 'dashboard.mock.status.approved', tone: 'emerald' },
  { key: 'won', labelKey: 'dashboard.mock.status.won', tone: 'emerald' },
  { key: 'lost', labelKey: 'dashboard.mock.status.lost', tone: 'blue' }
]
