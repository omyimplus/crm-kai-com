import type { Opportunity, OpportunityFormInput, OpportunityProject, OpportunityProjectDraft } from '~/types/crm'
import { formToOpportunityEditablePayload } from '~/utils/masterOpportunities'

export function useOpportunities() {
  const supabase = useSupabaseClient()

  async function list(stageId?: string | null) {
    const { data, error } = await supabase.rpc('list_opportunities', {
      p_stage_id: stageId ?? null
    })
    if (error) throw error
    return (data ?? []) as Opportunity[]
  }

  async function listProjects(opportunityId: string) {
    const { data, error } = await supabase.rpc('list_opportunity_projects', {
      p_opportunity_id: opportunityId
    })
    if (error) throw error
    return (data ?? []) as OpportunityProject[]
  }

  async function getByLeadId(leadId: string) {
    const { data, error } = await supabase.rpc('get_opportunity_by_lead', {
      p_lead_id: leadId
    })
    if (error) throw error
    return data ? String(data) : null
  }

  async function createFromLead(
    leadId: string,
    form: OpportunityFormInput,
    projects: OpportunityProjectDraft[] = []
  ) {
    const { data: id, error } = await supabase.rpc('create_opportunity_from_lead', {
      p_lead_id: leadId,
      p_payload: formToOpportunityEditablePayload(form, projects)
    })
    if (error) throw error
    const rows = await list()
    const created = rows.find(row => row.id === String(id))
    if (!created) throw new Error('Opportunity not found after create')
    return created
  }

  async function update(
    id: string,
    form: OpportunityFormInput,
    projects: OpportunityProjectDraft[] = []
  ) {
    const { error } = await supabase.rpc('update_opportunity', {
      p_opportunity_id: id,
      p_payload: formToOpportunityEditablePayload(form, projects)
    })
    if (error) throw error
    const rows = await list()
    const updated = rows.find(row => row.id === id)
    if (!updated) throw new Error('Opportunity not found after update')
    return updated
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_opportunity', {
      p_opportunity_id: id
    })
    if (error) throw error
  }

  async function ensureDefaults() {
    const { error } = await supabase.rpc('ensure_opportunity_module_defaults')
    if (error) throw error
  }

  return { list, listProjects, getByLeadId, createFromLead, update, remove, ensureDefaults }
}
