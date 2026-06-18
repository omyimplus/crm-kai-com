import type { Partner } from '~/types/crm'
import type { MasterPartnerFormInput } from '~/utils/masterPartner'
import { formToPartnerPayload } from '~/utils/masterPartner'

export function usePartners() {
  const supabase = useSupabaseClient()

  async function list() {
    const { data, error } = await supabase
      .from('partners')
      .select('*')
      .is('deleted_at', null)
      .order('sort_order')
      .order('name')
    if (error) throw error
    return data as Partner[]
  }

  async function listDeleted() {
    const { data, error } = await supabase
      .from('partners')
      .select('*')
      .not('deleted_at', 'is', null)
      .order('deleted_at', { ascending: false })
    if (error) throw error
    return data as Partner[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('partners')
      .select('*')
      .eq('id', id)
      .is('deleted_at', null)
      .single()
    if (error) throw error
    return data as Partner
  }

  async function create(payload: MasterPartnerFormInput) {
    const { data: id, error } = await supabase.rpc('create_partner', {
      p_payload: formToPartnerPayload(payload)
    })
    if (error) throw error
    return get(String(id))
  }

  async function update(id: string, payload: MasterPartnerFormInput) {
    const { error } = await supabase.rpc('update_partner', {
      p_partner_id: id,
      p_payload: formToPartnerPayload(payload)
    })
    if (error) throw error
    return get(id)
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_partner', {
      p_partner_id: id
    })
    if (error) throw error
  }

  async function restore(id: string) {
    const { error } = await supabase.rpc('restore_partner', {
      p_partner_id: id
    })
    if (error) throw error
  }

  return { list, listDeleted, get, create, update, remove, restore }
}
