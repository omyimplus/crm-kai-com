import type { Profile } from '~/types/crm'

export function useProfile() {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()
  const profile = useState<Profile | null>('profile', () => null)

  async function fetchProfile() {
    if (!user.value) {
      profile.value = null
      return null
    }
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.value.id)
      .maybeSingle()
    if (error) throw error
    profile.value = data
    return data
  }

  async function ensureProfile() {
    const p = await fetchProfile()
    if (!p && user.value) {
      await navigateTo('/signup?complete=1')
    }
    return p
  }

  return { profile, fetchProfile, ensureProfile }
}
