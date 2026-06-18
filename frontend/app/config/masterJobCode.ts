export const JOB_CODE_MODULE_KEYS = [
  'task',
  'customer',
  'contact',
  'lead',
  'opportunity',
  'pipeline',
  'quotations',
  'salesOrder',
  'invoices',
  'projects',
  'contractAgreements',
  'service'
] as const

export type JobCodeModuleKey = (typeof JOB_CODE_MODULE_KEYS)[number]

export const JOB_CODE_DATE_PARTS = ['year', 'month', 'day'] as const
export type JobCodeDatePart = (typeof JOB_CODE_DATE_PARTS)[number]

export const JOB_CODE_SEGMENTS = ['prefix', 'date', 'number'] as const
export type JobCodeSegment = (typeof JOB_CODE_SEGMENTS)[number]

export const JOB_CODE_DATE_STYLES = ['compact', 'dash', 'iso'] as const
export type JobCodeDateStyle = (typeof JOB_CODE_DATE_STYLES)[number]

export const JOB_CODE_RESET_RULES = ['never', 'daily', 'monthly', 'yearly'] as const
export type JobCodeResetRule = (typeof JOB_CODE_RESET_RULES)[number]

export const JOB_CODE_SEGMENT_SEPARATORS = ['-', '_', '.', '/', ':'] as const
export type JobCodeSegmentSeparator = (typeof JOB_CODE_SEGMENT_SEPARATORS)[number]

export const JOB_CODE_RECORD_STATUSES = ['active', 'inactive'] as const
export type JobCodeRecordStatus = (typeof JOB_CODE_RECORD_STATUSES)[number]

export const masterJobCodeSectionThemes = {
  basicInfo: {
    icon: 'i-lucide-hash',
    iconClass: 'bg-violet-100 text-violet-700 dark:bg-violet-950/60 dark:text-violet-300'
  },
  dateSegment: {
    icon: 'i-lucide-calendar-range',
    iconClass: 'bg-sky-100 text-sky-700 dark:bg-sky-950/60 dark:text-sky-300'
  },
  numberSegment: {
    icon: 'i-lucide-list-ordered',
    iconClass: 'bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-300'
  },
  layout: {
    icon: 'i-lucide-arrow-left-right',
    iconClass: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300'
  },
  settings: {
    icon: 'i-lucide-sliders-horizontal',
    iconClass: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300'
  }
} as const
