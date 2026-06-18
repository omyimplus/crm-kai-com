export const UNIT_STATUSES = ['active', 'inactive'] as const
export type UnitStatus = (typeof UNIT_STATUSES)[number]

export const masterUnitSectionThemes = {
  basicInfo: {
    icon: 'i-lucide-ruler',
    iconClass: 'bg-sky-100 text-sky-700 dark:bg-sky-950/60 dark:text-sky-300'
  },
  settings: {
    icon: 'i-lucide-sliders-horizontal',
    iconClass: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300'
  }
} as const
