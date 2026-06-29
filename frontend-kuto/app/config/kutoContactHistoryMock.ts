/** Mock — ประวัติการติดต่อ `/app/customers/contact-history` (ตาม figma.site) */

export type KutoContactHistoryTabKey =
  | 'all'
  | 'call'
  | 'email'
  | 'meeting'
  | 'onlineMeeting'
  | 'line'
  | 'followUp'
  | 'upcoming'
  | 'overdue'
  | 'completed'

export type KutoContactHistoryTypeKey = Exclude<
  KutoContactHistoryTabKey,
  'all' | 'upcoming' | 'overdue' | 'completed'
>

export type KutoContactHistoryStatusKey = 'completed' | 'upcoming' | 'overdue'

export interface KutoContactHistoryRow {
  id: string
  titleKey: string
  typeKey: KutoContactHistoryTypeKey
  statusKey: KutoContactHistoryStatusKey
  contactName: string
  companyName: string
  companyId: string
  dateLabelKey: string
  timeLabel: string
  ownerName: string
  relatedOpp?: string
  relatedTicket?: string
  relatedQuotation?: string
  dateGroupKey: string
  tabTags: KutoContactHistoryTabKey[]
  icon: string
}

export const kutoContactHistoryTabs = [
  { key: 'all', labelKey: 'kuto.customers.contactHistory.tabs.all', count: undefined },
  { key: 'call', labelKey: 'kuto.customers.contactHistory.tabs.call', count: 248 },
  { key: 'email', labelKey: 'kuto.customers.contactHistory.tabs.email', count: 312 },
  { key: 'meeting', labelKey: 'kuto.customers.contactHistory.tabs.meeting', count: 86 },
  { key: 'onlineMeeting', labelKey: 'kuto.customers.contactHistory.tabs.onlineMeeting', count: 64 },
  { key: 'line', labelKey: 'kuto.customers.contactHistory.tabs.line', count: 142 },
  { key: 'followUp', labelKey: 'kuto.customers.contactHistory.tabs.followUp', count: 184 },
  { key: 'upcoming', labelKey: 'kuto.customers.contactHistory.tabs.upcoming', count: 38 },
  { key: 'overdue', labelKey: 'kuto.customers.contactHistory.tabs.overdue', count: 12 },
  { key: 'completed', labelKey: 'kuto.customers.contactHistory.tabs.completed', count: 842 }
] as const

