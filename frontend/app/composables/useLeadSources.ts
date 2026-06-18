import type { LeadSource } from '~/types/crm'
import type { MasterLeadSourceFormInput } from '~/utils/masterLeadSource'
import { formToLeadSourcePayload } from '~/utils/masterLeadSource'

export function useLeadSources() {
  const supabase = useSupabaseClient()

  async function list() {
    const { data, error } = await supabase
      .from('lead_sources')
      .select('*')
      .is('deleted_at', null)
      .order('sort_order')
      .order('name')
    if (error) throw error
    return data as LeadSource[]
  }

  async function listDeleted() {
    const { data, error } = await supabase
      .from('lead_sources')
      .select('*')
      .not('deleted_at', 'is', null)
      .order('deleted_at', { ascending: false })
    if (error) throw error
    return data as LeadSource[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('lead_sources')
      .select('*')
      .eq('id', id)
      .is('deleted_at', null)
      .single()
    if (error) throw error
    return data as LeadSource
  }

  async function create(payload: MasterLeadSourceFormInput) {
    const { data: id, error } = await supabase.rpc('create_lead_source', {
      p_payload: formToLeadSourcePayload(payload)
    })
    if (error) throw error
    return get(String(id))
  }

  async function update(id: string, payload: MasterLeadSourceFormInput) {
    const { error } = await supabase.rpc('update_lead_source', {
      p_lead_source_id: id,
      p_payload: formToLeadSourcePayload(payload)
    })
    if (error) throw error
    return get(id)
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_lead_source', {
      p_lead_source_id: id
    })
    if (error) throw error
  }

  async function restore(id: string) {
    const { error } = await supabase.rpc('restore_lead_source', {
      p_lead_source_id: id
    })
    if (error) throw error
  }

  return { list, listDeleted, get, create, update, remove, restore }
}
