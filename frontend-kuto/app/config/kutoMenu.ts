/** Sidebar IA — KUTO-MENU-PAGE-MATRIX.md · Leads: KUTO-LEADS-IA.md · Customers: KUTO-CUSTOMERS-IA.md · Contacts: KUTO-CONTACTS-IA.md */

export interface KutoNavNode {
  key: string
  labelKey: string
  to: string
  icon?: string
  badge?: number
  /** ระดับลึกกว่า 1 (เช่น ตั้งค่า → ข้อมูลหลัก) */
  children?: KutoNavNode[]
}

export interface KutoNavItem extends KutoNavNode {
  icon: string
}

export interface KutoSubOptions {
  icon?: string
  badge?: number
  children?: KutoNavNode[]
}

function sub(
  key: string,
  labelKey: string,
  to: string,
  opts?: number | KutoSubOptions,
  legacyChildren?: KutoNavNode[]
): KutoNavNode {
  if (typeof opts === 'number') {
    return { key, labelKey, to, badge: opts, children: legacyChildren }
  }
  return { key, labelKey, to, ...opts }
}

/** Top-level + dropdown ย่อย — ตรง figma.site */
export const kutoNavItems: KutoNavItem[] = [
  {
    key: 'dashboard',
    labelKey: 'kuto.nav.dashboard',
    icon: 'i-lucide-layout-dashboard',
    to: '/app'
  },
  {
    key: 'leads',
    labelKey: 'kuto.nav.leads',
    icon: 'i-lucide-target',
    to: '/app/leads',
    badge: 12,
    children: [
      sub('inbox', 'kuto.nav.sub.leads.inbox', '/app/leads/inbox', { icon: 'i-lucide-inbox', badge: 12 }),
      sub('list', 'kuto.nav.sub.leads.all', '/app/leads', { icon: 'i-lucide-list' }),
      sub('import', 'kuto.nav.sub.leads.import', '/app/leads/import', { icon: 'i-lucide-upload' })
    ]
  },
  {
    key: 'customers',
    labelKey: 'kuto.nav.customers',
    icon: 'i-lucide-building-2',
    to: '/app/customers',
    children: [
      sub('list', 'kuto.nav.sub.customers.list', '/app/customers', { icon: 'i-lucide-list' }),
      sub('contacts', 'kuto.nav.sub.customers.contacts', '/app/customers/contacts', { icon: 'i-lucide-users' }),
      sub('contactHistory', 'kuto.nav.sub.customers.contactHistory', '/app/customers/contact-history', { icon: 'i-lucide-history' }),
      sub('import', 'kuto.nav.sub.customers.import', '/app/customers/import', { icon: 'i-lucide-upload' })
    ]
  },
  {
    key: 'opportunities',
    labelKey: 'kuto.nav.opportunities',
    icon: 'i-lucide-circle-dollar-sign',
    to: '/app/opportunities',
    children: [
      sub('pipelineKanban', 'kuto.nav.sub.opportunities.pipelineKanban', '/app/opportunities/pipeline'),
      sub('list', 'kuto.nav.sub.opportunities.list', '/app/opportunities'),
      sub('new', 'kuto.nav.sub.opportunities.new', '/app/opportunities/new'),
      sub('mine', 'kuto.nav.sub.opportunities.mine', '/app/opportunities/mine'),
      sub('team', 'kuto.nav.sub.opportunities.team', '/app/opportunities/team'),
      sub('detail', 'kuto.nav.sub.opportunities.detail', '/app/opportunities/detail'),
      sub('forecast', 'kuto.nav.sub.opportunities.forecast', '/app/opportunities/forecast'),
      sub('stale', 'kuto.nav.sub.opportunities.stale', '/app/opportunities/stale'),
      sub('competitors', 'kuto.nav.sub.opportunities.competitors', '/app/opportunities/competitors'),
      sub('winLoss', 'kuto.nav.sub.opportunities.winLoss', '/app/opportunities/win-loss'),
      sub('lostReasons', 'kuto.nav.sub.opportunities.lostReasons', '/app/opportunities/lost-reasons'),
      sub('scoring', 'kuto.nav.sub.opportunities.scoring', '/app/opportunities/scoring'),
      sub('salesStages', 'kuto.nav.sub.opportunities.salesStages', '/app/opportunities/sales-stages')
    ]
  },
  {
    key: 'quotations',
    labelKey: 'kuto.nav.quotations',
    icon: 'i-lucide-file-text',
    to: '/app/quotations',
    children: [
      sub('list', 'kuto.nav.sub.quotations.list', '/app/quotations'),
      sub('create', 'kuto.nav.sub.quotations.create', '/app/quotations/new'),
      sub('approvals', 'kuto.nav.sub.quotations.approvals', '/app/quotations/approvals', 5),
      sub('pricing', 'kuto.nav.sub.quotations.pricing', '/app/quotations/pricing'),
      sub('templates', 'kuto.nav.sub.quotations.templates', '/app/quotations/templates'),
      sub('versions', 'kuto.nav.sub.quotations.versions', '/app/quotations/versions'),
      sub('expired', 'kuto.nav.sub.quotations.expired', '/app/quotations/expired')
    ]
  },
  {
    key: 'contracts',
    labelKey: 'kuto.nav.contracts',
    icon: 'i-lucide-shield-check',
    to: '/app/contracts',
    children: [
      sub('all', 'kuto.nav.sub.contracts.all', '/app/contracts'),
      sub('renewalAlerts', 'kuto.nav.sub.contracts.renewalAlerts', '/app/contracts/renewal-alerts', 26),
      sub('renewalForecast', 'kuto.nav.sub.contracts.renewalForecast', '/app/contracts/renewal-forecast'),
      sub('expiring', 'kuto.nav.sub.contracts.expiring', '/app/contracts/expiring'),
      sub('expired', 'kuto.nav.sub.contracts.expired', '/app/contracts/expired'),
      sub('renewed', 'kuto.nav.sub.contracts.renewed', '/app/contracts/renewed'),
      sub('notRenewed', 'kuto.nav.sub.contracts.notRenewed', '/app/contracts/not-renewed'),
      sub('renewalCalendar', 'kuto.nav.sub.contracts.renewalCalendar', '/app/contracts/renewal-calendar'),
      sub('m365', 'kuto.nav.sub.contracts.m365', '/app/contracts/microsoft-csp'),
      sub('google', 'kuto.nav.sub.contracts.google', '/app/contracts/google-workspace'),
      sub('firewall', 'kuto.nav.sub.contracts.firewall', '/app/contracts/firewall'),
      sub('edr', 'kuto.nav.sub.contracts.edr', '/app/contracts/antivirus-edr'),
      sub('maintenance', 'kuto.nav.sub.contracts.maintenance', '/app/contracts/maintenance'),
      sub('sla', 'kuto.nav.sub.contracts.sla', '/app/contracts/sla'),
      sub('warranty', 'kuto.nav.sub.contracts.warranty', '/app/contracts/warranty')
    ]
  },
  {
    key: 'assets',
    labelKey: 'kuto.nav.assets',
    icon: 'i-lucide-tag',
    to: '/app/assets',
    children: [
      sub('all', 'kuto.nav.sub.assets.all', '/app/assets'),
      sub('installedBase', 'kuto.nav.sub.assets.installedBase', '/app/assets/installed-base'),
      sub('subscriptions', 'kuto.nav.sub.assets.subscriptions', '/app/assets/subscriptions'),
      sub('warranty', 'kuto.nav.sub.assets.warranty', '/app/assets/warranty'),
      sub('byCustomer', 'kuto.nav.sub.assets.byCustomer', '/app/assets/by-customer'),
      sub('import', 'kuto.nav.sub.assets.import', '/app/assets/import'),
      sub('settings', 'kuto.nav.sub.assets.settings', '/app/assets/settings')
    ]
  },
  {
    key: 'tickets',
    labelKey: 'kuto.nav.tickets',
    icon: 'i-lucide-headphones',
    to: '/app/tickets',
    badge: 8,
    children: [
      sub('all', 'kuto.nav.sub.tickets.all', '/app/tickets'),
      sub('create', 'kuto.nav.sub.tickets.create', '/app/tickets/new'),
      sub('mine', 'kuto.nav.sub.tickets.mine', '/app/tickets/mine'),
      sub('team', 'kuto.nav.sub.tickets.team', '/app/tickets/team'),
      sub('kanban', 'kuto.nav.sub.tickets.kanban', '/app/tickets/kanban'),
      sub('sla', 'kuto.nav.sub.tickets.sla', '/app/tickets/sla', 3),
      sub('engineerAssign', 'kuto.nav.sub.tickets.engineerAssign', '/app/tickets/engineer-assignment'),
      sub('serviceReport', 'kuto.nav.sub.tickets.serviceReport', '/app/tickets/service-reports'),
      sub('knowledgeBase', 'kuto.nav.sub.tickets.knowledgeBase', '/app/tickets/knowledge-base')
    ]
  },
  {
    key: 'activities',
    labelKey: 'kuto.nav.activities',
    icon: 'i-lucide-activity',
    to: '/app/activities',
    children: [
      sub('mine', 'kuto.nav.sub.activities.mine', '/app/activities/mine'),
      sub('schedule', 'kuto.nav.sub.activities.schedule', '/app/activities/schedule'),
      sub('calendar', 'kuto.nav.sub.activities.calendar', '/app/activities/calendar'),
      sub('meetings', 'kuto.nav.sub.activities.meetings', '/app/activities/meetings'),
      sub('followUp', 'kuto.nav.sub.activities.followUp', '/app/activities/follow-up')
    ]
  },
  {
    key: 'documents',
    labelKey: 'kuto.nav.documents',
    icon: 'i-lucide-folder-open',
    to: '/app/documents',
    children: [
      sub('all', 'kuto.nav.sub.documents.all', '/app/documents'),
      sub('customer', 'kuto.nav.sub.documents.customer', '/app/documents/customer'),
      sub('quotation', 'kuto.nav.sub.documents.quotation', '/app/documents/quotation'),
      sub('contract', 'kuto.nav.sub.documents.contract', '/app/documents/contract'),
      sub('project', 'kuto.nav.sub.documents.project', '/app/documents/project'),
      sub('service', 'kuto.nav.sub.documents.service', '/app/documents/service'),
      sub('warranty', 'kuto.nav.sub.documents.warranty', '/app/documents/warranty'),
      sub('invoice', 'kuto.nav.sub.documents.invoice', '/app/documents/invoice'),
      sub('templates', 'kuto.nav.sub.documents.templates', '/app/documents/templates'),
      sub('versioning', 'kuto.nav.sub.documents.versioning', '/app/documents/versioning'),
      sub('archived', 'kuto.nav.sub.documents.archived', '/app/documents/archived')
    ]
  },
  {
    key: 'reports',
    labelKey: 'kuto.nav.reports',
    icon: 'i-lucide-bar-chart-3',
    to: '/app/reports'
  },
  {
    key: 'ai',
    labelKey: 'kuto.nav.ai',
    icon: 'i-lucide-bot',
    to: '/app/ai'
  },
  {
    key: 'settings',
    labelKey: 'kuto.nav.settings',
    icon: 'i-lucide-settings',
    to: '/app/settings',
    children: [
      sub('company', 'kuto.nav.sub.settings.company', '/app/settings/company'),
      sub('users', 'kuto.nav.sub.settings.users', '/app/settings/users'),
      sub('roles', 'kuto.nav.sub.settings.roles', '/app/settings/roles'),
      sub('locale', 'kuto.nav.sub.settings.locale', '/app/settings/locale'),
      sub('auditLog', 'kuto.nav.sub.settings.auditLog', '/app/settings/audit-log'),
      sub('teams', 'kuto.nav.sub.settings.teams', '/app/settings/teams'),
      sub('notifications', 'kuto.nav.sub.settings.notifications', '/app/settings/notifications'),
      sub('approvalWorkflow', 'kuto.nav.sub.settings.approvalWorkflow', '/app/settings/approval-workflow'),
      sub('security', 'kuto.nav.sub.settings.security', '/app/settings/security'),
      sub('importExport', 'kuto.nav.sub.settings.importExport', '/app/settings/import-export'),
      sub('api', 'kuto.nav.sub.settings.api', '/app/settings/api-integration'),
      sub('masterData', 'kuto.nav.sub.settings.masterData', '/app/settings/master-data', undefined, [
        sub('customerType', 'kuto.nav.sub.settings.masterData.customerType', '/app/settings/master-data/customer-type'),
        sub('businessType', 'kuto.nav.sub.settings.masterData.businessType', '/app/settings/master-data/business-type'),
        sub('leadSource', 'kuto.nav.sub.settings.masterData.leadSource', '/app/settings/master-data/lead-source'),
        sub('salesStage', 'kuto.nav.sub.settings.masterData.salesStage', '/app/settings/master-data/sales-stage'),
        sub('productCategory', 'kuto.nav.sub.settings.masterData.productCategory', '/app/settings/master-data/product-category'),
        sub('region', 'kuto.nav.sub.settings.masterData.region', '/app/settings/master-data/region'),
        sub('tier', 'kuto.nav.sub.settings.masterData.tier', '/app/settings/master-data/tier'),
        sub('unit', 'kuto.nav.sub.settings.masterData.unit', '/app/settings/master-data/unit'),
        sub('tags', 'kuto.nav.sub.settings.masterData.tags', '/app/settings/master-data/tags'),
        sub('lostReason', 'kuto.nav.sub.settings.masterData.lostReason', '/app/settings/master-data/lost-reason')
      ]),
      sub('aiSettings', 'kuto.nav.sub.settings.aiSettings', '/app/settings/ai'),
      sub('package', 'kuto.nav.sub.settings.package', '/app/settings/package'),
      sub('featureFlags', 'kuto.nav.sub.settings.featureFlags', '/app/settings/features')
    ]
  }
]

