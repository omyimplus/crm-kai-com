export const SERVICE_KINDS = [
  'repair',
  'maintenance',
  'installation',
  'consulting',
  'other'
] as const

export const SERVICE_STATUSES = ['active', 'inactive'] as const

export const masterServiceSectionThemes = {
  basicInfo: {
    icon: 'i-lucide-wrench',
    iconClass: 'bg-sky-100 text-sky-700 dark:bg-sky-950/60 dark:text-sky-300'
  },
  pricing: {
    icon: 'i-lucide-banknote',
    iconClass: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300'
  }
} as const
