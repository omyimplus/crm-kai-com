import ws from 'ws'

function nodeMajor(): number | null {
  const version = process.versions?.node
  if (!version) return null
  return Number.parseInt(version.split('.')[0] ?? '', 10)
}

/**
 * Supabase Realtime SSR transport.
 * - Browser: native WebSocket (this file is `.server.ts` only — not loaded in browser)
 * - Node 22+: native WebSocket when available
 * - Node < 22: `ws` package (Node 20 has no built-in WebSocket)
 */
export function getSupabaseRealtimeTransport() {
  const major = nodeMajor()
  if (major !== null && major >= 22 && typeof globalThis.WebSocket !== 'undefined') {
    return globalThis.WebSocket
  }
  return ws
}
