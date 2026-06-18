import type {
  JobCodeDatePart,
  JobCodeDateStyle,
  JobCodeSegment
} from '~/config/masterJobCode'

export interface JobCodePreviewInput {
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
}

function pad2(value: number) {
  return String(value).padStart(2, '0')
}

function formatDateSegment(input: JobCodePreviewInput, date: Date): string | null {
  if (!input.date_enabled) return null

  const year = date.getFullYear()
  const month = date.getMonth() + 1
  const day = date.getDate()

  const tokenFor = (part: JobCodeDatePart): string | null => {
    if (part === 'year' && input.date_include_year) return String(year)
    if (part === 'month' && input.date_include_month) return pad2(month)
    if (part === 'day' && input.date_include_day) return pad2(day)
    return null
  }

  const tokens = input.date_part_order
    .map(tokenFor)
    .filter((token): token is string => Boolean(token))

  if (tokens.length === 0) return null

  if (input.date_style === 'iso') {
    return tokens.join('-')
  }
  if (input.date_style === 'dash') {
    return tokens.join('-')
  }
  return tokens.join('')
}

function formatNumberSegment(input: JobCodePreviewInput) {
  const length = Math.min(Math.max(input.pad_length, 1), 10)
  const number = Math.max(input.start_number, 1)
  return String(number).padStart(length, '0')
}

/** Preview next document code — uses start_number (not last_number) for master data UI */
export function previewJobCode(input: JobCodePreviewInput, date = new Date()): string {
  const parts: string[] = []

  for (const segment of input.segment_order) {
    if (segment === 'prefix') {
      const prefix = input.prefix.trim().toUpperCase()
      if (prefix) parts.push(prefix)
      continue
    }
    if (segment === 'date') {
      const datePart = formatDateSegment(input, date)
      if (datePart) parts.push(datePart)
      continue
    }
    if (segment === 'number') {
      parts.push(formatNumberSegment(input))
    }
  }

  return parts.join(input.separator_enabled ? (input.segment_separator || '-') : '')
}