/** รวมทุก node (flatten) — ใช้หา label/route จาก path */
export function flattenKutoNav(nodes: KutoNavNode[] = kutoNavItems): KutoNavNode[] {
  const out: KutoNavNode[] = []
  for (const node of nodes) {
    out.push(node)
    if (node.children?.length) {
      out.push(...flattenKutoNav(node.children))
    }
  }
  return out
}

/** parent keys ที่ต้อง expand เมื่ออยู่ route นี้ */
export function kutoExpandedKeysForPath(path: string): string[] {
  const keys: string[] = []

  function nodeMatches(node: KutoNavNode): boolean {
    if (node.to === '/app') {
      if (path === '/app' || path === '/app/') return true
    } else if (path === node.to || path.startsWith(`${node.to}/`)) {
      return true
    }
    return node.children?.some(nodeMatches) ?? false
  }

  function walk(nodes: KutoNavNode[], parentExpandKey?: string) {
    for (const node of nodes) {
      const expandKey = parentExpandKey ? `${parentExpandKey}.${node.key}` : node.key
      if (nodeMatches(node)) {
        if (parentExpandKey) keys.push(parentExpandKey)
        if (node.children?.length) keys.push(expandKey)
      }
      if (node.children?.length) walk(node.children, expandKey)
    }
  }

  walk(kutoNavItems)
  return [...new Set(keys)]
}

