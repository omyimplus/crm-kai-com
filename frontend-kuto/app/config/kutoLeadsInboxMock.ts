/** Mock — กล่องรับเป้าหมาย ตรง figma.site (ยังไม่ต่อ DB) */

export interface KutoInboxSummaryCard {
  key: string
  labelKey: string
  value: string
  subKey?: string
  trend?: string
  trendDown?: boolean
  accent: string
  icon: string
  iconBg: string
}

export interface KutoInboxFilterChip {
  key: string
  labelKey: string
  count?: number
}

export interface KutoInboxLeadRow {
  id: string
  code: string
  company: string
  contact: string
  sourceKey: string
  productKey: string
  score: number
  statusKey: string
  priorityKey: string
  salesName: string | null
  createdAt: string
  phone: string
  email: string
  budget: string
  positionKey?: string
  aiInsightKey: string
  actionKey?: string
}

export const kutoLeadsInboxSummary: KutoInboxSummaryCard[] = [
  {
    key: 'total',
    labelKey: 'kuto.leads.inbox.summary.total',
    value: '48',
    trend: '+12%',
    accent: '#17A8A3',
    icon: 'i-lucide-users',
    iconBg: 'bg-teal-50 text-teal-600'
  },
  {
    key: 'newToday',
    labelKey: 'kuto.leads.inbox.summary.newToday',
    value: '17',
    subKey: 'kuto.leads.inbox.summary.newTodaySub',
    accent: '#3B82F6',
    icon: 'i-lucide-inbox',
    iconBg: 'bg-blue-50 text-blue-600'
  },
  {
    key: 'highScore',
    labelKey: 'kuto.leads.inbox.summary.highScore',
    value: '12',
    accent: '#8B5CF6',
    icon: 'i-lucide-gauge',
    iconBg: 'bg-violet-50 text-violet-600'
  },
  {
    key: 'contacted',
    labelKey: 'kuto.leads.inbox.summary.contacted',
    value: '23',
    accent: '#14B8A6',
    icon: 'i-lucide-phone',
    iconBg: 'bg-teal-50 text-teal-500'
  },
  {
    key: 'website',
    labelKey: 'kuto.leads.inbox.summary.website',
    value: '31',
    trend: '+8',
    accent: '#0E8580',
    icon: 'i-lucide-globe',
    iconBg: 'bg-teal-50 text-teal-700'
  },
  {
    key: 'lineOa',
    labelKey: 'kuto.leads.inbox.summary.lineOa',
    value: '18',
    trend: '+2',
    accent: '#22C55E',
    icon: 'i-lucide-message-circle',
    iconBg: 'bg-green-50 text-green-600'
  }
]

export const kutoLeadsInboxChips: KutoInboxFilterChip[] = [
  { key: 'newToday', labelKey: 'kuto.leads.inbox.chips.newToday', count: 12 },
  { key: 'pendingReview', labelKey: 'kuto.leads.inbox.chips.pendingReview', count: 8 },
  { key: 'unassigned', labelKey: 'kuto.leads.inbox.chips.unassigned', count: 7 },
  { key: 'highScore', labelKey: 'kuto.leads.inbox.chips.highScore', count: 5 },
  { key: 'notContacted', labelKey: 'kuto.leads.inbox.chips.notContacted', count: 9 },
  { key: 'website', labelKey: 'kuto.leads.inbox.chips.website', count: 31 },
  { key: 'lineOa', labelKey: 'kuto.leads.inbox.chips.lineOa', count: 18 },
  { key: 'facebook', labelKey: 'kuto.leads.inbox.chips.facebook', count: 11 },
  { key: 'marketplace', labelKey: 'kuto.leads.inbox.chips.marketplace', count: 6 },
  { key: 'tender', labelKey: 'kuto.leads.inbox.chips.tender', count: 14 }
]

