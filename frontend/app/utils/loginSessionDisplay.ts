import type { LoginSession } from '~/types/crm'

export interface SessionEndedDisplay {
  at: string | null
  approximate: boolean
  stillActive: boolean
}

/** Ended time: explicit logout/login replacement, or last_seen when idle timeout */
export function getSessionEndedDisplay(session: LoginSession): SessionEndedDisplay {
  if (session.is_online) {
    return { at: null, approximate: false, stillActive: true }
  }

  if (session.ended_at) {
    return { at: session.ended_at, approximate: false, stillActive: false }
  }

  return { at: session.last_seen_at, approximate: true, stillActive: false }
}
