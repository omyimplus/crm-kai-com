import type { SalesTeam } from '~/types/crm'
import type { MasterSalesTeamFormInput } from '~/utils/masterSalesTeam'
import { formToSalesTeamPayload } from '~/utils/masterSalesTeam'

const SALES_TEAM_SELECT = `
  *,
  team_lead:profiles!sales_teams_team_lead_id_fkey(id, full_name, username, avatar_url),
  sales_team_members(
    profile_id,
    profiles(id, full_name, username, avatar_url)
  )
`

export function useSalesTeams() {
  const supabase = useSupabaseClient()

  async function list() {
    const { data, error } = await supabase
      .from('sales_teams')
      .select(SALES_TEAM_SELECT)
      .is('deleted_at', null)
      .order('sort_order')
      .order('name')
    if (error) throw error
    return data as SalesTeam[]
  }

  async function listDeleted() {
    const { data, error } = await supabase
      .from('sales_teams')
      .select(SALES_TEAM_SELECT)
      .not('deleted_at', 'is', null)
      .order('deleted_at', { ascending: false })
    if (error) throw error
    return data as SalesTeam[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('sales_teams')
      .select(SALES_TEAM_SELECT)
      .eq('id', id)
      .is('deleted_at', null)
      .single()
    if (error) throw error
    return data as SalesTeam
  }

  async function create(payload: MasterSalesTeamFormInput) {
    const { data: id, error } = await supabase.rpc('create_sales_team', {
      p_payload: formToSalesTeamPayload(payload)
    })
    if (error) throw error
    return get(String(id))
  }

  async function update(id: string, payload: MasterSalesTeamFormInput) {
    const { error } = await supabase.rpc('update_sales_team', {
      p_team_id: id,
      p_payload: formToSalesTeamPayload(payload)
    })
    if (error) throw error
    return get(id)
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_sales_team', {
      p_team_id: id
    })
    if (error) throw error
  }

  async function restore(id: string) {
    const { error } = await supabase.rpc('restore_sales_team', {
      p_team_id: id
    })
    if (error) throw error
  }

  async function listActiveProfiles() {
    const { data, error } = await supabase
      .from('profiles')
      .select('id, full_name, username, avatar_url, is_active')
      .eq('is_active', true)
      .order('full_name')
    if (error) throw error
    return data ?? []
  }

  return {
    list,
    listDeleted,
    get,
    create,
    update,
    remove,
    restore,
    listActiveProfiles
  }
}
