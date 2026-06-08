import { Hono } from 'hono'
import { healthRoutes } from './health.js'

export const app = new Hono()

app.route('/health', healthRoutes)
