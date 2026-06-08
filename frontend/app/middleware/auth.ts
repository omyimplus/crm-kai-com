export default defineNuxtRouteMiddleware(async () => {
  const user = await useAuthSession()
  if (!user) {
    return navigateTo('/login')
  }
})
