import type { SalesTarget } from '~/types/crm'
import {
  SALES_TARGET_CURRENCY,
  type SalesTargetPeriodType
} from '~/config/masterSalesTarget'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

export interface MasterSalesTargetFormInput {
  profile_id: string | null
  period_type: SalesTargetPeriodType
  period_year: number
  period_month: number | null
  period_quarter: number | null
  target_amount: number | null
  current_amount: number | null
  currency: string
  notes: string
}

export function defaultMasterSalesTargetFormInput(): MasterSalesTargetFormInput {
  const now = new Date()
  return {
    profile_id: null,
    period_type: 'month',
    period_year: now.getFullYear(),
    period_month: now.getMonth() + 1,
    period_quarter: null,
    target_amount: null,
    current_amount: 0,
    currency: SALES_TARGET_CURRENCY,
    notes: ''
  }
}

export function salesTargetToFormInput(row: SalesTarget): MasterSalesTargetFormInput {
  return {
    profile_id: row.profile_id,
    period_type: row.period_type,
    period_year: row.period_year,
    period_month: row.period_month,
    period_quarter: row.period_quarter,
    target_amount: row.target_amount,
    current_amount: row.current_amount ?? 0,
    currency: row.currency,
    notes: row.notes ?? ''
  }
}

export function formToSalesTargetPayload(form: MasterSalesTargetFormInput) {
  return {
    profile_id: form.profile_id,
    period_type: form.period_type,
    period_year: form.period_year,
    period_month: form.period_type === 'month' ? form.period_month : null,
    period_quarter: form.period_type === 'quarter' ? form.period_quarter : null,
    target_amount: form.target_amount ?? 0,
    current_amount: form.current_amount ?? 0,
    currency: form.currency.trim() || SALES_TARGET_CURRENCY,
    notes: form.notes.trim() || null
  }
}

export type MasterSalesTargetValidationKey =
  | 'assigneeRequired'
  | 'yearRequired'
  | 'monthRequired'
  | 'quarterRequired'
  | 'amountRequired'
  | 'amountInvalid'
  | 'currentAmountInvalid'
  | 'duplicatePeriod'

export function validateMasterSalesTargetForm(
  form: MasterSalesTargetFormInput
): MasterSalesTargetValidationKey | null {
  if (!form.profile_id) return 'assigneeRequired'
  if (!form.period_year || form.period_year < 2000 || form.period_year > 2100) return 'yearRequired'
  if (form.period_type === 'month' && !form.period_month) return 'monthRequired'
  if (form.period_type === 'quarter' && !form.period_quarter) return 'quarterRequired'
  if (form.target_amount == null || Number.isNaN(form.target_amount)) return 'amountRequired'
  if (form.target_amount < 0) return 'amountInvalid'
  if (form.current_amount != null && form.current_amount < 0) return 'currentAmountInvalid'
  return null
}

export function profileDisplayName(profile: {
  full_name?: string | null
  username?: string | null
  email?: string | null
}) {
  return profile.full_name?.trim()
    || profile.username?.trim()
    || profile.email?.trim()
    || '—'
}

export function computeAchievementPct(target: number, actual: number): number {
  if (target <= 0) return actual > 0 ? 100 : 0
  return Math.round((actual / target) * 100)
}

export function formatSalesAmount(
  amount: number,
  currency: string,
  locale: string
): string {
  try {
    return new Intl.NumberFormat(locale === 'th' ? 'th-TH' : 'en-US', {
      style: 'currency',
      currency: currency || SALES_TARGET_CURRENCY,
      maximumFractionDigits: 0
    }).format(amount)
  } catch {
    return `${amount.toLocaleString()} ${currency}`
  }
}

export function salesTargetSaveErrorMessage(
  error: unknown,
  t: (key: string) => string,
  fallback: string
): string {
  const message = getSupabaseErrorMessage(error, fallback)
  if (
    message.includes('sales_targets_unique_active_period')
    || message.includes('duplicate key value violates unique constraint')
  ) {
    return t('masterData.salesTarget.validation.duplicatePeriod')
  }
  return message
}

export function formatSalesTargetPeriod(
  row: Pick<SalesTarget, 'period_type' | 'period_year' | 'period_month' | 'period_quarter'>,
  t: (key: string, params?: Record<string, unknown>) => string
): string {
  if (row.period_type === 'month' && row.period_month) {
    return t('masterData.salesTarget.period.monthLabel', {
      month: t(`masterData.salesTarget.options.months.${row.period_month}`),
      year: row.period_year
    })
  }
  if (row.period_type === 'quarter' && row.period_quarter) {
    return t('masterData.salesTarget.period.quarterLabel', {
      quarter: t(`masterData.salesTarget.options.quarters.${row.period_quarter}`),
      year: row.period_year
    })
  }
  return t('masterData.salesTarget.period.yearLabel', { year: row.period_year })
}
