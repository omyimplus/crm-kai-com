import type { Category, Lead, OpportunityProject, OpportunityProjectDraft } from '~/types/crm'
import {
  OPPORTUNITY_PROJECT_SUB_TYPES,
  OPPORTUNITY_PROJECT_TYPES
} from '~/config/masterOpportunities'
import { productCategoryOptions } from '~/utils/masterProduct'

type SelectOption = { label: string, value: string }

function withExtraOption(options: SelectOption[], current: string): SelectOption[] {
  const trimmed = current.trim()
  if (!trimmed || options.some(option => option.value === trimmed)) {
    return options
  }
  return [{ label: trimmed, value: trimmed }, ...options]
}

export function opportunityProjectTypeSelectOptions(
  t: (key: string) => string,
  current = ''
): SelectOption[] {
  const options: SelectOption[] = [
    { label: t('opportunities.none'), value: '' },
    ...OPPORTUNITY_PROJECT_TYPES.map(value => ({
      label: t(`opportunities.options.projectType.${value}`),
      value
    }))
  ]
  return withExtraOption(options, current)
}

export function opportunityProjectSubTypeSelectOptions(
  t: (key: string) => string,
  current = ''
): SelectOption[] {
  const options: SelectOption[] = [
    { label: t('opportunities.none'), value: '' },
    ...OPPORTUNITY_PROJECT_SUB_TYPES.map(value => ({
      label: t(`opportunities.options.projectSubType.${value}`),
      value
    }))
  ]
  return withExtraOption(options, current)
}

export function opportunityProductGroupSelectOptions(
  t: (key: string) => string,
  categories: Category[],
  current = ''
): SelectOption[] {
  const options: SelectOption[] = [
    { label: t('opportunities.none'), value: '' },
    ...productCategoryOptions(categories)
  ]
  return withExtraOption(options, current)
}

export function defaultOpportunityProjectDraft(): OpportunityProjectDraft {
  return {
    id: crypto.randomUUID(),
    project_name: '',
    project_type: '',
    project_sub_type: '',
    products_group: '',
    estimated_value: '0',
    project_costs: '0'
  }
}

export function leadToDefaultProjects(lead: Lead): OpportunityProjectDraft[] {
  return [{
    ...defaultOpportunityProjectDraft(),
    project_name: lead.company_name?.trim() ?? '',
    estimated_value: String(lead.lead_value ?? 0)
  }]
}

export function opportunityProjectsToDrafts(rows: OpportunityProject[]): OpportunityProjectDraft[] {
  if (!rows.length) return []
  return rows.map(row => ({
    id: row.id,
    project_name: row.project_name?.trim() ?? '',
    project_type: row.project_type?.trim() ?? '',
    project_sub_type: row.project_sub_type?.trim() ?? '',
    products_group: row.products_group?.trim() ?? '',
    estimated_value: String(row.estimated_value ?? 0),
    project_costs: String(row.project_costs ?? 0)
  }))
}

export function legacyOpportunityToProjects(row: {
  project_name?: string | null
  project_type?: string | null
  project_sub_type?: string | null
  products_group?: string | null
  estimated_value?: number | null
  project_costs?: number | null
}): OpportunityProjectDraft[] {
  const hasData = [
    row.project_name,
    row.project_type,
    row.project_sub_type,
    row.products_group
  ].some(value => value?.trim())
    || Number(row.estimated_value ?? 0) > 0
    || Number(row.project_costs ?? 0) > 0

  if (!hasData) return []

  return [{
    id: crypto.randomUUID(),
    project_name: row.project_name?.trim() ?? '',
    project_type: row.project_type?.trim() ?? '',
    project_sub_type: row.project_sub_type?.trim() ?? '',
    products_group: row.products_group?.trim() ?? '',
    estimated_value: String(row.estimated_value ?? 0),
    project_costs: String(row.project_costs ?? 0)
  }]
}

export function sumOpportunityProjectsValue(projects: OpportunityProjectDraft[]): number {
  return projects.reduce((sum, row) => {
    const value = Number(row.estimated_value)
    return sum + (Number.isNaN(value) ? 0 : value)
  }, 0)
}

export function projectsToOpportunityPayload(projects: OpportunityProjectDraft[]) {
  return projects.map(row => ({
    project_name: row.project_name.trim(),
    project_type: row.project_type.trim(),
    project_sub_type: row.project_sub_type.trim(),
    products_group: row.products_group.trim(),
    estimated_value: row.estimated_value,
    project_costs: row.project_costs
  }))
}

export function validateOpportunityProjects(projects: OpportunityProjectDraft[]): string | null {
  for (const row of projects) {
    const value = Number(row.estimated_value)
    if (Number.isNaN(value) || value < 0) return 'valueInvalid'
    const costs = Number(row.project_costs)
    if (Number.isNaN(costs) || costs < 0) return 'costsInvalid'
  }
  return null
}
