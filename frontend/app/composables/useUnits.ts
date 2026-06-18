import type { Unit } from '~/types/crm'
import type { MasterUnitFormInput } from '~/utils/masterUnit'
import { formToUnitPayload } from '~/utils/masterUnit'

export function useUnits() {
  const supabase = useSupabaseClient()

  async function list() {
    const { data, error } = await supabase
      .from('units')
      .select('*')
      .is('deleted_at', null)
      .order('sort_order')
      .order('unit_code')
    if (error) throw error
    return data as Unit[]
  }

  async function listDeleted() {
    const { data, error } = await supabase
      .from('units')
      .select('*')
      .not('deleted_at', 'is', null)
      .order('deleted_at', { ascending: false })
    if (error) throw error
    return data as Unit[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('units')
      .select('*')
      .eq('id', id)
      .is('deleted_at', null)
      .single()
    if (error) throw error
    return data as Unit
  }

  async function create(payload: MasterUnitFormInput) {
    const { data: id, error } = await supabase.rpc('create_unit', {
      p_payload: formToUnitPayload(payload)
    })
    if (error) throw error
    return get(String(id))
  }

  async function update(id: string, payload: MasterUnitFormInput) {
    const { error } = await supabase.rpc('update_unit', {
      p_unit_id: id,
      p_payload: formToUnitPayload(payload)
    })
    if (error) throw error
    return get(id)
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_unit', {
      p_unit_id: id
    })
    if (error) throw error
  }

  async function restore(id: string) {
    const { error } = await supabase.rpc('restore_unit', {
      p_unit_id: id
    })
    if (error) throw error
  }

  return { list, listDeleted, get, create, update, remove, restore }
}
