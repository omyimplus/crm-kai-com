import {
  LOGIN_SESSION_STORAGE_KEY,
  LOGIN_SESSION_TOUCH_MS
} from '~/config/loginSession'
import type { LoginSession } from '~/types/crm'
import { parseUserAgent } from '~/utils/userAgent'

export function useLoginSession() {
  const supabase = useSupabaseClient()
  const { profile } = useProfile()

  const canView = computed(() =>
    profile.value?.role === 'owner' || profile.value?.role === 'admin'
  )

  function getStoredSessionId(): string | null {
    if (!import.meta.client) {
      return null
    }
    return localStorage.getItem(LOGIN_SESSION_STORAGE_KEY)
  }

  function storeSessionId(id: string) {
    if (!import.meta.client) {
      return
    }
    localStorage.setItem(LOGIN_SESSION_STORAGE_KEY, id)
  }

  function clearStoredSessionId() {
    if (!import.meta.client) {
      return
    }
    localStorage.removeItem(LOGIN_SESSION_STORAGE_KEY)
  }

  async function fetchClientIp(): Promise<string | null> {
    try {
      const info = await $fetch<{ ip: string | null }>('/api/session/client-info')
      return info.ip
    } catch {
      return null
    }
  }

  async function recordLogin() {
    if (!import.meta.client) {
      return
    }

    const ua = navigator.userAgent
    const { deviceType, browser } = parseUserAgent(ua)
    const ip = await fetchClientIp()

    const { data, error } = await supabase.rpc('record_user_login_session', {
      p_device_type: deviceType,
      p_browser: browser,
      p_ip_address: ip,
      p_user_agent: ua
    })

    if (error) {
      console.error('record_user_login_session', error)
      return
    }

    if (data) {
      storeSessionId(data as string)
    }
  }

  async function touchSession() {
    const sessionId = getStoredSessionId()
    if (!sessionId) {
      return
    }

    const { error } = await supabase.rpc('touch_user_login_session', {
      p_session_id: sessionId
    })

    if (error) {
      console.error('touch_user_login_session', error)
    }
  }

  async function endSession() {
    const sessionId = getStoredSessionId()
    if (sessionId) {
      const { error } = await supabase.rpc('end_user_login_session', {
        p_session_id: sessionId
      })
      if (error) {
        console.error('end_user_login_session', error)
      }
    }
    clearStoredSessionId()
  }

  async function list(): Promise<LoginSession[]> {
    const { data, error } = await supabase.rpc('list_org_login_sessions')
    if (error) {
      throw error
    }
    return (data ?? []) as LoginSession[]
  }

  function startHeartbeat() {
    if (!import.meta.client) {
      return () => {}
    }

    void touchSession()
    const timer = window.setInterval(() => {
      void touchSession()
    }, LOGIN_SESSION_TOUCH_MS)

    return () => window.clearInterval(timer)
  }

  return {
    canView,
    recordLogin,
    touchSession,
    endSession,
    list,
    startHeartbeat
  }
}
