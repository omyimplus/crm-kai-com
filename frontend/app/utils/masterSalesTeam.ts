import type { SalesTeam, SalesTeamProfileSummary } from '~/types/crm'
import {
  SALES_TEAM_STATUSES,
  type SalesTeamStatus
} from '~/config/masterSalesTeam'
import { profileDisplayName } from '~/utils/masterSalesTarget'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

export interface MasterSalesTeamFormInput {
  team_code: string
  name: string
  description: string
  team_lead_id: string | null
  member_profile_ids: string[]
  sort_order: number
  status: SalesTeamStatus
  notes: string
}

export function defaultMasterSalesTeamFormInput(): MasterSalesTeamFormInput {
  return {
    team_code: '',
    name: '',
    description: '',
    team_lead_id: null,
    member_profile_ids: [],
    sort_order: 0,
    status: 'active',
    notes: ''
  }
}

function parseStatus(value: string | null | undefined): SalesTeamStatus {
  if (value && (SALES_TEAM_STATUSES as readonly string[]).includes(value)) {
    return value as SalesTeamStatus
  }
  return 'active'
}

export function salesTeamToFormInput(team: SalesTeam): MasterSalesTeamFormInput {
  const memberIds = (team.sales_team_members ?? [])
    .map(row => row.profile_id)
    .filter(Boolean)

  return {
    team_code: team.team_code,
    name: team.name,
    description: team.description ?? '',
    team_lead_id: team.team_lead_id,
    member_profile_ids: memberIds,
    sort_order: team.sort_order ?? 0,
    status: parseStatus(team.status),
    notes: team.notes ?? ''
  }
}

export function formToSalesTeamPayload(form: MasterSalesTeamFormInput) {
  return {
    team_code: form.team_code.trim(),
    name: form.name.trim(),
    description: form.description.trim() || null,
    team_lead_id: form.team_lead_id,
    member_profile_ids: form.member_profile_ids,
    sort_order: form.sort_order ?? 0,
    status: form.status,
    notes: form.notes.trim() || null
  }
}

export type MasterSalesTeamValidationKey =
  | 'codeRequired'
  | 'nameRequired'
  | 'membersRequired'
  | 'sortOrderInvalid'

export function validateMasterSalesTeamForm(
  form: MasterSalesTeamFormInput
): MasterSalesTeamValidationKey | null {
  if (!form.team_code.trim()) return 'codeRequired'
  if (!form.name.trim()) return 'nameRequired'
  if (!form.member_profile_ids.length) return 'membersRequired'
  if (form.sort_order < 0) return 'sortOrderInvalid'
  return null
}

export function salesTeamMemberProfileIds(team: Pick<SalesTeam, 'team_lead_id' | 'sales_team_members'>) {
  const ids = new Set((team.sales_team_members ?? []).map(member => member.profile_id))
  if (team.team_lead_id) ids.add(team.team_lead_id)
  return [...ids]
}

export function salesTeamDisplayLabel(team: Pick<SalesTeam, 'name'>) {
  return team.name
}

export function salesTeamMemberCount(team: Pick<SalesTeam, 'sales_team_members'>) {
  return team.sales_team_members?.length ?? 0
}

export function profileSummaryDisplayName(profile: SalesTeamProfileSummary) {
  return profileDisplayName(profile)
}

export function salesTeamSaveErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.saveFailed'))
  if (message.includes('Duplicate team code')) {
    return t('masterData.salesTeam.validation.duplicateCode')
  }
  if (message.includes('At least one team member required')) {
    return t('masterData.salesTeam.validation.membersRequired')
  }
  if (message.includes('Invalid team member')) {
    return t('masterData.salesTeam.validation.invalidMember')
  }
  return message || t('common.saveFailed')
}

export function salesTeamDeleteErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.deleteFailed'))
  return message || t('common.deleteFailed')
}
