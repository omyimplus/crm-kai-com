import type { Lead, LeadFormInput, ModuleStatus } from '~/types/crm'
import type { LeadPriority, LeadScoreTier, LeadType } from '~/config/masterLeads'
import type { CustomerCompanyAddressDraft, MasterCustomerFormInput } from '~/utils/masterCustomer'
import {
  defaultCompanyAddressText,
  defaultMasterCustomerFormInput
} from '~/utils/masterCustomer'
import {
  CUSTOMER_INDUSTRY_SEGMENTS,
  CUSTOMER_SALES_GRADES,
  CUSTOMER_TYPES
} from '~/config/masterCustomer'
import {
  LEAD_CLOSED_STATUS_CODES,
  LEAD_HOT_SCORE_MIN,
  LEAD_PRIORITIES,
  LEAD_SCORE_MAX,
  LEAD_TYPES,
  LEAD_WARM_SCORE_MIN,
  leadScoreTierThemes
} from '~/config/masterLeads'
import { TASK_PRIORITY_SOLID_COLORS } from '~/config/masterTasks'
import {
  getActiveModuleStatuses,
  isoToDateInput,
  dateInputToIso
} from '~/utils/masterTasks'

export type LeadCustomerMode = 'existing' | 'new'

function parseLeadSlug<T extends string>(
  value: string | null | undefined,
  allowed: readonly string[],
  fallback: T | null
): T | null {
  if (value && allowed.includes(value)) return value as T
  return fallback
}

export function leadSnapshotToCustomerForm(lead: Lead): MasterCustomerFormInput {
  const customerType = parseLeadSlug(lead.customer_type, CUSTOMER_TYPES, 'company') ?? 'company'
  return {
    ...defaultMasterCustomerFormInput(),
    name: lead.company_name?.trim() ?? '',
    customer_type: customerType,
    email: lead.email,
    phone: lead.phone?.trim() ?? '',
    mobile: lead.mobile?.trim() ?? '',
    tax_id: lead.tax_id?.trim() ?? '',
    industry_segment: parseLeadSlug(lead.industry_segment, CUSTOMER_INDUSTRY_SEGMENTS, null),
    sales_grade: parseLeadSlug(lead.sales_grade, CUSTOMER_SALES_GRADES, null)
  }
}

export function leadSnapshotBillAddresses(lead: Lead): CustomerCompanyAddressDraft[] {
  const street = lead.address_street?.trim()
  if (!street) return []
  return [{
    id: `legacy-${lead.id}`,
    label: '',
    address: street,
    is_default: true
  }]
}

export function syncLeadFieldsFromCustomer(
  form: LeadFormInput,
  customer: MasterCustomerFormInput,
  companyId: string,
  billAddresses: CustomerCompanyAddressDraft[] = []
): LeadFormInput {
  const addressText = defaultCompanyAddressText(billAddresses) ?? ''
  const mobile = customer.mobile.trim() || customer.phone.trim()

  return {
    ...form,
    company_id: companyId,
    contact_id: null,
    company_name: customer.name.trim(),
    email: customer.email.trim(),
    phone: customer.phone.trim() || '',
    mobile,
    tax_id: customer.tax_id.trim() || '',
    customer_type: customer.customer_type,
    industry_segment: customer.industry_segment,
    sales_grade: customer.sales_grade,
    address_street: addressText,
    address_sub_district: '',
    address_district: '',
    address_province: '',
    address_postal_code: ''
  }
}

export function validateLeadCustomerMode(
  mode: LeadCustomerMode,
  companyId: string | null
): 'customerRequired' | null {
  if (mode === 'existing' && !companyId) return 'customerRequired'
  return null
}

export function leadFormModuleStatuses(
  statuses: ModuleStatus[],
  currentModuleStatusId?: string | null
): ModuleStatus[] {
  const active = getActiveModuleStatuses(statuses)
  if (!currentModuleStatusId) return active
  const current = statuses.find(row => row.id === currentModuleStatusId)
  if (!current || active.some(row => row.id === current.id)) return active
  return [...active, current].sort(
    (a, b) => a.sort_order - b.sort_order || a.name.localeCompare(b.name, 'th')
  )
}

export function isLeadType(value: string | null | undefined): value is LeadType {
  return Boolean(value && (LEAD_TYPES as readonly string[]).includes(value))
}

export function isLeadPriority(value: string | null | undefined): value is LeadPriority {
  return Boolean(value && (LEAD_PRIORITIES as readonly string[]).includes(value))
}

