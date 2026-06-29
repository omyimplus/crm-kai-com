import type { BulletLegendItemInterface } from 'vue-chrts'

/** สีมาตรฐานกราฟ CRM Kai — สอดคล้อง brand primary + semantic */
export const APP_CHART_COLORS = {
  primary: '#0b2a5b',
  accent: '#10b981',
  target: '#f59e0b',
  neutral: '#94a3b8',
  error: '#ef4444',
  info: '#0ea5e9'
} as const

export const APP_CHART_DEFAULT_HEIGHT = 280

export const APP_CHART_PADDING = {
  top: 16,
  right: 16,
  bottom: 36,
  left: 56
} as const

export interface AppChartSeries {
  key: string
  label: string
  color: string
  dashed?: boolean
}

export function appChartCategories(
  series: AppChartSeries[]
): Record<string, BulletLegendItemInterface> {
  return Object.fromEntries(
    series.map(item => [item.key, { name: item.label, color: item.color }])
  )
}

export function appChartLineDashArray(series: AppChartSeries[]): number[][] | undefined {
  const dashed = series.some(item => item.dashed)
  if (!dashed) return undefined
  return series.map(item => (item.dashed ? [6, 4] : []))
}

export function formatChartAxisAmount(amount: number, locale: string): string {
  const loc = locale === 'th' ? 'th-TH' : 'en-US'
  return new Intl.NumberFormat(loc, { maximumFractionDigits: 0 }).format(amount)
}
