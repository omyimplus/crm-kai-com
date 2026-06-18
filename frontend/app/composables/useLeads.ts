import type { Lead, LeadFormInput } from '~/types/crm'
import { formToLeadPayload } from '~/utils/masterLeads'

export function useLeads() {
  const supabase = useSupabaseClient()

  async function list(statusCode?: string | null, leadSourceId?: string | null) {
    const { data, error } = await supabase.rpc('list_leads', {
      p_status_code: statusCode ?? null,
      p_lead_source_id: leadSourceId ?? null
    })
    if (error) throw error
    return (data ?? []) as Lead[]
  }

  async function create(form: LeadFormInput) {
    const { data: id, error } = await supabase.rpc('create_lead', {
      p_payload: formToLeadPayload(form)
    })
    if (error) throw error
    const rows = await list()
    const created = rows.find(row => row.id === String(id))
    if (!created) throw new Error('Lead not found after create')
    return created
  }

  async function update(id: string, form: LeadFormInput) {
    const { error } = await supabase.rpc('update_lead', {
      p_lead_id: id,
      p_payload: formToLeadPayload(form)
    })
    if (error) throw error
    const rows = await list()
    const updated = rows.find(row => row.id === id)
    if (!updated) throw new Error('Lead not found after update')
    return updated
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_lead', {
      p_lead_id: id
    })
    if (error) throw error
  }

  async function ensureDefaults() {
    const { error } = await supabase.rpc('ensure_lead_module_defaults')
    if (error) throw error
  }

  return { list, create, update, remove, ensureDefaults }
}
