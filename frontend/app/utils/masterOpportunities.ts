import type { Lead, Opportunity, OpportunityFormInput, OpportunityLineItemDraft, PipelineStage } from '~/types/crm'
import { leadDisplayName } from '~/utils/masterLeads'
import {
  lineItemsToPayload,
  validateOpportunityLineItems
} from '~/utils/masterOpportunityLineItems'
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
    sales_team_id: null
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
    sales_team_id: null
  }
}

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
    sales_team_id: row.sales_team_id
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
  lineItems: OpportunityLineItemDraft[] = []
): string | null {
  if (!form.title.trim()) return 'titleRequired'
  if (!form.company_id) return 'customerRequired'
  if (!form.stage_id) return 'stageRequired'
  if (!form.owner_id) return 'ownerRequired'

  return validateOpportunityLineItems(lineItems)
}

/** ฟิลด์ที่แก้ได้บน opp ที่มาจากลีด */
export function formToOpportunityLeadUpdatePayload(
  form: OpportunityFormInput,
  lineItems: OpportunityLineItemDraft[] = []
) {
  return {
    stage_id: form.stage_id,
    close_date: dateInputToIso(form.close_date),
    sales_designer_id: form.sales_designer_id,
    sales_team_id: form.sales_team_id,
    line_items: lineItemsToPayload(lineItems)
  }
}

/** ฟิลด์ครบสำหรับสร้าง/แก้ opp ที่ไม่มีลีดต้นทาง */
export function formToOpportunityStandalonePayload(
  form: OpportunityFormInput,
  lineItems: OpportunityLineItemDraft[] = []
) {
  return {
    title: form.title.trim(),
    company_id: form.company_id,
    contact_id: form.contact_id,
    stage_id: form.stage_id,
    close_date: dateInputToIso(form.close_date),
    description: form.description.trim(),
    owner_id: form.owner_id,
    sales_owner_id: form.sales_owner_id,
    sales_designer_id: form.sales_designer_id,
    sales_team_id: form.sales_team_id,
    line_items: lineItemsToPayload(lineItems)
  }
}

/** @deprecated use formToOpportunityLeadUpdatePayload */
export function formToOpportunityEditablePayload(
  form: OpportunityFormInput,
  lineItems: OpportunityLineItemDraft[] = []
) {
  return formToOpportunityLeadUpdatePayload(form, lineItems)
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
