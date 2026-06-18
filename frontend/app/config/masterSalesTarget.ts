export const SALES_TARGET_PERIOD_TYPES = ['month', 'quarter', 'year'] as const
export type SalesTargetPeriodType = (typeof SALES_TARGET_PERIOD_TYPES)[number]

export const SALES_TARGET_CURRENCY = 'THB'

export const SALES_TARGET_MONTHS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12] as const
export const SALES_TARGET_QUARTERS = [1, 2, 3, 4] as const

export function salesTargetYearOptions(baseYear = new Date().getFullYear()) {
  return [baseYear - 1, baseYear, baseYear + 1, baseYear + 2]
}

export function achievementColor(pct: number): 'error' | 'warning' | 'success' | 'neutral' {
  if (pct >= 100) return 'success'
  if (pct >= 50) return 'warning'
  if (pct > 0) return 'error'
  return 'neutral'
}

export const masterSalesTargetSectionThemes = {
  main: {
    icon: 'i-lucide-target',
    iconClass: 'bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-300'
  },
  progress: {
    icon: 'i-lucide-trending-up',
    iconClass: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300'
  }
} as const
