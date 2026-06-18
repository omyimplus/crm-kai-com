import type { ModuleStatus } from '~/types/crm'
import type { ModuleStatusModuleKey } from '~/config/masterModuleStatus'
import type { MasterModuleStatusFormInput } from '~/utils/masterModuleStatus'
import { formToModuleStatusPayload, moduleStatusSelectOptions } from '~/utils/masterModuleStatus'

export function useModuleStatuses() {
  const supabase = useSupabaseClient()

  async function list() {
    const { data, error } = await supabase
      .from('module_statuses')
      .select('*')
      .is('deleted_at', null)
      .order('module_key')
      .order('sort_order')
      .order('name')
    if (error) throw error
    return data as ModuleStatus[]
  }

  async function listByModule(moduleKey: ModuleStatusModuleKey, activeOnly = false) {
    let query = supabase
      .from('module_statuses')
      .select('*')
      .eq('module_key', moduleKey)
      .is('deleted_at', null)
      .order('sort_order')
      .order('name')

    if (activeOnly) {
      query = query.eq('status', 'active')
    }

    const { data, error } = await query
    if (error) throw error
    return data as ModuleStatus[]
  }

  async function listSelectOptions(moduleKey: ModuleStatusModuleKey) {
    return listByModule(moduleKey, true)
  }

  async function listDeleted() {
    const { data, error } = await supabase
      .from('module_statuses')
      .select('*')
      .not('deleted_at', 'is', null)
      .order('deleted_at', { ascending: false })
    if (error) throw error
    return data as ModuleStatus[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('module_statuses')
      .select('*')
      .eq('id', id)
      .is('deleted_at', null)
      .single()
    if (error) throw error
    return data as ModuleStatus
  }

  async function create(payload: MasterModuleStatusFormInput) {
    const { data: id, error } = await supabase.rpc('create_module_status', {
      p_payload: formToModuleStatusPayload(payload)
    })
    if (error) throw error
    return get(String(id))
  }

  async function update(id: string, payload: MasterModuleStatusFormInput) {
    const { error } = await supabase.rpc('update_module_status', {
      p_module_status_id: id,
      p_payload: formToModuleStatusPayload(payload)
    })
    if (error) throw error
    return get(id)
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_module_status', {
      p_module_status_id: id
    })
    if (error) throw error
  }

  async function restore(id: string) {
    const { error } = await supabase.rpc('restore_module_status', {
      p_module_status_id: id
    })
    if (error) throw error
  }

  async function loadSelectOptions(moduleKey: ModuleStatusModuleKey) {
    const rows = await listSelectOptions(moduleKey)
    return moduleStatusSelectOptions(rows)
  }

  return {
    list,
    listByModule,
    listSelectOptions,
    loadSelectOptions,
    listDeleted,
    get,
    create,
    update,
    remove,
    restore
  }
}
