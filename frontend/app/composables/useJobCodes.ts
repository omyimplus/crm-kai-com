import type { JobCodeSequence } from '~/types/crm'
import type { JobCodeModuleKey } from '~/config/masterJobCode'
import type { MasterJobCodeFormInput } from '~/utils/masterJobCode'
import { formToJobCodePayload } from '~/utils/masterJobCode'

export function useJobCodes() {
  const supabase = useSupabaseClient()

  async function list() {
    const { data, error } = await supabase
      .from('job_code_sequences')
      .select('*')
      .is('deleted_at', null)
      .order('module_key')
    if (error) throw error
    return data as JobCodeSequence[]
  }

  async function getByModule(moduleKey: JobCodeModuleKey) {
    const { data, error } = await supabase
      .from('job_code_sequences')
      .select('*')
      .eq('module_key', moduleKey)
      .is('deleted_at', null)
      .maybeSingle()
    if (error) throw error
    return data as JobCodeSequence | null
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('job_code_sequences')
      .select('*')
      .eq('id', id)
      .is('deleted_at', null)
      .single()
    if (error) throw error
    return data as JobCodeSequence
  }

  async function create(payload: MasterJobCodeFormInput) {
    const { data: id, error } = await supabase.rpc('create_job_code_sequence', {
      p_payload: formToJobCodePayload(payload)
    })
    if (error) throw error
    return get(String(id))
  }

  async function update(id: string, payload: MasterJobCodeFormInput) {
    const { error } = await supabase.rpc('update_job_code_sequence', {
      p_job_code_sequence_id: id,
      p_payload: formToJobCodePayload(payload)
    })
    if (error) throw error
    return get(id)
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_job_code_sequence', {
      p_job_code_sequence_id: id
    })
    if (error) throw error
  }

  return {
    list,
    getByModule,
    get,
    create,
    update,
    remove
  }
}
