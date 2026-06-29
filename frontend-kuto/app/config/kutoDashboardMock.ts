/** Mock data — ตรง figma.site แดชบอร์ดของฉัน (ยังไม่ต่อ DB) */

export interface KutoLiveKpi {
  key: string
  labelKey: string
  value: string
  subKey: string
  icon: string
  accent: string
  iconBg: string
}

export const kutoLiveKpis: KutoLiveKpi[] = [
  {
    key: 'newLeads',
    labelKey: 'kuto.dashboard.live.newLeads',
    value: '0',
    subKey: 'kuto.dashboard.live.newLeadsSub',
    icon: 'i-lucide-users',
    accent: '#17A8A3',
    iconBg: 'bg-teal-50 text-teal-600'
  },
  {
    key: 'pipeline',
    labelKey: 'kuto.dashboard.live.pipeline',
    value: '฿0.0M',
    subKey: 'kuto.dashboard.live.pipelineSub',
    icon: 'i-lucide-circle-dollar-sign',
    accent: '#3B82F6',
    iconBg: 'bg-blue-50 text-blue-600'
  },
  {
    key: 'openTickets',
    labelKey: 'kuto.dashboard.live.openTickets',
    value: '0',
    subKey: 'kuto.dashboard.live.openTicketsSub',
    icon: 'i-lucide-activity',
    accent: '#14B8A6',
    iconBg: 'bg-teal-50 text-teal-500'
  },
  {
    key: 'expiringContracts',
    labelKey: 'kuto.dashboard.live.expiringContracts',
    value: '0',
    subKey: 'kuto.dashboard.live.within90Days',
    icon: 'i-lucide-triangle-alert',
    accent: '#0E8580',
    iconBg: 'bg-teal-50 text-teal-700'
  },
  {
    key: 'totalCustomers',
    labelKey: 'kuto.dashboard.live.totalCustomers',
    value: '0',
    subKey: 'kuto.dashboard.live.totalCustomersSub',
    icon: 'i-lucide-star',
    accent: '#8B5CF6',
    iconBg: 'bg-violet-50 text-violet-600'
  },
  {
    key: 'activitiesToday',
    labelKey: 'kuto.dashboard.live.activitiesToday',
    value: '0',
    subKey: 'kuto.dashboard.live.activitiesTodaySub',
    icon: 'i-lucide-trending-up',
    accent: '#F59E0B',
    iconBg: 'bg-amber-50 text-amber-600'
  }
]

export interface KutoMyKpi {
  key: string
  labelKey: string
  value: string
  icon: string
  iconBg: string
  trend?: string
  trendDown?: boolean
}

export const kutoMyKpis: KutoMyKpi[] = [
  {
    key: 'activitiesToday',
    labelKey: 'kuto.dashboard.myKpi.activitiesToday',
    value: '8',
    icon: 'i-lucide-activity',
    iconBg: 'bg-teal-50 text-teal-600'
  },
  {
    key: 'overdue',
    labelKey: 'kuto.dashboard.myKpi.overdue',
    value: '3',
    icon: 'i-lucide-triangle-alert',
    iconBg: 'bg-red-50 text-red-600',
    trend: '▼ -1',
    trendDown: true
  },
  {
    key: 'leadsFollowUp',
    labelKey: 'kuto.dashboard.myKpi.leadsFollowUp',
    value: '12',
    icon: 'i-lucide-users',
    iconBg: 'bg-blue-50 text-blue-600'
  },
  {
    key: 'openOpps',
    labelKey: 'kuto.dashboard.myKpi.openOpps',
    value: '7',
    icon: 'i-lucide-circle-dollar-sign',
    iconBg: 'bg-emerald-50 text-emerald-600'
  },
  {
    key: 'pendingQuotations',
    labelKey: 'kuto.dashboard.myKpi.pendingQuotations',
    value: '4',
    icon: 'i-lucide-file-text',
    iconBg: 'bg-amber-50 text-amber-600'
  },
  {
    key: 'myTickets',
    labelKey: 'kuto.dashboard.myKpi.myTickets',
    value: '2',
    icon: 'i-lucide-headphones',
    iconBg: 'bg-violet-50 text-violet-600'
  }
]

