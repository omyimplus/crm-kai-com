import { createServerClient, parseCookieHeader } from '@supabase/ssr'
import { getHeader, setCookie } from 'h3'
import { getSupabaseRealtimeTransport } from '../../build/supabaseRealtimeTransport'

async function fetchWithRetry(req: RequestInfo | URL, init?: RequestInit) {
  const retries = 3
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      return await fetch(req, init)
    } catch (error) {
      if (init?.signal?.aborted) throw error
      if (attempt === retries) {
        console.error(`Error fetching request ${String(req)}`, error, init)
        throw error
      }
      console.warn(`Retrying fetch attempt ${attempt + 1} for request: ${String(req)}`)
    }
  }
  throw new Error('Unreachable fetch retry loop')
}

function setCookies(
  event: ReturnType<typeof useRequestEvent>,
  cookies: Array<{ name: string, value: string, options: Parameters<typeof setCookie>[3] }>
) {
  if (!event) return
  const response = event.node.res
  const headersWritable = () => !response.headersSent && !response.writableEnded
  if (!headersWritable()) return

  for (const { name, value, options } of cookies) {
    if (!headersWritable()) break
    setCookie(event, name, value, options)
  }
}

export default defineNuxtPlugin({
  name: 'supabase',
  enforce: 'pre',
  async setup({ provide }) {
    const { url, key, cookiePrefix, useSsrCookies, cookieOptions, clientOptions } = useRuntimeConfig().public.supabase
    const event = useRequestEvent()

    const client = createServerClient(url, key, {
      ...clientOptions,
      realtime: {
        ...(clientOptions?.realtime ?? {}),
        transport: getSupabaseRealtimeTransport()
      },
      cookies: {
        getAll: () => parseCookieHeader(getHeader(event, 'Cookie') ?? ''),
        setAll: cookies => setCookies(event, cookies)
      },
      cookieOptions: {
        ...cookieOptions,
        name: cookiePrefix
      },
      global: {
        fetch: fetchWithRetry,
        ...clientOptions?.global
      }
    })

    provide('supabase', { client })

    if (useSsrCookies) {
      const { data: { session } } = await client.auth.getSession()
      useSupabaseSession().value = session
      useSupabaseUser().value = session?.user ?? null
    }
  }
})
