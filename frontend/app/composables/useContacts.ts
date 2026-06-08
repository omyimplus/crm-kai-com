import type { Contact } from '~/types/crm'

export function useContacts() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()

  async function list() {
    const { data, error } = await supabase
      .from('contacts')
      .select('*, companies(name)')
      .order('created_at', { ascending: false })
    if (error) throw error
    return data as Contact[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('contacts')
      .select('*, companies(name)')
      .eq('id', id)
      .single()
    if (error) throw error
    return data as Contact
  }

  async function create(payload: Partial<Contact>) {
    const { data, error } = await supabase
      .from('contacts')
      .insert({
        ...payload,
        org_id: profile.value!.org_id,
        created_by: profile.value!.id
      })
      .select()
      .single()
    if (error) throw error
    return data
  }

  async function update(id: string, payload: Partial<Contact>) {
    const { data, error } = await supabase
      .from('contacts')
      .update(payload)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  }

  async function remove(id: string) {
    const { error } = await supabase
      .from('contacts')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id)
    if (error) throw error
  }

  return { list, get, create, update, remove }
}