export type KutoDashboardTypeId =
  | 'my'
  | 'sales'
  | 'manager'
  | 'executive'
  | 'service'
  | 'renewal'
  | 'admin'
  | 'ai'

export interface KutoDashboardType {
  id: KutoDashboardTypeId
  labelKey: string
  icon: string
}

export const kutoDashboardTypes: KutoDashboardType[] = [
  { id: 'my', labelKey: 'kuto.dashboard.types.my', icon: 'i-lucide-users' },
  { id: 'sales', labelKey: 'kuto.dashboard.types.sales', icon: 'i-lucide-trending-up' },
  { id: 'manager', labelKey: 'kuto.dashboard.types.manager', icon: 'i-lucide-bar-chart-3' },
  { id: 'executive', labelKey: 'kuto.dashboard.types.executive', icon: 'i-lucide-star' },
  { id: 'service', labelKey: 'kuto.dashboard.types.service', icon: 'i-lucide-headphones' },
  { id: 'renewal', labelKey: 'kuto.dashboard.types.renewal', icon: 'i-lucide-shield-check' },
  { id: 'admin', labelKey: 'kuto.dashboard.types.admin', icon: 'i-lucide-settings' },
  { id: 'ai', labelKey: 'kuto.dashboard.types.ai', icon: 'i-lucide-bot' }
]
