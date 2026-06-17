import type { Contact } from '~/types/crm'
import type { MasterContactFormInput } from '~/utils/masterContact'
import { formToContactPayload } from '~/utils/masterContact'

export function useContacts() {
  const supabase = useSupabaseClient()

  async function list() {
    const { data, error } = await supabase
      .from('contacts')
      .select('*, companies(name)')
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
    if (error) throw error
    return data as Contact[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('contacts')
      .select('*, companies(name)')
      .eq('id', id)
      .is('deleted_at', null)
      .single()
    if (error) throw error
    return data as Contact
  }

  async function create(payload: MasterContactFormInput) {
    const { data: id, error } = await supabase.rpc('create_contact', {
      p_payload: formToContactPayload(payload)
    })
    if (error) throw error
    return get(String(id))
  }

  async function update(id: string, payload: MasterContactFormInput) {
    const { error } = await supabase.rpc('update_contact', {
      p_contact_id: id,
      p_payload: formToContactPayload(payload)
    })
    if (error) throw error
    return get(id)
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_contact', {
      p_contact_id: id
    })
    if (error) throw error
  }

  return { list, get, create, update, remove }
}
