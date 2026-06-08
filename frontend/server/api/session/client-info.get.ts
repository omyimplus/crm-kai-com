export default defineEventHandler((event) => {
  const ip = getRequestIP(event, { xForwardedFor: true }) ?? null
  return { ip }
})
