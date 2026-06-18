import type { CompanyBillAddress, Lead, Opportunity, OpportunityFormInput, OpportunityProjectDraft, PipelineStage } from '~/types/crm'
import { leadDisplayName } from '~/utils/masterLeads'
import {
  leadToDefaultProjects,
  legacyOpportunityToProjects,
  opportunityProjectsToDrafts,
  projectsToOpportunityPayload,
  validateOpportunityProjects
} from '~/utils/masterOpportunityProjects'
import { isoToDateInput, dateInputToIso, currentMonthDateRange } from '~/utils/masterTasks'

export type OpportunityDateField = 'created' | 'close'

export interface OpportunityDateRangeFilter {
  from: string
  to: string
}

export interface OpportunityFilterOptions {
  stageFilter?: string | null
  search?: string
  dateRange?: OpportunityDateRangeFilter
  dateField?: OpportunityDateField
  /** แปลชื่อ stage สำหรับค้นหา (locale) */
  stageLabel?: (stageName: string | null | undefined) => string
}

export function defaultOpportunityFormInput(): OpportunityFormInput {
  return {
    title: '',
    company_id: null,
    contact_id: null,
    stage_id: null,
    probability: 0,
    close_date: '',
    description: '',
    owner_id: null,
    sales_owner_id: null,
    sales_designer_id: null,
    sales_team_id: null,
    address_bill_to: ''
  }
}

export function leadToOpportunityPrefill(
  lead: Lead,
  defaultStage: PipelineStage | null,
  ownerId: string | null,
  titleSuffix = ''
): OpportunityFormInput {
  const displayName = leadDisplayName(lead)
  const suffix = titleSuffix.trim()
  const title = suffix ? `${displayName} — ${suffix}` : displayName

  return {
    title,
    company_id: lead.company_id,
    contact_id: lead.contact_id,
    stage_id: defaultStage?.id ?? null,
    probability: defaultStage?.probability ?? 0,
    close_date: '',
    description: lead.requirement?.trim() ?? '',
    owner_id: lead.owner_id ?? ownerId,
    sales_owner_id: lead.owner_id,
    sales_designer_id: null,
    sales_team_id: null,
    address_bill_to: ''
  }
}

export { leadToDefaultProjects, opportunityProjectsToDrafts, legacyOpportunityToProjects }

export function opportunityToFormInput(row: Opportunity): OpportunityFormInput {
  return {
    title: row.title,
    company_id: row.company_id,
    contact_id: row.contact_id,
    stage_id: row.stage_id,
    probability: row.probability,
    close_date: isoToDateInput(row.close_date),
    description: row.description?.trim() ?? '',
    owner_id: row.owner_id,
    sales_owner_id: row.sales_owner_id,
    sales_designer_id: row.sales_designer_id,
    sales_team_id: row.sales_team_id,
    address_bill_to: row.address_bill_to?.trim() ?? ''
  }
}

export function stageOptionLabel(
  stage: PipelineStage,
  formatName: (name: string) => string
): string {
  const name = formatName(stage.name?.trim() || '')
  return `${name} (${stage.probability}%)`
}

export function opportunityMatchesDateRange(
  row: Pick<Opportunity, 'created_at' | 'close_date' | 'closed_at'>,
  range: OpportunityDateRangeFilter,
  field: OpportunityDateField
): boolean {
  if (!range.from && !range.to) return true

  let raw: string | null = null
  if (field === 'close') {
    raw = row.close_date ?? row.closed_at
  } else {
    raw = row.created_at
  }

  if (!raw) return false

  const day = raw.slice(0, 10)
  if (range.from && day < range.from) return false
  if (range.to && day > range.to) return false
  return true
}