export const kutoContactHistoryRows: KutoContactHistoryRow[] = [
  {
    id: '1',
    titleKey: 'kuto.customers.contactHistory.items.renewalCall',
    typeKey: 'call',
    statusKey: 'completed',
    contactName: 'คุณสมชาย วงศ์ไทย',
    companyName: 'กลุ่มซีเมนต์ไทย',
    companyId: '1',
    dateLabelKey: 'kuto.customers.contactHistory.dates.today',
    timeLabel: '10:30',
    ownerName: 'นิชา ศรีวงศ์',
    relatedOpp: 'OPP-2481',
    dateGroupKey: 'kuto.customers.contactHistory.groups.today',
    tabTags: ['call', 'completed'],
    icon: 'i-lucide-phone'
  },
  {
    id: '2',
    titleKey: 'kuto.customers.contactHistory.items.firewallEmail',
    typeKey: 'email',
    statusKey: 'completed',
    contactName: 'คุณวิชัย เทคโนโลยี',
    companyName: 'Bangkok Technology',
    companyId: '2',
    dateLabelKey: 'kuto.customers.contactHistory.dates.yesterday',
    timeLabel: '14:15',
    ownerName: 'สมศักดิ์ ใจดี',
    relatedOpp: 'OPP-2390',
    dateGroupKey: 'kuto.customers.contactHistory.groups.yesterday',
    tabTags: ['email', 'completed'],
    icon: 'i-lucide-mail'
  },
  {
    id: '3',
    titleKey: 'kuto.customers.contactHistory.items.itMeeting',
    typeKey: 'meeting',
    statusKey: 'completed',
    contactName: 'คุณนภา สุขสันต์',
    companyName: 'เอเชีย ฟู้ดส์',
    companyId: '5',
    dateLabelKey: 'kuto.customers.contactHistory.dates.jun19',
    timeLabel: '11:00',
    ownerName: 'นิชา ศรีวงศ์',
    dateGroupKey: 'kuto.customers.contactHistory.groups.jun19',
    tabTags: ['meeting', 'completed'],
    icon: 'i-lucide-users'
  },
  {
    id: '4',
    titleKey: 'kuto.customers.contactHistory.items.lineDemo',
    typeKey: 'line',
    statusKey: 'completed',
    contactName: 'คุณมานี มีสุข',
    companyName: 'Metro Retail Group',
    companyId: '7',
    dateLabelKey: 'kuto.customers.contactHistory.dates.jun18',
    timeLabel: '16:45',
    ownerName: 'นิชา ศรีวงศ์',
    dateGroupKey: 'kuto.customers.contactHistory.groups.jun18',
    tabTags: ['line', 'completed'],
    icon: 'i-lucide-message-circle'
  },
  {
    id: '5',
    titleKey: 'kuto.customers.contactHistory.items.contractReview',
    typeKey: 'onlineMeeting',
    statusKey: 'upcoming',
    contactName: 'คุณพิมพ์ใจ รุ่งเรือง',
    companyName: 'Example Hospital',
    companyId: '3',
    dateLabelKey: 'kuto.customers.contactHistory.dates.jun25',
    timeLabel: '15:00',
    ownerName: 'นิชา ศรีวงศ์',
    relatedOpp: 'OPP-2510',
    dateGroupKey: 'kuto.customers.contactHistory.groups.upcoming',
    tabTags: ['onlineMeeting', 'upcoming'],
    icon: 'i-lucide-video'
  },
  {
    id: '6',
    titleKey: 'kuto.customers.contactHistory.items.overdueFollowUp',
    typeKey: 'followUp',
    statusKey: 'overdue',
    contactName: 'คุณประเสริฐ มั่นคง',
    companyName: 'North Logistics',
    companyId: '6',
    dateLabelKey: 'kuto.customers.contactHistory.dates.jun7',
    timeLabel: '09:00',
    ownerName: 'สมศักดิ์ ใจดี',
    relatedTicket: 'TK-8942',
    dateGroupKey: 'kuto.customers.contactHistory.groups.jun7',
    tabTags: ['followUp', 'overdue'],
    icon: 'i-lucide-clock-alert'
  },
  {
    id: '7',
    titleKey: 'kuto.customers.contactHistory.items.m365Call',
    typeKey: 'call',
    statusKey: 'completed',
    contactName: 'คุณกิตติ ชัยวัฒน์',
    companyName: 'กลุ่มซีเมนต์ไทย',
    companyId: '1',
    dateLabelKey: 'kuto.customers.contactHistory.dates.jun17',
    timeLabel: '13:30',
    ownerName: 'นิชา ศรีวงศ์',
    relatedOpp: 'OPP-2481',
    dateGroupKey: 'kuto.customers.contactHistory.groups.jun17',
    tabTags: ['call', 'completed'],
    icon: 'i-lucide-phone'
  },
  {
    id: '8',
    titleKey: 'kuto.customers.contactHistory.items.proposalEmail',
    typeKey: 'email',
    statusKey: 'completed',
    contactName: 'คุณวราภรณ์ ศรีสุข',
    companyName: 'Bangkok Technology',
    companyId: '2',
    dateLabelKey: 'kuto.customers.contactHistory.dates.jun16',
    timeLabel: '10:00',
    ownerName: 'สมศักดิ์ ใจดี',
    relatedQuotation: 'QT-1755',
    dateGroupKey: 'kuto.customers.contactHistory.groups.jun16',
    tabTags: ['email', 'completed'],
    icon: 'i-lucide-mail'
  },
  {
    id: '9',
    titleKey: 'kuto.customers.contactHistory.items.demoMeeting',
    typeKey: 'meeting',
    statusKey: 'upcoming',
    contactName: 'คุณอรทัย วงศ์ดี',
    companyName: 'Smart Clinic',
    companyId: '9',
    dateLabelKey: 'kuto.customers.contactHistory.dates.jun26',
    timeLabel: '14:00',
    ownerName: 'นิชา ศรีวงศ์',
    dateGroupKey: 'kuto.customers.contactHistory.groups.upcoming',
    tabTags: ['meeting', 'upcoming'],
    icon: 'i-lucide-users'
  },
  {
    id: '10',
    titleKey: 'kuto.customers.contactHistory.items.lineFollowUp',
    typeKey: 'line',
    statusKey: 'completed',
    contactName: 'คุณสุรชัย ดีงาม',
    companyName: 'Pacific Finance',
    companyId: '8',
    dateLabelKey: 'kuto.customers.contactHistory.dates.jun15',
    timeLabel: '11:20',
    ownerName: 'สมศักดิ์ ใจดี',
    dateGroupKey: 'kuto.customers.contactHistory.groups.jun15',
    tabTags: ['line', 'completed'],
    icon: 'i-lucide-message-circle'
  }
]
