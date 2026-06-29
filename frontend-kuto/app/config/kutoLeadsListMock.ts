/** Mock — hub เป้าหมายทั้งหมด `/app/leads` (ยังไม่ต่อ DB) */

import { kutoLeadsInboxRows, type KutoInboxLeadRow } from '~/config/kutoLeadsInboxMock'

export type KutoLeadPipelineStatus =
  | 'newCustomer'
  | 'contacted'
  | 'qualified'
  | 'failed'
  | 'followUp'
  | 'losingInterest'
  | 'converted'

export type KutoLeadListRow = KutoInboxLeadRow & {
  converted?: boolean
  potentialValue: number
  pipelineStatus: KutoLeadPipelineStatus
}

export type KutoLeadViewMode = 'table' | 'kanban'

const extraRows: KutoLeadListRow[] = [
  {
    id: '6',
    code: 'LD-2398',
    company: 'Siam Retail Group',
    contact: 'คุณปิยะ รุ่งเรือง',
    sourceKey: 'kuto.leads.inbox.sources.lineOa',
    productKey: 'kuto.leads.inbox.products.m365',
    score: 71,
    statusKey: 'kuto.leads.list.pipeline.contacted',
    priorityKey: 'kuto.leads.inbox.priority.normal',
    salesName: 'นิชา ศรีวงศ์',
    createdAt: '2026-06-20',
    phone: '081-999-0001',
    email: 'piya@siamretail.co.th',
    budget: '฿320,000',
    potentialValue: 320_000,
    pipelineStatus: 'contacted',
    aiInsightKey: 'kuto.leads.inbox.ai.assignSoon'
  },
  {
    id: '7',
    code: 'LD-2390',
    company: 'Northern Logistics Ltd.',
    contact: 'คุณอรทัย มั่นคง',
    sourceKey: 'kuto.leads.inbox.sources.website',
    productKey: 'kuto.leads.inbox.products.google',
    score: 88,
    statusKey: 'kuto.leads.list.pipeline.qualified',
    priorityKey: 'kuto.leads.inbox.priority.high',
    salesName: 'สมศักดิ์ ใจดี',
    createdAt: '2026-06-18',
    phone: '053-111-222',
    email: 'orathai@northlog.com',
    budget: '฿560,000',
    potentialValue: 560_000,
    pipelineStatus: 'qualified',
    aiInsightKey: 'kuto.leads.inbox.ai.highScoreFollowUp'
  },
  {
    id: '8',
    code: 'LD-2385',
    company: 'Converted Corp.',
    contact: 'คุณสุดา แปลงแล้ว',
    sourceKey: 'kuto.leads.inbox.sources.tender',
    productKey: 'kuto.leads.inbox.products.firewall',
    score: 91,
    statusKey: 'kuto.leads.list.pipeline.converted',
    priorityKey: 'kuto.leads.inbox.priority.high',
    salesName: 'นิชา ศรีวงศ์',
    createdAt: '2026-05-30',
    phone: '02-888-9999',
    email: 'suda@converted.co.th',
    budget: '฿1,100,000',
    potentialValue: 1_100_000,
    converted: true,
    pipelineStatus: 'converted',
    aiInsightKey: 'kuto.leads.inbox.ai.tenderDeadline'
  },
  {
    id: '9',
    code: 'LD-2380',
    company: 'Won Deal Industries',
    contact: 'คุณชัย ชนะดีล',
    sourceKey: 'kuto.leads.inbox.sources.facebook',
    productKey: 'kuto.leads.inbox.products.m365',
    score: 95,
    statusKey: 'kuto.leads.list.pipeline.converted',
    priorityKey: 'kuto.leads.inbox.priority.urgent',
    salesName: 'สมศักดิ์ ใจดี',
    createdAt: '2026-05-12',
    phone: '089-111-2222',
    email: 'chai@wondeal.com',
    budget: '฿780,000',
    potentialValue: 780_000,
    converted: true,
    pipelineStatus: 'converted',
    aiInsightKey: 'kuto.leads.inbox.ai.highScoreFollowUp'
  },
  {
    id: '10',
    code: 'LD-2375',
    company: 'Failed Lead Co.',
    contact: 'คุณมานะ ไม่ผ่าน',
    sourceKey: 'kuto.leads.inbox.sources.marketplace',
    productKey: 'kuto.leads.inbox.products.google',
    score: 22,
    statusKey: 'kuto.leads.list.pipeline.failed',
    priorityKey: 'kuto.leads.inbox.priority.low',
    salesName: 'นิชา ศรีวงศ์',
    createdAt: '2026-05-08',
    phone: '062-000-1111',
    email: 'mana@failed.co.th',
    budget: '฿40,000',
    potentialValue: 40_000,
    pipelineStatus: 'failed',
    aiInsightKey: 'kuto.leads.inbox.ai.lowScoreNurture'
  }
]