export const kutoLeadsInboxRows: KutoInboxLeadRow[] = [
  {
    id: '1',
    code: 'LD-2401',
    company: 'บริษัท เอเชีย ฟู้ดส์ จำกัด',
    contact: 'คุณสมชาย วงศ์สุวรรณ',
    sourceKey: 'kuto.leads.inbox.sources.website',
    productKey: 'kuto.leads.inbox.products.m365',
    score: 92,
    statusKey: 'kuto.leads.inbox.status.new',
    priorityKey: 'kuto.leads.inbox.priority.urgent',
    salesName: null,
    createdAt: '2026-06-25',
    phone: '081-234-5678',
    email: 'somchai@asiafoods.co.th',
    budget: '฿450,000',
    aiInsightKey: 'kuto.leads.inbox.ai.highScoreFollowUp'
  },
  {
    id: '2',
    code: 'LD-2402',
    company: 'Example Hospital',
    contact: 'คุณพิมพ์ใจ รักษ์ดี',
    sourceKey: 'kuto.leads.inbox.sources.lineOa',
    productKey: 'kuto.leads.inbox.products.firewall',
    score: 78,
    statusKey: 'kuto.leads.inbox.status.pending',
    priorityKey: 'kuto.leads.inbox.priority.high',
    salesName: 'นิชา ศรีวงศ์',
    createdAt: '2026-06-24',
    phone: '02-111-2222',
    email: 'pimjai@examplehospital.com',
    budget: '฿1,200,000',
    aiInsightKey: 'kuto.leads.inbox.ai.hospitalDemo'
  },
  {
    id: '3',
    code: 'LD-2403',
    company: 'Bangkok Technology Co., Ltd.',
    contact: 'คุณเดวิด เฉิน',
    positionKey: 'kuto.leads.inbox.positions.manager',
    sourceKey: 'kuto.leads.inbox.sources.tender',
    productKey: 'kuto.leads.inbox.products.firewall',
    score: 84,
    statusKey: 'kuto.leads.inbox.status.review',
    priorityKey: 'kuto.leads.inbox.priority.high',
    salesName: null,
    createdAt: '2026-06-24',
    phone: '02-555-1234',
    email: 'david.chen@bkktech.com',
    budget: '฿85,000',
    aiInsightKey: 'kuto.leads.inbox.ai.bkkTechUrgent',
    actionKey: 'kuto.leads.inbox.actions.sendSample'
  },
  {
    id: '4',
    code: 'LD-2404',
    company: 'กลุ่มซิเมนต์ไทย',
    contact: 'คุณอนุชา บุญเรือง',
    sourceKey: 'kuto.leads.inbox.sources.tender',
    productKey: 'kuto.leads.inbox.products.maintenance',
    score: 88,
    statusKey: 'kuto.leads.inbox.status.review',
    priorityKey: 'kuto.leads.inbox.priority.high',
    salesName: 'สมศักดิ์ ใจดี',
    createdAt: '2026-06-23',
    phone: '02-333-4444',
    email: 'anucha@scg.com',
    budget: '฿3,500,000',
    aiInsightKey: 'kuto.leads.inbox.ai.tenderDeadline'
  },
  {
    id: '5',
    code: 'LD-2405',
    company: 'Marketplace Seller Co.',
    contact: 'คุณมานี มีสุข',
    sourceKey: 'kuto.leads.inbox.sources.marketplace',
    productKey: 'kuto.leads.inbox.products.google',
    score: 41,
    statusKey: 'kuto.leads.inbox.status.new',
    priorityKey: 'kuto.leads.inbox.priority.low',
    salesName: null,
    createdAt: '2026-06-23',
    phone: '062-555-1234',
    email: 'manee@marketplace.co.th',
    budget: '฿95,000',
    aiInsightKey: 'kuto.leads.inbox.ai.lowScoreNurture'
  }
]

export const kutoInboxChannelBars = [
  { key: 'website', labelKey: 'kuto.leads.inbox.channels.website', value: 93, color: '#17A8A3' },
  { key: 'lineOa', labelKey: 'kuto.leads.inbox.channels.lineOa', value: 58, color: '#22C55E' },
  { key: 'phone', labelKey: 'kuto.leads.inbox.channels.phone', value: 54, color: '#3B82F6' },
  { key: 'facebook', labelKey: 'kuto.leads.inbox.channels.facebook', value: 13, color: '#6366F1' },
  { key: 'marketplace', labelKey: 'kuto.leads.inbox.channels.marketplace', value: 5, color: '#F59E0B' }
] as const

export function kutoLeadScoreColor(score: number): string {
  if (score >= 80) return '#17A8A3'
  if (score >= 40) return '#F59E0B'
  return '#EF4444'
}
