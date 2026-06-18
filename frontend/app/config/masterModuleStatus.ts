export const MODULE_STATUS_MODULE_KEYS = [
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

export type ModuleStatusModuleKey = (typeof MODULE_STATUS_MODULE_KEYS)[number]

export const MODULE_STATUS_RECORD_STATUSES = ['active', 'inactive'] as const
export type ModuleStatusRecordStatus = (typeof MODULE_STATUS_RECORD_STATUSES)[number]

export const masterModuleStatusSectionThemes = {
  basicInfo: {
    icon: 'i-lucide-list-tree',
    iconClass: 'bg-indigo-100 text-indigo-700 dark:bg-indigo-950/60 dark:text-indigo-300'
  },
  settings: {
    icon: 'i-lucide-sliders-horizontal',
    iconClass: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300'
  }
} as const
