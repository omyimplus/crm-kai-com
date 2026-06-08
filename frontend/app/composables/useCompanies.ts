import type { Company } from '~/types/crm'

export function useCompanies() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()

  async function list() {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .order('name')
    if (error) throw error
    return data as Company[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('id', id)
      .single()
    if (error) throw error
    return data as Company
  }

  async function create(payload: Partial<Company>) {
    const { data, error } = await supabase
      .from('companies')
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

  async function update(id: string, payload: Partial<Company>) {
    const { data, error } = await supabase
      .from('companies')
      .update(payload)
      .eq('id', id)
      .select()
      .single()
    if (error) throw error
    return data
  }

  async function remove(id: string) {
    const { error } = await supabase
      .from('companies')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', id)
    if (error) throw error
  }

  return { list, get, create, update, remove }
}
