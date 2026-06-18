export const CATEGORY_MODULE_KEYS = ['product'] as const
export type CategoryModuleKey = (typeof CATEGORY_MODULE_KEYS)[number]

export const CATEGORY_STATUSES = ['active', 'inactive'] as const
export type CategoryStatus = (typeof CATEGORY_STATUSES)[number]

export const CATEGORY_MODULE_KEY: CategoryModuleKey = 'product'

export const masterCategorySectionThemes = {
  basicInfo: {
    icon: 'i-lucide-tags',
    iconClass: 'bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-300'
  },
  hierarchy: {
    icon: 'i-lucide-git-branch',
    iconClass: 'bg-violet-100 text-violet-700 dark:bg-violet-950/60 dark:text-violet-300'
  }
} as const
