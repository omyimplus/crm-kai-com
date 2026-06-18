import type { JobCodeSequence } from '~/types/crm'
import {
  JOB_CODE_DATE_PARTS,
  JOB_CODE_MODULE_KEYS,
  JOB_CODE_RECORD_STATUSES,
  JOB_CODE_RESET_RULES,
  JOB_CODE_SEGMENT_SEPARATORS,
  JOB_CODE_SEGMENTS,
  type JobCodeDatePart,
  type JobCodeDateStyle,
  type JobCodeModuleKey,
  type JobCodeRecordStatus,
  type JobCodeResetRule,
  type JobCodeSegment
} from '~/config/masterJobCode'
import type { JobCodePreviewInput } from '~/utils/jobCodePreview'
import { previewJobCode } from '~/utils/jobCodePreview'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

const JOB_CODE_PREFIX_PATTERN = /^[A-Z][A-Z0-9]{0,9}$/

export interface MasterJobCodeFormInput {
  module_key: JobCodeModuleKey | null
  prefix: string
  date_enabled: boolean
  date_include_year: boolean
  date_include_month: boolean
  date_include_day: boolean
  date_part_order: JobCodeDatePart[]
  date_style: JobCodeDateStyle
  segment_order: JobCodeSegment[]
  separator_enabled: boolean
  segment_separator: string
  pad_length: number
  start_number: number
  reset_rule: JobCodeResetRule
  status: JobCodeRecordStatus
  notes: string
}

export function defaultMasterJobCodeFormInput(
  moduleKey: JobCodeModuleKey | null = null
): MasterJobCodeFormInput {
  return {
    module_key: moduleKey,
    prefix: '',
    date_enabled: true,
    date_include_year: true,
    date_include_month: true,
    date_include_day: true,
    date_part_order: [...JOB_CODE_DATE_PARTS],
    date_style: 'compact',
    segment_order: [...JOB_CODE_SEGMENTS],
    separator_enabled: true,
    segment_separator: '-',
    pad_length: 4,
    start_number: 1,
    reset_rule: 'never',
    status: 'active',
    notes: ''
  }
}

export function isJobCodeModuleKey(value: string | null | undefined): value is JobCodeModuleKey {
  return Boolean(value && (JOB_CODE_MODULE_KEYS as readonly string[]).includes(value))
}

export function jobCodeModuleLabel(moduleKey: string, t: (key: string) => string) {
  const key = `masterData.jobCode.options.module.${moduleKey}`
  const translated = t(key)
  return translated === key ? moduleKey : translated
}

export function jobCodeListPath(moduleKey: JobCodeModuleKey) {
  return `/app/job-code?module=${moduleKey}`
}

export function jobCodeToFormInput(row: JobCodeSequence): MasterJobCodeFormInput {
  return {
    module_key: isJobCodeModuleKey(row.module_key) ? row.module_key : null,
    prefix: row.prefix,
    date_enabled: row.date_enabled,
    date_include_year: row.date_include_year,
    date_include_month: row.date_include_month,
    date_include_day: row.date_include_day,
    date_part_order: normalizeDatePartOrder(row.date_part_order),
    date_style: parseDateStyle(row.date_style),
    segment_order: normalizeSegmentOrder(row.segment_order),
    separator_enabled: row.separator_enabled ?? true,
    segment_separator: parseSegmentSeparator(row.segment_separator),
    pad_length: row.pad_length ?? 4,
    start_number: row.start_number ?? 1,
    reset_rule: parseResetRule(row.reset_rule),
    status: parseRecordStatus(row.status),
    notes: row.notes ?? ''
  }
}

export function isJobCodeDatePartIncluded(
  form: Pick<MasterJobCodeFormInput, 'date_include_year' | 'date_include_month' | 'date_include_day'>,
  part: JobCodeDatePart
): boolean {
  if (part === 'year') return form.date_include_year
  if (part === 'month') return form.date_include_month
  return form.date_include_day
}

export function enabledJobCodeDatePartOrder(form: MasterJobCodeFormInput): JobCodeDatePart[] {
  return form.date_part_order.filter(part => isJobCodeDatePartIncluded(form, part))
}

export function mergeJobCodeDatePartOrder(
  form: MasterJobCodeFormInput,
  enabledOrder: JobCodeDatePart[]
): JobCodeDatePart[] {
  const disabled = form.date_part_order.filter(part => !isJobCodeDatePartIncluded(form, part))
  return [...enabledOrder, ...disabled]
}

export function formToJobCodePreviewInput(form: MasterJobCodeFormInput): JobCodePreviewInput {
  return {
    prefix: form.prefix,
    date_enabled: form.date_enabled,
    date_include_year: form.date_include_year,
    date_include_month: form.date_include_month,
    date_include_day: form.date_include_day,
    date_part_order: enabledJobCodeDatePartOrder(form),
    date_style: form.date_style,
    segment_order: form.segment_order,
    separator_enabled: form.separator_enabled,
    segment_separator: form.segment_separator,
    pad_length: form.pad_length,
    start_number: form.start_number
  }
}

