import type { OrgCompanyProfile, OrgCompanyProfileInput } from '~/types/crm'
import { mapOrgCompanyProfile } from '~/utils/orgCompanyProfile'

export function useOrgCompanyProfiles() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()
  const { removeLogo } = useOrgCompanyLogo()

  const canManage = computed(() =>
    profile.value?.role === 'owner' || profile.value?.role === 'admin'
  )

  async function list(): Promise<OrgCompanyProfile[]> {
    const { data, error } = await supabase.rpc('list_org_company_profiles')
    if (error) throw error
    return ((data ?? []) as Record<string, unknown>[]).map(mapOrgCompanyProfile)
  }

  async function create(payload: OrgCompanyProfileInput): Promise<string> {
    const { data, error } = await supabase.rpc('create_org_company_profile', {
      p_payload: payload
    })
    if (error) throw error
    return data as string
  }

  async function update(profileId: string, payload: OrgCompanyProfileInput) {
    const { error } = await supabase.rpc('update_org_company_profile', {
      p_profile_id: profileId,
      p_payload: payload
    })
    if (error) throw error
  }

  async function remove(profileId: string, knownLogoUrl?: string | null) {
    await removeLogo(profileId, knownLogoUrl)

    const { error } = await supabase.rpc('delete_org_company_profile', {
      p_profile_id: profileId
    })
    if (error) throw error
  }

  return {
    canManage,
    list,
    create,
    update,
    remove
  }
}
