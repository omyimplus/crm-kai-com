export const LEAD_SOURCE_STATUSES = ['active', 'inactive'] as const
export type LeadSourceStatus = (typeof LEAD_SOURCE_STATUSES)[number]

export const masterLeadSourceSectionThemes = {
  basicInfo: {
    icon: 'i-lucide-radar',
    iconClass: 'bg-violet-100 text-violet-700 dark:bg-violet-950/60 dark:text-violet-300'
  },
  settings: {
    icon: 'i-lucide-sliders-horizontal',
    iconClass: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300'
  }
} as const
