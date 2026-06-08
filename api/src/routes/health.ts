import { Hono } from 'hono'

export const healthRoutes = new Hono()

healthRoutes.get('/', (c) =>
  c.json({
    status: 'ok',
    service: 'crm-kai-api',
    phase: 'scaffold',
    note: 'Control Plane API — implement in Phase 3+'
  })
)
