import type { OrgAuthProviderId, OrgAuthProviders } from '~/config/orgAuthProviders'
import {
  buildProviderUpdatePayload,
  mergeOrgAuthProviders
} from '~/utils/orgAuthProviders'

export function useOrgAuthProviders() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()

  const canManage = computed(() =>
    profile.value?.role === 'owner' || profile.value?.role === 'admin'
  )

  async function get(): Promise<OrgAuthProviders> {
    const { data, error } = await supabase.rpc('get_org_auth_providers')
    if (error) throw error
    return mergeOrgAuthProviders(data as Record<string, unknown>)
  }

  async function update(
    providers: OrgAuthProviders,
    providerId: OrgAuthProviderId,
    patch: Record<string, unknown>
  ) {
    const { error } = await supabase.rpc('update_org_auth_providers', {
      p_payload: buildProviderUpdatePayload(providers, providerId, patch)
    })
    if (error) throw error
  }

  return {
    canManage,
    get,
    update
  }
}
