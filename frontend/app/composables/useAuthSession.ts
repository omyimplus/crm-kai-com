/** ตรวจ session จาก cookie — ใช้ใน middleware auth/guest */
export async function useAuthSession() {
  const supabase = useSupabaseClient()
  const user = useSupabaseUser()

  if (user.value) {
    return user.value
  }

  const { data: { user: verified } } = await supabase.auth.getUser()
  return verified
}
