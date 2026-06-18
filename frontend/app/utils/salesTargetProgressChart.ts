import type { SalesTargetPeriodType } from '~/config/masterSalesTarget'
import type { MasterSalesTargetFormInput } from '~/utils/masterSalesTarget'

export interface SalesTargetDealClose {
  date: Date
  amount: number
}

export interface SalesTargetLineChartRow {
  cumulative: number
  target: number
  dateLabel: string
}

export interface SalesTargetProgressChartModel {
  start: Date
  end: Date
  targetAmount: number
  currentAmount: number
  dealCloses: SalesTargetDealClose[]
  chartRows: SalesTargetLineChartRow[]
}

function hashSeed(parts: (string | number | null | undefined)[]): number {
  const str = parts.join('|')
  let hash = 2166136261
  for (let i = 0; i < str.length; i++) {
    hash ^= str.charCodeAt(i)
    hash = Math.imul(hash, 16777619)
  }
  return hash >>> 0
}

function createSeededRandom(seed: number) {
  let state = seed >>> 0
  return () => {
    state = (Math.imul(state, 1664525) + 1013904223) >>> 0
    return state / 4294967296
  }
}

function startOfDay(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate())
}

function enumerateDays(start: Date, end: Date): Date[] {
  const days: Date[] = []
  const cursor = startOfDay(start)
  const last = startOfDay(end)
  while (cursor <= last) {
    days.push(new Date(cursor))
    cursor.setDate(cursor.getDate() + 1)
  }
  return days
}

export function getSalesTargetPeriodRange(form: Pick<
  MasterSalesTargetFormInput,
  'period_type' | 'period_year' | 'period_month' | 'period_quarter'
>): { start: Date, end: Date } {
  const { period_type, period_year } = form
  if (period_type === 'month' && form.period_month) {
    const start = new Date(period_year, form.period_month - 1, 1)
    const end = new Date(period_year, form.period_month, 0)
    return { start, end }
  }
  if (period_type === 'quarter' && form.period_quarter) {
    const startMonth = (form.period_quarter - 1) * 3
    const start = new Date(period_year, startMonth, 1)
    const end = new Date(period_year, startMonth + 3, 0)
    return { start, end }
  }
  return {
    start: new Date(period_year, 0, 1),
    end: new Date(period_year, 11, 31)
  }
}

function splitDealAmounts(total: number, count: number, rand: () => number): number[] {
  if (count <= 1) return [total]
  const weights = Array.from({ length: count }, () => 0.2 + rand() * 0.8)
  const weightSum = weights.reduce((sum, value) => sum + value, 0)
  const amounts = weights.map(weight => Math.floor((total * weight) / weightSum))
  let remainder = total - amounts.reduce((sum, value) => sum + value, 0)
  let index = 0
  while (remainder > 0) {
    amounts[index % amounts.length] += 1
    remainder -= 1
    index += 1
  }
  return amounts.filter(amount => amount > 0)
}

export function simulateSalesTargetDealCloses(
  form: MasterSalesTargetFormInput
): SalesTargetDealClose[] {
  const currentAmount = Math.max(0, Math.round(form.current_amount ?? 0))
  if (currentAmount <= 0) return []

  const { start, end } = getSalesTargetPeriodRange(form)
  const dayCount = enumerateDays(start, end).length
  if (dayCount <= 0) return []

  const rand = createSeededRandom(hashSeed([
    form.profile_id,
    form.period_type,
    form.period_year,
    form.period_month,
    form.period_quarter,
    currentAmount
  ]))

  const dealCount = Math.min(
    8,
    Math.max(2, 2 + Math.floor(rand() * 5))
  )
  const amounts = splitDealAmounts(currentAmount, dealCount, rand)
  const dayIndexes = new Set<number>()

  while (dayIndexes.size < amounts.length) {
    dayIndexes.add(Math.floor(rand() * dayCount))
  }

  const sortedIndexes = [...dayIndexes].sort((a, b) => a - b)
  const days = enumerateDays(start, end)

  return amounts.map((amount, index) => ({
    date: days[sortedIndexes[index] ?? index] ?? end,
    amount
  })).sort((a, b) => a.date.getTime() - b.date.getTime())
}

export function formatSalesTargetChartDate(
  date: Date,
  locale: string,
  periodType: SalesTargetPeriodType
): string {
  const loc = locale === 'th' ? 'th-TH' : 'en-US'
  if (periodType === 'year') {
    return new Intl.DateTimeFormat(loc, { month: 'short' }).format(date)
  }
  return new Intl.DateTimeFormat(loc, { day: 'numeric', month: 'short' }).format(date)
}

function buildChartRows(
  form: MasterSalesTargetFormInput,
  dealCloses: SalesTargetDealClose[],
  locale: string,
  targetAmount: number
): SalesTargetLineChartRow[] {
  const { start, end } = getSalesTargetPeriodRange(form)
  const closesByDay = new Map<number, number>()

  for (const deal of dealCloses) {
    const key = startOfDay(deal.date).getTime()
    closesByDay.set(key, (closesByDay.get(key) ?? 0) + deal.amount)
  }

  let cumulative = 0
  return enumerateDays(start, end).map((date) => {
    const dealAmount = closesByDay.get(startOfDay(date).getTime()) ?? 0
    if (dealAmount) cumulative += dealAmount
    return {
      cumulative,
      target: targetAmount,
      dateLabel: formatSalesTargetChartDate(date, locale, form.period_type)
    }
  })
}

export function buildSalesTargetProgressChartModel(
  form: MasterSalesTargetFormInput,
  locale: string
): SalesTargetProgressChartModel {
  const { start, end } = getSalesTargetPeriodRange(form)
  const targetAmount = Math.max(0, form.target_amount ?? 0)
  const currentAmount = Math.max(0, form.current_amount ?? 0)
  const dealCloses = simulateSalesTargetDealCloses(form)
  const chartRows = buildChartRows(form, dealCloses, locale, targetAmount)

  return {
    start,
    end,
    targetAmount,
    currentAmount,
    dealCloses,
    chartRows
  }
}
