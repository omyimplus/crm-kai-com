/** Mock — รายชื่อลูกค้า `/app/customers` (ตาม figma.site) */

export type KutoCustomerStatusTabKey =
  | 'all'
  | 'active'
  | 'target'
  | 'inactive'
  | 'blacklist'
  | 'atRisk'
  | 'renewalSoon'
  | 'noActivity'

export type KutoCustomerStatusTag = Exclude<KutoCustomerStatusTabKey, 'all'>

export interface KutoCustomerListRow {
  id: string
  code: string
  name: string
  initials: string
  avatarBg: string
  customerTypeKey: string
  businessTypeKey: string
  tierKey: string
  ownerName: string
  revenueLabel: string
  pipelineLabel: string
  ticketCount: number
  renewalKey: string
  healthScore: number
  lastActivityKey: string
  actionKey?: string
  statusTags: KutoCustomerStatusTag[]
  taxId: string
  phone: string
  email: string
  industryKey: string
  groupKey: string
  statusLabelKey: string
  aiInsightKey: string
}

export const kutoCustomersListRows: KutoCustomerListRow[] = [
  {
    id: '1',
    code: 'CUS-1024',
    name: 'กลุ่มซีเมนต์ไทย',
    initials: 'SC',
    avatarBg: 'bg-teal-600',
    customerTypeKey: 'kuto.customers.list.types.enterprise',
    businessTypeKey: 'kuto.customers.list.business.manufacturing',
    tierKey: 'kuto.customers.list.tiers.platinum',
    ownerName: 'นิชา ศรีวงศ์',
    revenueLabel: '฿58.2M',
    pipelineLabel: '฿7.4M',
    ticketCount: 6,
    renewalKey: 'kuto.customers.list.renewal.days30',
    healthScore: 92,
    lastActivityKey: 'kuto.customers.list.activity.days2',
    actionKey: 'kuto.customers.list.actions.renewContract',
    statusTags: ['active', 'renewalSoon'],
    taxId: '0105533001234',
    phone: '02-586-3333',
    email: 'contact@scg.com',
    industryKey: 'kuto.customers.list.industry.materials',
    groupKey: 'kuto.customers.list.groups.holding',
    statusLabelKey: 'kuto.customers.list.status.active',
    aiInsightKey: 'kuto.customers.list.ai.scgRenewal'
  },
  {
    id: '2',
    code: 'CUS-1021',
    name: 'Bangkok Technology',
    initials: 'BT',
    avatarBg: 'bg-blue-600',
    customerTypeKey: 'kuto.customers.list.types.keyAccount',
    businessTypeKey: 'kuto.customers.list.business.itServices',
    tierKey: 'kuto.customers.list.tiers.gold',
    ownerName: 'สมศักดิ์ ใจดี',
    revenueLabel: '฿24.8M',
    pipelineLabel: '฿3.1M',
    ticketCount: 4,
    renewalKey: 'kuto.customers.list.renewal.atRisk',
    healthScore: 68,
    lastActivityKey: 'kuto.customers.list.activity.week1',
    statusTags: ['active', 'atRisk'],
    taxId: '0105567009876',
    phone: '02-111-4455',
    email: 'sales@bkktech.co.th',
    industryKey: 'kuto.customers.list.industry.technology',
    groupKey: 'kuto.customers.list.groups.standalone',
    statusLabelKey: 'kuto.customers.list.status.active',
    aiInsightKey: 'kuto.customers.list.ai.bkkTechRisk'
  },
  {
    id: '3',
    code: 'CUS-1018',
    name: 'Example Hospital',
    initials: 'EH',
    avatarBg: 'bg-rose-500',
    customerTypeKey: 'kuto.customers.list.types.keyAccount',
    businessTypeKey: 'kuto.customers.list.business.healthcare',
    tierKey: 'kuto.customers.list.tiers.gold',
    ownerName: 'นิชา ศรีวงศ์',
    revenueLabel: '฿18.5M',
    pipelineLabel: '฿2.2M',
    ticketCount: 2,
    renewalKey: 'kuto.customers.list.renewal.ok',
    healthScore: 85,
    lastActivityKey: 'kuto.customers.list.activity.days3',
    statusTags: ['active', 'target'],
    taxId: '0105561234567',
    phone: '02-777-8899',
    email: 'procurement@examplehospital.th',
    industryKey: 'kuto.customers.list.industry.healthcare',
    groupKey: 'kuto.customers.list.groups.standalone',
    statusLabelKey: 'kuto.customers.list.status.active',
    aiInsightKey: 'kuto.customers.list.ai.hospitalProposal'
  },
  {
    id: '4',
    code: 'CUS-1015',
    name: 'เอเชีย ฟู้ดส์',
    initials: 'AF',
    avatarBg: 'bg-orange-500',
    customerTypeKey: 'kuto.customers.list.types.sme',
    businessTypeKey: 'kuto.customers.list.business.retail',
    tierKey: 'kuto.customers.list.tiers.silver',
    ownerName: 'สมศักดิ์ ใจดี',
    revenueLabel: '฿6.2M',
    pipelineLabel: '฿890K',
    ticketCount: 1,
    renewalKey: 'kuto.customers.list.renewal.ok',
    healthScore: 74,
    lastActivityKey: 'kuto.customers.list.activity.days5',
    statusTags: ['active', 'target'],
    taxId: '0105544987654',
    phone: '02-333-2211',
    email: 'info@asiafoods.co.th',
    industryKey: 'kuto.customers.list.industry.retail',
    groupKey: 'kuto.customers.list.groups.standalone',
    statusLabelKey: 'kuto.customers.list.status.active',
    aiInsightKey: 'kuto.customers.list.ai.asiaFoodsFollowUp'
  },
  {
    id: '5',
    code: 'CUS-1012',
    name: 'Northern Logistics Ltd.',
    initials: 'NL',
    avatarBg: 'bg-violet-600',
    customerTypeKey: 'kuto.customers.list.types.standard',
    businessTypeKey: 'kuto.customers.list.business.logistics',
    tierKey: 'kuto.customers.list.tiers.silver',
    ownerName: 'นิชา ศรีวงศ์',
    revenueLabel: '฿4.1M',
    pipelineLabel: '฿520K',
    ticketCount: 0,
    renewalKey: 'kuto.customers.list.renewal.none',
    healthScore: 61,
    lastActivityKey: 'kuto.customers.list.activity.days14',
    statusTags: ['active'],
    taxId: '0105539876543',
    phone: '053-222-3344',
    email: 'ops@northlog.com',
    industryKey: 'kuto.customers.list.industry.logistics',
    groupKey: 'kuto.customers.list.groups.standalone',
    statusLabelKey: 'kuto.customers.list.status.active',
    aiInsightKey: 'kuto.customers.list.ai.northLogNurture'
  },
  {
    id: '6',
    code: 'CUS-1008',
    name: 'Metro Retail Chain',
    initials: 'MR',
    avatarBg: 'bg-emerald-600',
    customerTypeKey: 'kuto.customers.list.types.enterprise',
    businessTypeKey: 'kuto.customers.list.business.retail',
    tierKey: 'kuto.customers.list.tiers.platinum',
    ownerName: 'สมศักดิ์ ใจดี',
    revenueLabel: '฿42.0M',
    pipelineLabel: '฿5.8M',
    ticketCount: 3,
    renewalKey: 'kuto.customers.list.renewal.days30',
    healthScore: 88,
    lastActivityKey: 'kuto.customers.list.activity.days1',
    statusTags: ['active', 'renewalSoon', 'target'],
    taxId: '0105577112233',
    phone: '02-999-1122',
    email: 'it@metroretail.th',
    industryKey: 'kuto.customers.list.industry.retail',
    groupKey: 'kuto.customers.list.groups.holding',
    statusLabelKey: 'kuto.customers.list.status.active',
    aiInsightKey: 'kuto.customers.list.ai.metroRenewal'
  },
  {
    id: '7',
    code: 'CUS-0995',
    name: 'Stale Account Co.',
    initials: 'SA',
    avatarBg: 'bg-gray-500',
    customerTypeKey: 'kuto.customers.list.types.standard',
    businessTypeKey: 'kuto.customers.list.business.services',
    tierKey: 'kuto.customers.list.tiers.silver',
    ownerName: 'นิชา ศรีวงศ์',
    revenueLabel: '฿1.2M',
    pipelineLabel: '฿0',
    ticketCount: 0,
    renewalKey: 'kuto.customers.list.renewal.none',
    healthScore: 45,
    lastActivityKey: 'kuto.customers.list.activity.days90plus',
    statusTags: ['active', 'noActivity', 'atRisk'],
    taxId: '0105511223344',
    phone: '02-000-1111',
    email: 'admin@stale.co.th',
    industryKey: 'kuto.customers.list.industry.services',
    groupKey: 'kuto.customers.list.groups.standalone',
    statusLabelKey: 'kuto.customers.list.status.active',
    aiInsightKey: 'kuto.customers.list.ai.staleReengage'
  },
  {
    id: '8',
    code: 'CUS-0988',
    name: 'Blacklisted Vendor Ltd.',
    initials: 'BV',
    avatarBg: 'bg-red-700',
    customerTypeKey: 'kuto.customers.list.types.standard',
    businessTypeKey: 'kuto.customers.list.business.services',
    tierKey: 'kuto.customers.list.tiers.silver',
    ownerName: '—',
    revenueLabel: '฿0',
    pipelineLabel: '฿0',
    ticketCount: 0,
    renewalKey: 'kuto.customers.list.renewal.none',
    healthScore: 12,
    lastActivityKey: 'kuto.customers.list.activity.months6',
    statusTags: ['blacklist', 'inactive'],
    taxId: '0105599887766',
    phone: '02-555-0000',
    email: 'blocked@vendor.th',
    industryKey: 'kuto.customers.list.industry.services',
    groupKey: 'kuto.customers.list.groups.standalone',
    statusLabelKey: 'kuto.customers.list.status.blacklist',
    aiInsightKey: 'kuto.customers.list.ai.blacklist'
  },
  {
    id: '9',
    code: 'CUS-0982',
    name: 'Pacific Finance Group',
    initials: 'PF',
    avatarBg: 'bg-cyan-700',
    customerTypeKey: 'kuto.customers.list.types.keyAccount',
    businessTypeKey: 'kuto.customers.list.business.finance',
    tierKey: 'kuto.customers.list.tiers.gold',
    ownerName: 'สมศักดิ์ ใจดี',
    revenueLabel: '฿31.4M',
    pipelineLabel: '฿4.0M',
    ticketCount: 2,
    renewalKey: 'kuto.customers.list.renewal.ok',
    healthScore: 79,
    lastActivityKey: 'kuto.customers.list.activity.days7',
    statusTags: ['active', 'target'],
    taxId: '0105533445566',
    phone: '02-444-5566',
    email: 'cio@pacificfinance.th',
    industryKey: 'kuto.customers.list.industry.finance',
    groupKey: 'kuto.customers.list.groups.holding',
    statusLabelKey: 'kuto.customers.list.status.active',
    aiInsightKey: 'kuto.customers.list.ai.pacificUpsell'
  },
  {
    id: '10',
    code: 'CUS-0975',
    name: 'Dormant Industries',
    initials: 'DI',
    avatarBg: 'bg-stone-500',
    customerTypeKey: 'kuto.customers.list.types.sme',
    businessTypeKey: 'kuto.customers.list.business.manufacturing',
    tierKey: 'kuto.customers.list.tiers.silver',
    ownerName: 'นิชา ศรีวงศ์',
    revenueLabel: '฿2.8M',
    pipelineLabel: '฿120K',
    ticketCount: 1,
    renewalKey: 'kuto.customers.list.renewal.none',
    healthScore: 38,
    lastActivityKey: 'kuto.customers.list.activity.months3',
    statusTags: ['inactive'],
    taxId: '0105522334455',
    phone: '034-111-2233',
    email: 'contact@dormant.co.th',
    industryKey: 'kuto.customers.list.industry.materials',
    groupKey: 'kuto.customers.list.groups.standalone',
    statusLabelKey: 'kuto.customers.list.status.inactive',
    aiInsightKey: 'kuto.customers.list.ai.dormant'
  }
]