export function isLeadActive(lead: Pick<Lead, 'status_code'>): boolean {
  const code = lead.status_code?.trim().toUpperCase()
  return Boolean(code && !(LEAD_CLOSED_STATUS_CODES as readonly string[]).includes(code as typeof LEAD_CLOSED_STATUS_CODES[number]))
}

export function leadDisplayName(lead: Pick<Lead, 'full_name' | 'company_name' | 'email'>) {
  return lead.full_name?.trim() || lead.company_name?.trim() || lead.email.trim()
}

/** ชื่อลูกค้าใต้หัวข้อหลัก เมื่อชื่อผู้ติดต่อไม่ใช่ชื่อบริษัท */
export function leadTableCompanySubtitle(
  lead: Pick<Lead, 'full_name' | 'company_name' | 'email'>
): string | null {
  const primary = leadDisplayName(lead)
  const company = lead.company_name?.trim()
  if (company && company !== primary) return company
  return null
}

export function leadTableContactLine(
  lead: Pick<Lead, 'phone' | 'mobile' | 'email'>
): string {
  return lead.phone?.trim() || lead.mobile?.trim() || lead.email?.trim() || ''
}

export type LeadDateField = 'next_action' | 'created'

export interface LeadDateRangeFilter {
  from: string
  to: string
}

export function leadDateKey(
  lead: Pick<Lead, 'next_action_at' | 'created_at'>,
  field: LeadDateField
): string | null {
  const source = field === 'next_action' ? lead.next_action_at : lead.created_at
  if (!source) return null
  return source.slice(0, 10)
}

export function leadMatchesDateRange(
  lead: Pick<Lead, 'next_action_at' | 'created_at'>,
  range: LeadDateRangeFilter,
  field: LeadDateField = 'created'
): boolean {
  const key = leadDateKey(lead, field)
  const from = range.from.trim()
  const to = range.to.trim()
  const hasFilter = Boolean(from || to)

  if (!key) return !hasFilter
  if (from && key < from) return false
  if (to && key > to) return false
  return true
}

export function leadScoreTier(score: number): LeadScoreTier {
  if (score >= LEAD_HOT_SCORE_MIN) return 'hot'
  if (score >= LEAD_WARM_SCORE_MIN) return 'warm'
  return 'cold'
}

const SCORE_RING_RADIUS = 16

export function leadScoreRingMetrics(score: number) {
  const normalized = Math.min(LEAD_SCORE_MAX, Math.max(0, Math.round(score)))
  const circumference = 2 * Math.PI * SCORE_RING_RADIUS
  const progress = normalized / 100
  const tier = leadScoreTier(normalized)
  return {
    score: normalized,
    tier,
    circumference,
    dashOffset: circumference * (1 - progress),
    color: leadScoreTierThemes[tier].ring,
    fill: leadScoreTierThemes[tier].fill
  }
}

/** @deprecated use leadScoreRingMetrics — kept for legacy callers */
export function leadScoreCircleStyle(score: number) {
  const { color } = leadScoreRingMetrics(score)
  return { backgroundColor: color, color: '#ffffff' }
}

export function leadPrioritySolidStyle(priority: LeadPriority) {
  return {
    backgroundColor: TASK_PRIORITY_SOLID_COLORS[priority],
    color: '#ffffff'
  }
}

export function computeLeadSummary(leads: Lead[]) {
  const active = leads.filter(isLeadActive)
  const hot = active.filter(lead => lead.lead_score >= LEAD_HOT_SCORE_MIN)
  const potentialValue = active.reduce((sum, lead) => sum + Number(lead.lead_value ?? 0), 0)
  return {
    activeCount: active.length,
    hotCount: hot.length,
    potentialValue
  }
}

export interface LeadListFilterOptions {
  hotFilter?: boolean
  statusFilter?: string | null
  sourceFilter?: string | null
  dateRange?: LeadDateRangeFilter
  dateField?: LeadDateField
  search?: string
  statusLabel?: (code: string, name?: string | null) => string
}

export function filterLeadRows(leads: Lead[], options: LeadListFilterOptions): Lead[] {
  let rows = leads

  if (options.hotFilter) {
    rows = rows.filter(lead =>
      lead.lead_score >= LEAD_HOT_SCORE_MIN && isLeadActive(lead)
    )
  }

  if (options.statusFilter) {
    rows = rows.filter(lead => lead.status_code === options.statusFilter)
  }

  if (options.sourceFilter) {
    rows = rows.filter(lead => lead.lead_source_id === options.sourceFilter)
  }

  if (options.dateRange) {
    rows = rows.filter(lead =>
      leadMatchesDateRange(lead, options.dateRange!, options.dateField ?? 'created')
    )
  }

  const q = options.search?.trim().toLowerCase()
  if (q) {
    const label = options.statusLabel ?? ((code: string) => code)
    rows = rows.filter((lead) => {
      const haystack = [
        lead.lead_code,
        lead.full_name,
        lead.company_name,
        lead.email,
        lead.phone,
        lead.mobile,
        lead.lead_source_name,
        lead.owner_name,
        lead.tele_sale_name,
        label(lead.status_code, lead.status_name)
      ].filter(Boolean).join(' ').toLowerCase()
      return haystack.includes(q)
    })
  }

  return rows
}

