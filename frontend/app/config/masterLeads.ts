export const LEAD_TYPES = [
  'end_user',
  'dealer',
  'contractor',
  'distributor',
  'oem',
  'other'
] as const
export type LeadType = (typeof LEAD_TYPES)[number]

export const LEAD_PRIORITIES = ['high', 'medium', 'low'] as const
export type LeadPriority = (typeof LEAD_PRIORITIES)[number]

/** Status codes that close a lead — excluded from “active leads” summary */
export const LEAD_CLOSED_STATUS_CODES = ['CONVERTED', 'CANCELLED', 'UNQUALIFIED'] as const

/** Canonical lead workflow statuses (module_statuses.module_key = lead) */
export const LEAD_STATUS_CODES = [
  'NEW',
  'OPEN',
  'CONTACTED',
  'NURTURING',
  'QUALIFIED',
  'UNQUALIFIED',
  'CANCELLED',
  'CONVERTED'
] as const

export const LEAD_HOT_SCORE_MIN = 80
export const LEAD_WARM_SCORE_MIN = 40
export const LEAD_SCORE_MAX = 100

/** ปุ่มลัดในฟอร์มคะแนนลีด */
export const LEAD_SCORE_QUICK_PRESETS = [0, 25, 50, 75, LEAD_HOT_SCORE_MIN, LEAD_SCORE_MAX] as const

export type LeadScoreTier = 'cold' | 'warm' | 'hot'

export const LEAD_SCORE_TIER_ORDER: LeadScoreTier[] = ['cold', 'warm', 'hot']

export const leadScoreTierThemes: Record<LeadScoreTier, {
  ring: string
  fill: string
  badge: 'error' | 'warning' | 'success'
  softBg: string
  softText: string
}> = {
  cold: {
    ring: '#ef4444',
    fill: '#fef2f2',
    badge: 'error',
    softBg: 'bg-red-50 dark:bg-red-950/40',
    softText: 'text-red-700 dark:text-red-300'
  },
  warm: {
    ring: '#f97316',
    fill: '#fff7ed',
    badge: 'warning',
    softBg: 'bg-orange-50 dark:bg-orange-950/40',
    softText: 'text-orange-700 dark:text-orange-300'
  },
  hot: {
    ring: '#22c55e',
    fill: '#f0fdf4',
    badge: 'success',
    softBg: 'bg-emerald-50 dark:bg-emerald-950/40',
    softText: 'text-emerald-700 dark:text-emerald-300'
  }
}

export const leadsSectionThemes = {
  customer: {
    icon: 'i-lucide-building-2',
    iconClass: 'bg-violet-100 text-violet-700 dark:bg-violet-950/60 dark:text-violet-300'
  },
  general: {
    icon: 'i-lucide-user-plus',
    iconClass: 'bg-sky-100 text-sky-700 dark:bg-sky-950/60 dark:text-sky-300'
  },
  score: {
    icon: 'i-lucide-star',
    iconClass: 'bg-orange-100 text-orange-700 dark:bg-orange-950/60 dark:text-orange-300'
  },
  requirement: {
    icon: 'i-lucide-mail',
    iconClass: 'bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-300'
  },
  address: {
    icon: 'i-lucide-map-pin',
    iconClass: 'bg-blue-100 text-blue-700 dark:bg-blue-950/60 dark:text-blue-300'
  }
} as const