export function filterOpportunityRows(
  rows: Opportunity[],
  options: OpportunityFilterOptions
): Opportunity[] {
  const search = options.search?.trim().toLowerCase() ?? ''
  const stageFilter = options.stageFilter ?? null
  const dateField = options.dateField ?? 'created'
  const dateRange = options.dateRange ?? currentMonthDateRange()

  return rows.filter((row) => {
    if (stageFilter && row.stage_id !== stageFilter) return false

    if (search) {
      const stageDisplay = options.stageLabel?.(row.stage_name) ?? row.stage_name
      const haystack = [
        row.title,
        row.opportunity_code,
        row.company_name,
        row.lead_code,
        row.owner_name,
        row.stage_name,
        stageDisplay
      ].join(' ').toLowerCase()
      if (!haystack.includes(search)) return false
    }

    if (!opportunityMatchesDateRange(row, dateRange, dateField)) return false

    return true
  })
}

export function sortOpportunityRows(rows: Opportunity[]): Opportunity[] {
  return [...rows].sort((a, b) => {
    const at = a.created_at ?? ''
    const bt = b.created_at ?? ''
    if (at !== bt) return bt.localeCompare(at)
    return (b.opportunity_code ?? '').localeCompare(a.opportunity_code ?? '')
  })
}

export function computeOpportunitySummary(
  rows: Opportunity[],
  wonDateRange: OpportunityDateRangeFilter
) {
  const openRows = rows.filter(row => row.status === 'open')
  const wonRows = rows.filter(
    row => row.status === 'won'
      && opportunityMatchesDateRange(row, wonDateRange, 'close')
  )

  return {
    pipelineValue: openRows.reduce((sum, row) => sum + Number(row.estimated_value ?? 0), 0),
    wonValue: wonRows.reduce((sum, row) => sum + Number(row.estimated_value ?? 0), 0),
    openCount: openRows.length
  }
}

export function validateOpportunityForm(
  form: OpportunityFormInput,
  projects: OpportunityProjectDraft[] = []
): string | null {
  if (!form.title.trim()) return 'titleRequired'
  if (!form.company_id) return 'customerRequired'
  if (!form.stage_id) return 'stageRequired'
  if (!form.owner_id) return 'ownerRequired'

  return validateOpportunityProjects(projects)
}

/** ฟิลด์ที่แก้ได้บน opp (ไม่รวมข้อมูลจากลีด) */
export function formToOpportunityEditablePayload(
  form: OpportunityFormInput,
  projects: OpportunityProjectDraft[] = []
) {
  return {
    stage_id: form.stage_id,
    close_date: dateInputToIso(form.close_date),
    sales_designer_id: form.sales_designer_id,
    sales_team_id: form.sales_team_id,
    address_bill_to: form.address_bill_to.trim(),
    projects: projectsToOpportunityPayload(projects)
  }
}

export interface CompanyBillAddressOption {
  value: string
  label: string
  address: string
}

export function companyBillAddressSelectOptions(
  addresses: CompanyBillAddress[],
  currentText = ''
): CompanyBillAddressOption[] {
  const options = addresses.map(row => ({
    value: row.id,
    label: row.label?.trim()
      ? `${row.label.trim()} — ${row.address.trim()}`
      : row.address.trim(),
    address: row.address.trim()
  }))

  const trimmed = currentText.trim()
  if (trimmed && !options.some(option => option.address === trimmed)) {
    options.unshift({
      value: `legacy:${trimmed}`,
      label: trimmed,
      address: trimmed
    })
  }

  return options
}

export function defaultCompanyBillAddressText(addresses: CompanyBillAddress[]): string {
  const row = addresses.find(address => address.is_default) ?? addresses[0]
  return row?.address.trim() ?? ''
}

export function opportunityAssigneeDisplay(
  row: Pick<Opportunity, 'owner_name' | 'sales_team_name'>,
  emptyLabel: string
): string {
  return row.owner_name?.trim() || row.sales_team_name?.trim() || emptyLabel
}

export function canConvertLead(lead: Pick<Lead, 'status_code'>): boolean {
  const code = lead.status_code?.trim().toUpperCase()
  return code !== 'CONVERTED' && code !== 'CANCELLED' && code !== 'UNQUALIFIED'
}
