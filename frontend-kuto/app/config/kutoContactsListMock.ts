/** Mock — รายชื่อผู้ติดต่อ `/app/customers/contacts` (ตาม figma.site) */

export type KutoContactStatusTabKey =
  | 'all'
  | 'active'
  | 'inactive'
  | 'primary'
  | 'decisionMaker'
  | 'purchasing'
  | 'it'
  | 'neverContacted'
  | 'noActivity'

export type KutoContactTabTag = Exclude<KutoContactStatusTabKey, 'all'>

export interface KutoContactListRow {
  id: string
  code: string
  fullName: string
  initials: string
  avatarBg: string
  companyName: string
  companyId: string
  jobTitle: string
  department: string
  phone: string
  email: string
  lineId?: string
  roleKey: string
  isMainContact: boolean
  statusLabelKey: string
  ownerName: string
  lastActivityKey: string
  starRating: number
  relatedOpp?: string
  relatedQuotation?: string
  relatedTicket?: string
  aiInsightKey: string
  tabTags: KutoContactTabTag[]
}

export const kutoContactsListRows: KutoContactListRow[] = [
  {
    id: '1',
    code: 'CON-1042',
    fullName: 'คุณสมชาย วงศ์ไทย',
    initials: 'สว',
    avatarBg: 'bg-teal-600',
    companyName: 'กลุ่มซีเมนต์ไทย',
    companyId: '1',
    jobTitle: 'IT Director',
    department: 'IT',
    phone: '02-586-3333',
    email: 'somchai@scg.com',
    lineId: 'somchai.scg',
    roleKey: 'kuto.customers.contacts.list.roles.decisionMaker',
    isMainContact: true,
    statusLabelKey: 'kuto.customers.contacts.list.status.active',
    ownerName: 'นิชา ศรีวงศ์',
    lastActivityKey: 'kuto.customers.contacts.list.activity.days2',
    starRating: 5,
    relatedOpp: 'OPP-2481',
    relatedQuotation: 'QT-1842',
    relatedTicket: 'TK-8542',
    aiInsightKey: 'kuto.customers.contacts.list.ai.scgDecision',
    tabTags: ['active', 'primary', 'decisionMaker']
  },
  {
    id: '2',
    code: 'CON-1038',
    fullName: 'คุณพิมพ์ใจ รุ่งเรือง',
    initials: 'พร',
    avatarBg: 'bg-rose-500',
    companyName: 'Example Hospital',
    companyId: '3',
    jobTitle: 'Purchasing Manager',
    department: 'Purchasing',
    phone: '02-777-8899',
    email: 'pimjai@examplehospital.th',
    roleKey: 'kuto.customers.contacts.list.roles.purchasing',
    isMainContact: false,
    statusLabelKey: 'kuto.customers.contacts.list.status.active',
    ownerName: 'นิชา ศรีวงศ์',
    lastActivityKey: 'kuto.customers.contacts.list.activity.days5',
    starRating: 4,
    relatedOpp: 'OPP-2390',
    aiInsightKey: 'kuto.customers.contacts.list.ai.hospitalPurchasing',
    tabTags: ['active', 'purchasing']
  },
  {
    id: '3',
    code: 'CON-1035',
    fullName: 'คุณวิชัย เทคโนโลยี',
    initials: 'วท',
    avatarBg: 'bg-blue-600',
    companyName: 'Bangkok Technology',
    companyId: '2',
    jobTitle: 'CTO',
    department: 'IT',
    phone: '02-111-4455',
    email: 'wichai@bkktech.co.th',
    roleKey: 'kuto.customers.contacts.list.roles.it',
    isMainContact: true,
    statusLabelKey: 'kuto.customers.contacts.list.status.active',
    ownerName: 'สมศักดิ์ ใจดี',
    lastActivityKey: 'kuto.customers.contacts.list.activity.week1',
    starRating: 4,
    relatedTicket: 'TK-8201',
    aiInsightKey: 'kuto.customers.contacts.list.ai.bkkTechCto',
    tabTags: ['active', 'primary', 'it']
  },
  {
    id: '4',
    code: 'CON-1031',
    fullName: 'คุณนภา สุขสันต์',
    initials: 'นส',
    avatarBg: 'bg-violet-600',
    companyName: 'เอเชีย ฟู้ดส์',
    companyId: '5',
    jobTitle: 'CFO',
    department: 'Finance',
    phone: '02-333-2211',
    email: 'napa@asiafoods.co.th',
    roleKey: 'kuto.customers.contacts.list.roles.influencer',
    isMainContact: true,
    statusLabelKey: 'kuto.customers.contacts.list.status.active',
    ownerName: 'นิชา ศรีวงศ์',
    lastActivityKey: 'kuto.customers.contacts.list.activity.days3',
    starRating: 5,
    relatedOpp: 'OPP-2510',
    relatedQuotation: 'QT-1901',
    aiInsightKey: 'kuto.customers.contacts.list.ai.asiaFoodsCfo',
    tabTags: ['active', 'primary']
  },
  {
    id: '5',
    code: 'CON-1028',
    fullName: 'คุณประเสริฐ มั่นคง',
    initials: 'ปม',
    avatarBg: 'bg-amber-600',
    companyName: 'North Logistics',
    companyId: '6',
    jobTitle: 'Operations Director',
    department: 'Operations',
    phone: '053-221-9988',
    email: 'prasert@northlogistics.co.th',
    roleKey: 'kuto.customers.contacts.list.roles.gatekeeper',
    isMainContact: false,
    statusLabelKey: 'kuto.customers.contacts.list.status.active',
    ownerName: 'สมศักดิ์ ใจดี',
    lastActivityKey: 'kuto.customers.contacts.list.activity.days14',
    starRating: 3,
    aiInsightKey: 'kuto.customers.contacts.list.ai.northLogistics',
    tabTags: ['active', 'noActivity']
  },
  {
    id: '6',
    code: 'CON-1024',
    fullName: 'คุณมานี มีสุข',
    initials: 'มส',
    avatarBg: 'bg-emerald-600',
    companyName: 'Metro Retail Group',
    companyId: '7',
    jobTitle: 'Store Manager',
    department: 'Retail',
    phone: '02-445-6677',
    email: 'manee@metroretail.co.th',
    roleKey: 'kuto.customers.contacts.list.roles.user',
    isMainContact: false,
    statusLabelKey: 'kuto.customers.contacts.list.status.active',
    ownerName: 'นิชา ศรีวงศ์',
    lastActivityKey: 'kuto.customers.contacts.list.activity.days1',
    starRating: 4,
    aiInsightKey: 'kuto.customers.contacts.list.ai.metroRetail',
    tabTags: ['active', 'purchasing']
  },
  {
    id: '7',
    code: 'CON-1019',
    fullName: 'คุณสุรชัย ดีงาม',
    initials: 'สด',
    avatarBg: 'bg-slate-600',
    companyName: 'Pacific Finance',
    companyId: '8',
    jobTitle: 'Compliance Officer',
    department: 'Legal',
    phone: '02-900-1122',
    email: 'surachai@pacificfinance.co.th',
    roleKey: 'kuto.customers.contacts.list.roles.other',
    isMainContact: false,
    statusLabelKey: 'kuto.customers.contacts.list.status.inactive',
    ownerName: 'สมศักดิ์ ใจดี',
    lastActivityKey: 'kuto.customers.contacts.list.activity.months3',
    starRating: 2,
    aiInsightKey: 'kuto.customers.contacts.list.ai.inactive',
    tabTags: ['inactive', 'noActivity']
  },
  {
    id: '8',
    code: 'CON-1015',
    fullName: 'คุณอรทัย วงศ์ดี',
    initials: 'อว',
    avatarBg: 'bg-pink-600',
    companyName: 'Smart Clinic',
    companyId: '9',
    jobTitle: 'IT Manager',
    department: 'IT',
    phone: '02-555-7788',
    email: 'orathai@smartclinic.th',
    roleKey: 'kuto.customers.contacts.list.roles.it',
    isMainContact: true,
    statusLabelKey: 'kuto.customers.contacts.list.status.active',
    ownerName: 'นิชา ศรีวงศ์',
    lastActivityKey: 'kuto.customers.contacts.list.activity.never',
    starRating: 0,
    aiInsightKey: 'kuto.customers.contacts.list.ai.neverContacted',
    tabTags: ['active', 'primary', 'it', 'neverContacted']
  },
  {
    id: '9',
    code: 'CON-1012',
    fullName: 'คุณกิตติ ชัยวัฒน์',
    initials: 'กช',
    avatarBg: 'bg-indigo-600',
    companyName: 'กลุ่มซีเมนต์ไทย',
    companyId: '1',
    jobTitle: 'Procurement Lead',
    department: 'Purchasing',
    phone: '02-586-3344',
    email: 'kitti@scg.com',
    roleKey: 'kuto.customers.contacts.list.roles.purchasing',
    isMainContact: false,
    statusLabelKey: 'kuto.customers.contacts.list.status.active',
    ownerName: 'นิชา ศรีวงศ์',
    lastActivityKey: 'kuto.customers.contacts.list.activity.days7',
    starRating: 4,
    relatedOpp: 'OPP-2481',
    aiInsightKey: 'kuto.customers.contacts.list.ai.scgPurchasing',
    tabTags: ['active', 'purchasing']
  },
  {
    id: '10',
    code: 'CON-1008',
    fullName: 'คุณวราภรณ์ ศรีสุข',
    initials: 'วศ',
    avatarBg: 'bg-cyan-600',
    companyName: 'Bangkok Technology',
    companyId: '2',
    jobTitle: 'Head of Procurement',
    department: 'Purchasing',
    phone: '02-111-4466',
    email: 'waraporn@bkktech.co.th',
    roleKey: 'kuto.customers.contacts.list.roles.decisionMaker',
    isMainContact: false,
    statusLabelKey: 'kuto.customers.contacts.list.status.active',
    ownerName: 'สมศักดิ์ ใจดี',
    lastActivityKey: 'kuto.customers.contacts.list.activity.days2',
    starRating: 5,
    relatedQuotation: 'QT-1755',
    aiInsightKey: 'kuto.customers.contacts.list.ai.bkkTechDm',
    tabTags: ['active', 'decisionMaker', 'purchasing']
  }
]