export const kutoCustomerStatusTabs = [
  { key: 'all', labelKey: 'kuto.customers.list.tabs.all', count: 1284 },
  { key: 'active', labelKey: 'kuto.customers.list.tabs.active', count: 1082 },
  { key: 'target', labelKey: 'kuto.customers.list.tabs.target', count: 142 },
  { key: 'inactive', labelKey: 'kuto.customers.list.tabs.inactive', count: 44 },
  { key: 'blacklist', labelKey: 'kuto.customers.list.tabs.blacklist', count: 17 },
  { key: 'atRisk', labelKey: 'kuto.customers.list.tabs.atRisk', count: 43 },
  { key: 'renewalSoon', labelKey: 'kuto.customers.list.tabs.renewalSoon', count: 26 },
  { key: 'noActivity', labelKey: 'kuto.customers.list.tabs.noActivity', count: 38 }
] as const

export const kutoCustomersListSummaryMeta = [
  {
    key: 'total',
    labelKey: 'kuto.customers.list.summary.total',
    subKey: 'kuto.customers.list.summary.totalSub',
    value: '1,284',
    trend: '+24',
    accent: '#17A8A3',
    icon: 'i-lucide-building-2',
    iconBg: 'bg-teal-50 text-teal-600',
    tabKey: 'all' as KutoCustomerStatusTabKey
  },
  {
    key: 'active',
    labelKey: 'kuto.customers.list.summary.active',
    subKey: 'kuto.customers.list.summary.activeSub',
    value: '1,082',
    trend: '84.3%',
    accent: '#10B981',
    icon: 'i-lucide-circle-check',
    iconBg: 'bg-emerald-50 text-emerald-600',
    tabKey: 'active' as KutoCustomerStatusTabKey
  },
  {
    key: 'target',
    labelKey: 'kuto.customers.list.summary.target',
    subKey: 'kuto.customers.list.summary.targetSub',
    value: '142',
    trend: '+18',
    accent: '#3B82F6',
    icon: 'i-lucide-target',
    iconBg: 'bg-blue-50 text-blue-600',
    tabKey: 'target' as KutoCustomerStatusTabKey
  },
  {
    key: 'renewal',
    labelKey: 'kuto.customers.list.summary.renewal',
    subKey: 'kuto.customers.list.summary.renewalSub',
    value: '26',
    trend: '+4',
    accent: '#F59E0B',
    icon: 'i-lucide-calendar-clock',
    iconBg: 'bg-amber-50 text-amber-600',
    tabKey: 'renewalSoon' as KutoCustomerStatusTabKey
  },
  {
    key: 'atRisk',
    labelKey: 'kuto.customers.list.summary.atRisk',
    subKey: 'kuto.customers.list.summary.atRiskSub',
    value: '43',
    trend: '-5',
    trendDown: true,
    accent: '#EF4444',
    icon: 'i-lucide-alert-triangle',
    iconBg: 'bg-red-50 text-red-600',
    tabKey: 'atRisk' as KutoCustomerStatusTabKey
  },
  {
    key: 'tickets',
    labelKey: 'kuto.customers.list.summary.tickets',
    subKey: 'kuto.customers.list.summary.ticketsSub',
    value: '38',
    accent: '#8B5CF6',
    icon: 'i-lucide-headphones',
    iconBg: 'bg-violet-50 text-violet-600',
    tabKey: 'noActivity' as KutoCustomerStatusTabKey
  }
] as const