export function sortLeadRows(rows: Lead[]): Lead[] {
  return [...rows].sort((a, b) => {
    const scoreDiff = b.lead_score - a.lead_score
    if (scoreDiff !== 0) return scoreDiff
    return new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime()
  })
}

export function defaultLeadFormInput(): LeadFormInput {
  return {
    full_name: '',
    lead_type: 'end_user',
    owner_id: null,
    tele_sale_id: null,
    company_id: null,
    contact_id: null,
    company_name: '',
    email: '',
    phone: '',
    mobile: '',
    tax_id: '',
    lead_value: '0',
    customer_type: 'company',
    industry_segment: null,
    sales_grade: null,
    lead_source_id: null,
    module_status_id: null,
    priority: 'medium',
    next_action_at: '',
    next_action: '',
    lead_score: 0,
    requirement: '',
    address_street: '',
    address_sub_district: '',
    address_district: '',
    address_province: '',
    address_postal_code: ''
  }
}

export function leadToFormInput(lead: Lead): LeadFormInput {
  return {
    full_name: lead.full_name ?? '',
    lead_type: parseLeadSlug(lead.lead_type, LEAD_TYPES, 'other') ?? 'other',
    owner_id: lead.owner_id,
    tele_sale_id: lead.tele_sale_id,
    company_id: lead.company_id,
    contact_id: lead.contact_id,
    company_name: lead.company_name ?? '',
    email: lead.email,
    phone: lead.phone ?? '',
    mobile: lead.mobile,
    tax_id: lead.tax_id ?? '',
    lead_value: String(lead.lead_value ?? 0),
    customer_type: parseLeadSlug(lead.customer_type, CUSTOMER_TYPES, 'company') ?? 'company',
    industry_segment: lead.industry_segment,
    sales_grade: lead.sales_grade,
    lead_source_id: lead.lead_source_id,
    module_status_id: lead.module_status_id,
    priority: lead.priority,
    next_action_at: isoToDateInput(lead.next_action_at),
    next_action: lead.next_action ?? '',
    lead_score: lead.lead_score ?? 0,
    requirement: lead.requirement ?? '',
    address_street: lead.address_street ?? '',
    address_sub_district: lead.address_sub_district ?? '',
    address_district: lead.address_district ?? '',
    address_province: lead.address_province ?? '',
    address_postal_code: lead.address_postal_code ?? ''
  }
}

export function validateLeadForm(form: LeadFormInput): string | null {
  if (!form.email.trim()) return 'emailRequired'
  if (!form.mobile.trim()) return 'mobileRequired'
  if (!form.module_status_id) return 'statusRequired'
  const tax = form.tax_id.trim()
  if (tax && !/^\d{13}$/.test(tax)) return 'taxIdInvalid'
  if (form.lead_score < 0 || form.lead_score > LEAD_SCORE_MAX) return 'scoreInvalid'
  return null
}

export function formToLeadPayload(form: LeadFormInput) {
  return {
    full_name: form.full_name.trim() || null,
    lead_type: form.lead_type,
    owner_id: form.owner_id,
    tele_sale_id: form.tele_sale_id,
    company_id: form.company_id,
    contact_id: form.contact_id,
    company_name: form.company_name.trim() || null,
    email: form.email.trim(),
    phone: form.phone.trim() || null,
    mobile: form.mobile.trim(),
    tax_id: form.tax_id.trim() || null,
    lead_value: String(form.lead_value ?? '').trim() || '0',
    customer_type: form.customer_type,
    industry_segment: form.industry_segment,
    sales_grade: form.sales_grade,
    lead_source_id: form.lead_source_id,
    module_status_id: form.module_status_id,
    priority: form.priority,
    next_action_at: dateInputToIso(form.next_action_at),
    next_action: form.next_action.trim() || null,
    lead_score: form.lead_score,
    requirement: form.requirement.trim() || null,
    address_street: form.address_street.trim() || null,
    address_sub_district: form.address_sub_district.trim() || null,
    address_district: form.address_district.trim() || null,
    address_province: form.address_province.trim() || null,
    address_postal_code: form.address_postal_code.trim() || null
  }
}