export const kutoContactStatusTabs = [
  { key: 'all', labelKey: 'kuto.customers.contacts.list.tabs.all', count: 2418 },
  { key: 'active', labelKey: 'kuto.customers.contacts.list.tabs.active', count: 2148 },
  { key: 'inactive', labelKey: 'kuto.customers.contacts.list.tabs.inactive', count: 270 },
  { key: 'primary', labelKey: 'kuto.customers.contacts.list.tabs.primary', count: 842 },
  { key: 'decisionMaker', labelKey: 'kuto.customers.contacts.list.tabs.decisionMaker', count: 318 },
  { key: 'purchasing', labelKey: 'kuto.customers.contacts.list.tabs.purchasing', count: 426 },
  { key: 'it', labelKey: 'kuto.customers.contacts.list.tabs.it', count: 512 },
  { key: 'neverContacted', labelKey: 'kuto.customers.contacts.list.tabs.neverContacted', count: 87 },
  { key: 'noActivity', labelKey: 'kuto.customers.contacts.list.tabs.noActivity', count: 143 }
] as const

export const kutoContactsListSummaryMeta = [
  {
    key: 'total',
    labelKey: 'kuto.customers.contacts.list.summary.total',
    subKey: 'kuto.customers.contacts.list.summary.totalSub',
    value: '2,418',
    trend: '+42',
    accent: '#17A8A3',
    icon: 'i-lucide-users',
    iconBg: 'bg-teal-50 text-teal-600',
    tabKey: 'all' as KutoContactStatusTabKey
  },
  {
    key: 'active',
    labelKey: 'kuto.customers.contacts.list.summary.active',
    subKey: 'kuto.customers.contacts.list.summary.activeSub',
    value: '2,148',
    trend: '88.8%',
    accent: '#10B981',
    icon: 'i-lucide-circle-check',
    iconBg: 'bg-emerald-50 text-emerald-600',
    tabKey: 'active' as KutoContactStatusTabKey
  },
  {
    key: 'primary',
    labelKey: 'kuto.customers.contacts.list.summary.primary',
    subKey: 'kuto.customers.contacts.list.summary.primarySub',
    value: '842',
    accent: '#F59E0B',
    icon: 'i-lucide-star',
    iconBg: 'bg-amber-50 text-amber-600',
    tabKey: 'primary' as KutoContactStatusTabKey
  },
  {
    key: 'decisionMaker',
    labelKey: 'kuto.customers.contacts.list.summary.decisionMaker',
    subKey: 'kuto.customers.contacts.list.summary.decisionMakerSub',
    value: '318',
    accent: '#EF4444',
    icon: 'i-lucide-crown',
    iconBg: 'bg-red-50 text-red-600',
    tabKey: 'decisionMaker' as KutoContactStatusTabKey
  },
  {
    key: 'neverContacted',
    labelKey: 'kuto.customers.contacts.list.summary.neverContacted',
    subKey: 'kuto.customers.contacts.list.summary.neverContactedSub',
    value: '87',
    accent: '#8B5CF6',
    icon: 'i-lucide-phone-off',
    iconBg: 'bg-violet-50 text-violet-600',
    tabKey: 'neverContacted' as KutoContactStatusTabKey
  },
  {
    key: 'noActivity',
    labelKey: 'kuto.customers.contacts.list.summary.noActivity',
    subKey: 'kuto.customers.contacts.list.summary.noActivitySub',
    value: '143',
    accent: '#64748B',
    icon: 'i-lucide-clock',
    iconBg: 'bg-slate-100 text-slate-600',
    tabKey: 'noActivity' as KutoContactStatusTabKey
  }
] as const

export const kutoContactRecentActivities = [
  {
    key: 'call',
    titleKey: 'kuto.customers.contacts.list.recent.call',
    dateKey: 'kuto.customers.contacts.list.activity.days2',
    icon: 'i-lucide-phone',
    color: '#17A8A3'
  },
  {
    key: 'email',
    titleKey: 'kuto.customers.contacts.list.recent.email',
    dateKey: 'kuto.customers.contacts.list.activity.days5',
    icon: 'i-lucide-mail',
    color: '#3B82F6'
  },
  {
    key: 'meeting',
    titleKey: 'kuto.customers.contacts.list.recent.meeting',
    dateKey: 'kuto.customers.contacts.list.activity.week1',
    icon: 'i-lucide-calendar',
    color: '#8B5CF6'
  }
] as const
