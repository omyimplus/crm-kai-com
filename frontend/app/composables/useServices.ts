import type { Service } from '~/types/crm'
import type { MasterServiceFormInput } from '~/utils/masterService'
import { formToServicePayload } from '~/utils/masterService'

export function useServices() {
  const supabase = useSupabaseClient()

  async function list() {
    const { data, error } = await supabase
      .from('services')
      .select('*')
      .is('deleted_at', null)
      .order('service_code')
    if (error) throw error
    return data as Service[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('services')
      .select('*')
      .eq('id', id)
      .is('deleted_at', null)
      .single()
    if (error) throw error
    return data as Service
  }

  async function create(payload: MasterServiceFormInput) {
    const { data: id, error } = await supabase.rpc('create_service', {
      p_payload: formToServicePayload(payload)
    })
    if (error) throw error
    return get(String(id))
  }

  return { list, get, create }
}
