import type { Company, CompanyBillAddress, CompanyShipAddress } from '~/types/crm'
import type { CustomerCompanyAddressDraft } from '~/utils/masterCustomer'
import { normalizeCompanyAddressDefaults } from '~/utils/masterCustomer'

export function useCompanies() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()

  async function list() {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .is('deleted_at', null)
      .order('name')
    if (error) throw error
    return data as Company[]
  }

  async function listDeleted() {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .not('deleted_at', 'is', null)
      .order('deleted_at', { ascending: false })
    if (error) throw error
    return data as Company[]
  }

  async function get(id: string) {
    const { data, error } = await supabase
      .from('companies')
      .select('*')
      .eq('id', id)
      .is('deleted_at', null)
      .single()
    if (error) throw error
    return data as Company
  }

  async function create(payload: Partial<Company>) {
    const { data: id, error } = await supabase.rpc('create_company', {
      p_payload: payload
    })
    if (error) throw error
    return get(String(id))
  }

  async function update(id: string, payload: Partial<Company>) {
    const { error } = await supabase.rpc('update_company', {
      p_company_id: id,
      p_payload: payload
    })
    if (error) throw error
    return get(id)
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_company', {
      p_company_id: id
    })
    if (error) throw error
  }

  async function restore(id: string) {
    const { error } = await supabase.rpc('restore_company', {
      p_company_id: id
    })
    if (error) throw error
  }

  async function listBillAddresses(companyId: string) {
    const { data, error } = await supabase
      .from('company_bill_addresses')
      .select('*')
      .eq('company_id', companyId)
      .order('is_default', { ascending: false })
      .order('sort_order')
    if (error) throw error
    return data as CompanyBillAddress[]
  }

  async function getDefaultBillAddress(companyId: string) {
    const { data, error } = await supabase.rpc('get_company_default_bill_address', {
      p_company_id: companyId
    })
    if (error) throw error
    return (data as CompanyBillAddress | null) ?? null
  }

  async function syncBillAddresses(companyId: string, drafts: CustomerCompanyAddressDraft[]) {
    const orgId = profile.value!.org_id
    const normalized = normalizeCompanyAddressDefaults(drafts)
    const { error: deleteError } = await supabase
      .from('company_bill_addresses')
      .delete()
      .eq('company_id', companyId)
    if (deleteError) throw deleteError

    const rows = normalized
      .map((draft, index) => ({
        org_id: orgId,
        company_id: companyId,
        label: draft.label.trim() || null,
        address: draft.address.trim(),
        is_default: draft.is_default,
        sort_order: index
      }))
      .filter(row => row.address.length > 0)

    if (rows.length === 0) return

    const { error: insertError } = await supabase
      .from('company_bill_addresses')
      .insert(rows)
    if (insertError) throw insertError
  }

  async function listShipAddresses(companyId: string) {
    const { data, error } = await supabase
      .from('company_ship_addresses')
      .select('*')
      .eq('company_id', companyId)
      .order('is_default', { ascending: false })
      .order('sort_order')
    if (error) throw error
    return data as CompanyShipAddress[]
  }

  async function getDefaultShipAddress(companyId: string) {
    const { data, error } = await supabase.rpc('get_company_default_ship_address', {
      p_company_id: companyId
    })
    if (error) throw error
    return (data as CompanyShipAddress | null) ?? null
  }

  async function syncShipAddresses(companyId: string, drafts: CustomerCompanyAddressDraft[]) {
    const orgId = profile.value!.org_id
    const normalized = normalizeCompanyAddressDefaults(drafts)
    const { error: deleteError } = await supabase
      .from('company_ship_addresses')
      .delete()
      .eq('company_id', companyId)
    if (deleteError) throw deleteError

    const rows = normalized
      .map((draft, index) => ({
        org_id: orgId,
        company_id: companyId,
        label: draft.label.trim() || null,
        address: draft.address.trim(),
        is_default: draft.is_default,
        sort_order: index
      }))
      .filter(row => row.address.length > 0)

    if (rows.length === 0) return

    const { error: insertError } = await supabase
      .from('company_ship_addresses')
      .insert(rows)
    if (insertError) throw insertError
  }

  return {
    list,
    listDeleted,
    get,
    create,
    update,
    remove,
    restore,
    listBillAddresses,
    getDefaultBillAddress,
    syncBillAddresses,
    listShipAddresses,
    getDefaultShipAddress,
    syncShipAddresses
  }
}