export function previewMasterJobCode(form: MasterJobCodeFormInput, date?: Date) {
  return previewJobCode(formToJobCodePreviewInput(form), date)
}

function parseDateStyle(value: string | null | undefined): JobCodeDateStyle {
  if (value === 'dash' || value === 'iso' || value === 'compact') return value
  return 'compact'
}

function parseResetRule(value: string | null | undefined): JobCodeResetRule {
  if (value && (JOB_CODE_RESET_RULES as readonly string[]).includes(value)) {
    return value as JobCodeResetRule
  }
  return 'never'
}

function parseRecordStatus(value: string | null | undefined): JobCodeRecordStatus {
  if (value && (JOB_CODE_RECORD_STATUSES as readonly string[]).includes(value)) {
    return value as JobCodeRecordStatus
  }
  return 'active'
}

function parseSegmentSeparator(value: string | null | undefined): string {
  if (value && (JOB_CODE_SEGMENT_SEPARATORS as readonly string[]).includes(value)) {
    return value
  }
  return '-'
}

function normalizeDatePartOrder(order: string[] | null | undefined): JobCodeDatePart[] {
  const valid = (order ?? []).filter(
    (part): part is JobCodeDatePart =>
      (JOB_CODE_DATE_PARTS as readonly string[]).includes(part)
  )
  const merged = [...valid]
  for (const part of JOB_CODE_DATE_PARTS) {
    if (!merged.includes(part)) merged.push(part)
  }
  return merged
}

function normalizeSegmentOrder(order: string[] | null | undefined): JobCodeSegment[] {
  const valid = (order ?? []).filter(
    (part): part is JobCodeSegment =>
      (JOB_CODE_SEGMENTS as readonly string[]).includes(part)
  )
  const merged = [...valid]
  for (const part of JOB_CODE_SEGMENTS) {
    if (!merged.includes(part)) merged.push(part)
  }
  return merged.slice(0, JOB_CODE_SEGMENTS.length)
}

export function normalizeJobCodePrefixInput(raw: string): string {
  return raw.toUpperCase().replace(/[^A-Z0-9]/g, '')
}

function normalizeJobCodePrefix(raw: string): string {
  return raw.trim().toUpperCase()
}

export type MasterJobCodeValidationKey =
  | 'moduleRequired'
  | 'prefixRequired'
  | 'prefixInvalid'
  | 'datePartRequired'
  | 'padLengthInvalid'
  | 'startNumberInvalid'
  | 'separatorInvalid'

export function validateMasterJobCodeForm(
  form: MasterJobCodeFormInput
): MasterJobCodeValidationKey | null {
  if (!form.module_key) return 'moduleRequired'

  const prefix = normalizeJobCodePrefix(form.prefix)
  if (!prefix) return 'prefixRequired'
  if (!JOB_CODE_PREFIX_PATTERN.test(prefix)) return 'prefixInvalid'

  if (form.date_enabled) {
    const hasPart = form.date_include_year || form.date_include_month || form.date_include_day
    if (!hasPart) return 'datePartRequired'
  }

  if (form.pad_length < 1 || form.pad_length > 10) return 'padLengthInvalid'
  if (form.start_number < 1) return 'startNumberInvalid'

  if (form.separator_enabled) {
    if (!(JOB_CODE_SEGMENT_SEPARATORS as readonly string[]).includes(form.segment_separator)) {
      return 'separatorInvalid'
    }
  }

  return null
}

export function formToJobCodePayload(form: MasterJobCodeFormInput) {
  return {
    module_key: form.module_key,
    prefix: normalizeJobCodePrefix(form.prefix),
    date_enabled: form.date_enabled,
    date_include_year: form.date_include_year,
    date_include_month: form.date_include_month,
    date_include_day: form.date_include_day,
    date_part_order: form.date_part_order,
    date_style: form.date_style,
    segment_order: form.segment_order,
    separator_enabled: form.separator_enabled,
    segment_separator: parseSegmentSeparator(form.segment_separator),
    pad_length: form.pad_length,
    start_number: form.start_number,
    reset_rule: form.reset_rule,
    status: form.status,
    notes: form.notes.trim() || null
  }
}

export function jobCodeSaveErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.saveFailed'))
  if (message.includes('Job code already configured')) {
    return t('masterData.jobCode.validation.alreadyConfigured')
  }
  if (message.includes('Invalid prefix format') || message.includes('Prefix required')) {
    return t('masterData.jobCode.validation.prefixInvalid')
  }
  if (message.includes('Invalid segment separator')) {
    return t('masterData.jobCode.validation.separatorInvalid')
  }
  return message || t('common.saveFailed')
}

export function moveOrderItem<T>(items: T[], index: number, direction: -1 | 1): T[] {
  const nextIndex = index + direction
  if (nextIndex < 0 || nextIndex >= items.length) return items
  const next = [...items]
  const temp = next[index]!
  next[index] = next[nextIndex]!
  next[nextIndex] = temp
  return next
}
