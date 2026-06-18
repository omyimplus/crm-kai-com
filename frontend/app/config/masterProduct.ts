export const PRODUCT_STATUSES = ['active', 'inactive'] as const
export type ProductStatus = (typeof PRODUCT_STATUSES)[number]

export const PRODUCT_CURRENCIES = ['THB', 'USD'] as const
export type ProductCurrency = (typeof PRODUCT_CURRENCIES)[number]

export const MAX_PRODUCT_GALLERY_IMAGES = 20

export const masterProductSectionThemes = {
  basicInfo: {
    icon: 'i-lucide-package',
    iconClass: 'bg-sky-100 text-sky-700 dark:bg-sky-950/60 dark:text-sky-300'
  },
  pricing: {
    icon: 'i-lucide-banknote',
    iconClass: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300'
  }
} as const
