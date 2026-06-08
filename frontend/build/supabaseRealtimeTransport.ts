import ws from 'ws'

/** Node < 22 — Supabase Realtime SSR ต้องใช้ `ws` (browser ใช้ native WebSocket เอง) */
export function getSupabaseRealtimeTransport() {
  if (typeof globalThis.WebSocket !== 'undefined') {
    return globalThis.WebSocket
  }
  return ws
}
