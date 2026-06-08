export default defineNuxtRouteMiddleware(async (to) => {
  const user = await useAuthSession()
  if (!user) {
    return
  }
  // Logged-in user finishing profile after email confirm / login
  if (to.path === '/signup' && to.query.complete === '1') {
    return
  }
  return navigateTo('/app')
})
