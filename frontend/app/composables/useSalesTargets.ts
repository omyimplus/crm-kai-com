import type { SalesTarget } from '~/types/crm'
import type { MasterSalesTargetFormInput } from '~/utils/masterSalesTarget'
import { computeAchievementPct, formToSalesTargetPayload } from '~/utils/masterSalesTarget'

function withAchievement(rows: SalesTarget[]): SalesTarget[] {
  return rows.map(row => ({
    ...row,
    achievement_pct: computeAchievementPct(
      Number(row.target_amount),
      Number(row.current_amount ?? 0)
    )
  }))
}

const PROFILE_SELECT = '*, profiles!sales_targets_profile_id_fkey(full_name, username)'

export function useSalesTargets() {
  const supabase = useSupabaseClient()

  async function list() {
    const { data, error } = await supabase
      .from('sales_targets')
      .select(PROFILE_SELECT)
      .is('deleted_at', null)
      .order('period_year', { ascending: false })
      .order('period_month', { ascending: false, nullsFirst: false })
      .order('period_quarter', { ascending: false, nullsFirst: false })
    if (error) throw error
    return withAchievement((data ?? []) as SalesTarget[])
  }

  async function listDeleted() {
    const { data, error } = await supabase
      .from('sales_targets')
      .select(PROFILE_SELECT)
      .not('deleted_at', 'is', null)
      .order('deleted_at', { ascending: false })
    if (error) throw error
    return withAchievement((data ?? []) as SalesTarget[])
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('sales_targets')
      .select(PROFILE_SELECT)
      .eq('id', id)
      .is('deleted_at', null)
      .single()
    if (error) throw error
    const [row] = withAchievement([data as SalesTarget])
    return row
  }

  async function create(payload: MasterSalesTargetFormInput) {
    const { data: id, error } = await supabase.rpc('create_sales_target', {
      p_payload: formToSalesTargetPayload(payload)
    })
    if (error) throw error
    return get(String(id))
  }

  async function update(id: string, payload: MasterSalesTargetFormInput) {
    const { error } = await supabase.rpc('update_sales_target', {
      p_target_id: id,
      p_payload: formToSalesTargetPayload(payload)
    })
    if (error) throw error
    return get(id)
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_sales_target', {
      p_target_id: id
    })
    if (error) throw error
  }

  async function restore(id: string) {
    const { error } = await supabase.rpc('restore_sales_target', {
      p_target_id: id
    })
    if (error) throw error
  }

  return { list, listDeleted, get, create, update, remove, restore }
}