function withPipeline(row: KutoInboxLeadRow, pipelineStatus: KutoLeadPipelineStatus): KutoLeadListRow {
  const numeric = Number(row.budget.replace(/[^\d]/g, '')) || 0
  const statusKeyMap: Record<KutoLeadPipelineStatus, string> = {
    newCustomer: 'kuto.leads.list.pipeline.newCustomer',
    contacted: 'kuto.leads.list.pipeline.contacted',
    qualified: 'kuto.leads.list.pipeline.qualified',
    failed: 'kuto.leads.list.pipeline.failed',
    followUp: 'kuto.leads.list.pipeline.followUp',
    losingInterest: 'kuto.leads.list.pipeline.losingInterest',
    converted: 'kuto.leads.list.pipeline.converted'
  }
  return {
    ...row,
    converted: pipelineStatus === 'converted',
    potentialValue: numeric,
    pipelineStatus,
    statusKey: statusKeyMap[pipelineStatus]
  }
}

export const kutoLeadsAllRows: KutoLeadListRow[] = [
  withPipeline(kutoLeadsInboxRows[0]!, 'newCustomer'),
  withPipeline(kutoLeadsInboxRows[1]!, 'contacted'),
  withPipeline(kutoLeadsInboxRows[2]!, 'qualified'),
  withPipeline(kutoLeadsInboxRows[3]!, 'followUp'),
  withPipeline(kutoLeadsInboxRows[4]!, 'losingInterest'),
  ...extraRows
]

/** แท็บสถานะ — ตาม mock figma (ตัวเลขรวม mock) */
export const kutoLeadPipelineTabs = [
  { key: 'all', labelKey: 'kuto.leads.list.pipeline.all', count: 2418 },
  { key: 'newCustomer', labelKey: 'kuto.leads.list.pipeline.newCustomer', count: 184 },
  { key: 'contacted', labelKey: 'kuto.leads.list.pipeline.contacted', count: 342 },
  { key: 'qualified', labelKey: 'kuto.leads.list.pipeline.qualified', count: 642 },
  { key: 'failed', labelKey: 'kuto.leads.list.pipeline.failed', count: 96 },
  { key: 'followUp', labelKey: 'kuto.leads.list.pipeline.followUp', count: 218 },
  { key: 'losingInterest', labelKey: 'kuto.leads.list.pipeline.losingInterest', count: 43 },
  { key: 'converted', labelKey: 'kuto.leads.list.pipeline.converted', count: 318 }
] as const

export type KutoLeadPipelineTabKey = (typeof kutoLeadPipelineTabs)[number]['key']

/** KPI 5 กล่องบน — ตาม mock figma */
export const kutoLeadsListSummaryMeta = [
  {
    key: 'total' as const,
    labelKey: 'kuto.leads.list.summary.total',
    subKey: 'kuto.leads.list.summary.totalSub',
    value: '2,418',
    accent: '#17A8A3',
    icon: 'i-lucide-users',
    iconBg: 'bg-teal-50 text-teal-600',
    tabKey: 'all' as KutoLeadPipelineTabKey
  },
  {
    key: 'newCustomer' as const,
    labelKey: 'kuto.leads.list.summary.newCustomer',
    subKey: 'kuto.leads.list.summary.newCustomerSub',
    value: '184',
    trend: '+12%',
    accent: '#3B82F6',
    icon: 'i-lucide-user-plus',
    iconBg: 'bg-blue-50 text-blue-600',
    tabKey: 'newCustomer' as KutoLeadPipelineTabKey
  },
  {
    key: 'qualified' as const,
    labelKey: 'kuto.leads.list.summary.qualified',
    subKey: 'kuto.leads.list.summary.qualifiedSub',
    value: '642',
    accent: '#8B5CF6',
    icon: 'i-lucide-badge-check',
    iconBg: 'bg-violet-50 text-violet-600',
    tabKey: 'qualified' as KutoLeadPipelineTabKey
  },
  {
    key: 'converted' as const,
    labelKey: 'kuto.leads.list.summary.converted',
    subKey: 'kuto.leads.list.summary.convertedSub',
    value: '318',
    trend: '+31',
    accent: '#14B8A6',
    icon: 'i-lucide-trending-up',
    iconBg: 'bg-teal-50 text-teal-600',
    tabKey: 'converted' as KutoLeadPipelineTabKey
  },
  {
    key: 'failed' as const,
    labelKey: 'kuto.leads.list.summary.failed',
    subKey: 'kuto.leads.list.summary.failedSub',
    value: '96',
    accent: '#EF4444',
    icon: 'i-lucide-x-circle',
    iconBg: 'bg-red-50 text-red-600',
    tabKey: 'failed' as KutoLeadPipelineTabKey
  }
] as const

export const kutoLeadKanbanColumns = [
  { key: 'newCustomer', labelKey: 'kuto.leads.list.pipeline.newCustomer', pipelineStatus: 'newCustomer' as const },
  { key: 'contacted', labelKey: 'kuto.leads.list.pipeline.contacted', pipelineStatus: 'contacted' as const },
  { key: 'qualified', labelKey: 'kuto.leads.list.pipeline.qualified', pipelineStatus: 'qualified' as const }
] as const

export function kutoLeadIsInbox(row: KutoLeadListRow): boolean {
  return !row.converted && row.salesName === null
}

export function kutoFormatPotentialValue(value: number, locale: string): string {
  return new Intl.NumberFormat(locale === 'th' ? 'th-TH' : 'en-US', {
    style: 'currency',
    currency: 'THB',
    maximumFractionDigits: 0
  }).format(value)
}
