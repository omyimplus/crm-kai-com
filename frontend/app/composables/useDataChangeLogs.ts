import type { DataChangeAction, DataChangeLog } from '~/types/crm'

export interface DataChangeLogFilters {
  entityType?: string | null
  action?: DataChangeAction | null
  limit?: number
  offset?: number
}

export const DATA_CHANGE_ENTITY_TYPES = [
  'profiles',
  'org_roles',
  'contacts',
  'companies',
  'sales_targets',
  'deals',
  'activities',
  'pipelines',
  'pipeline_stages'
] as const

export function useDataChangeLogs() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()

  const canView = computed(() =>
    profile.value?.role === 'owner' || profile.value?.role === 'admin'
  )

  async function list(filters: DataChangeLogFilters = {}): Promise<DataChangeLog[]> {
    const { data, error } = await supabase.rpc('list_data_change_logs', {
      p_limit: filters.limit ?? 100,
      p_offset: filters.offset ?? 0,
      p_entity_type: filters.entityType ?? null,
      p_action: filters.action ?? null
    })
    if (error) throw error
    return (data ?? []) as DataChangeLog[]
  }

  return { canView, list, entityTypes: DATA_CHANGE_ENTITY_TYPES }
}