export interface KutoTodayTask {
  id: string
  icon: string
  iconColor: string
  title: string
  meta: string
  statusKey: string
  statusTone: 'today' | 'overdue'
}

export const kutoTodayTasks: KutoTodayTask[] = [
  {
    id: '1',
    icon: 'i-lucide-phone',
    iconColor: 'text-teal-600 bg-teal-50',
    title: 'kuto.dashboard.tasks.items.renewalScg',
    meta: 'kuto.dashboard.tasks.meta.scg',
    statusKey: 'kuto.dashboard.tasks.status.today',
    statusTone: 'today'
  },
  {
    id: '2',
    icon: 'i-lucide-users',
    iconColor: 'text-blue-600 bg-blue-50',
    title: 'kuto.dashboard.tasks.items.demoCrm',
    meta: 'kuto.dashboard.tasks.meta.asiaFoods',
    statusKey: 'kuto.dashboard.tasks.status.today',
    statusTone: 'today'
  },
  {
    id: '3',
    icon: 'i-lucide-file-text',
    iconColor: 'text-amber-600 bg-amber-50',
    title: 'kuto.dashboard.tasks.items.finalProposal',
    meta: 'kuto.dashboard.tasks.meta.hospital',
    statusKey: 'kuto.dashboard.tasks.status.today',
    statusTone: 'today'
  },
  {
    id: '4',
    icon: 'i-lucide-calendar-check',
    iconColor: 'text-purple-600 bg-purple-50',
    title: 'kuto.dashboard.tasks.items.firewallRenewal',
    meta: 'kuto.dashboard.tasks.meta.bangkokTech',
    statusKey: 'kuto.dashboard.tasks.status.overdue',
    statusTone: 'overdue'
  }
]

export interface KutoMyOpportunity {
  id: string
  name: string
  customer: string
  stageKey: string
  amount: string
  probability: number
}

export const kutoMyOpportunities: KutoMyOpportunity[] = [
  {
    id: '1',
    name: 'Microsoft 365 Renewal 2026',
    customer: 'กลุ่มซิเมนต์ไทย',
    stageKey: 'kuto.dashboard.opps.stage.verbalCommit',
    amount: '฿1.8M',
    probability: 88
  },
  {
    id: '2',
    name: 'Firewall Subscription Upgrade',
    customer: 'Bangkok Technology Co., Ltd.',
    stageKey: 'kuto.dashboard.opps.stage.negotiation',
    amount: '฿850K',
    probability: 65
  },
  {
    id: '3',
    name: 'Server Replacement Project',
    customer: 'Example Hospital',
    stageKey: 'kuto.dashboard.opps.stage.proposal',
    amount: '฿4.2M',
    probability: 52
  }
]

export interface KutoQuickAction {
  key: string
  labelKey: string
  icon: string
}

export const kutoQuickActions: KutoQuickAction[] = [
  { key: 'activity', labelKey: 'kuto.dashboard.quickActions.activity', icon: 'i-lucide-plus' },
  { key: 'lead', labelKey: 'kuto.dashboard.quickActions.lead', icon: 'i-lucide-user-plus' },
  { key: 'opportunity', labelKey: 'kuto.dashboard.quickActions.opportunity', icon: 'i-lucide-circle-dollar-sign' },
  { key: 'quotation', labelKey: 'kuto.dashboard.quickActions.quotation', icon: 'i-lucide-file-text' }
]

export interface KutoAiInsight {
  key: string
  textKey: string
}

export const kutoAiInsights: KutoAiInsight[] = [
  { key: 'renewal', textKey: 'kuto.dashboard.ai.renewalDeal' },
  { key: 'followUp', textKey: 'kuto.dashboard.ai.followUp' }
]
