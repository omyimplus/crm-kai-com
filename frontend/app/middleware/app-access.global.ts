export default defineNuxtRouteMiddleware(async (to) => {
  if (!to.path.startsWith('/app')) {
    return
  }
  if (to.path === '/app/pending') {
    return
  }

  const user = await useAuthSession()
  if (!user) {
    return
  }

  const { fetchProfile } = useProfile()
  const profile = await fetchProfile()
  if (!profile) {
    return
  }

  if (!profile.is_active) {
    return navigateTo('/app/pending')
  }
})
