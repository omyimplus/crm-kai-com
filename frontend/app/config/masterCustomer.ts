export const CUSTOMER_TYPES = ['company', 'individual'] as const
export type CustomerType = (typeof CUSTOMER_TYPES)[number]

export const CUSTOMER_INDUSTRY_SEGMENTS = ['enterprise', 'sme', 'startup', 'individual'] as const
export type CustomerIndustrySegment = (typeof CUSTOMER_INDUSTRY_SEGMENTS)[number]

/** อุตสาหกรรม (Industry) — slug บันทึกลง `companies.industry` */
export const CUSTOMER_INDUSTRIES = [
  'agriculture',
  'construction',
  'education',
  'finance',
  'healthcare',
  'hospitality',
  'manufacturing',
  'retail',
  'technology',
  'transportation'
] as const
export type CustomerIndustry = (typeof CUSTOMER_INDUSTRIES)[number]

export const CUSTOMER_SALES_GRADES = ['vip', 'a', 'b', 'c', 'prospect'] as const
export type CustomerSalesGrade = (typeof CUSTOMER_SALES_GRADES)[number]

export const CUSTOMER_STATUSES = ['active', 'inactive', 'prospect', 'churned', 'pending'] as const
export type CustomerStatus = (typeof CUSTOMER_STATUSES)[number]

/** Badge color บนหน้ารายการลูกค้า — Nuxt UI color */
export const customerStatusBadgeColor: Record<CustomerStatus, 'success' | 'neutral' | 'primary' | 'error' | 'warning'> = {
  active: 'success',
  inactive: 'neutral',
  prospect: 'primary',
  churned: 'error',
  pending: 'warning'
}

export const CUSTOMER_VAT_CURRENCIES = ['THB', 'USD'] as const
export type CustomerVatCurrency = (typeof CUSTOMER_VAT_CURRENCIES)[number]

/** อัตราหัก ณ ที่จ่าย (WHT) — slug บันทึกลง `companies.tax_vat` (mockup row: Tax VAT) */
export const CUSTOMER_WHT_RATE_OPTIONS = [
  'none',
  'wht_3',
  'wht_5',
  'wht_0_5',
  'wht_0_75',
  'wht_1',
  'wht_1_5',
  'wht_2',
  'wht_10',
  'wht_15'
] as const
export type CustomerWhtRate = (typeof CUSTOMER_WHT_RATE_OPTIONS)[number]

export const CUSTOMER_PAYMENT_CODES = ['transfer', 'credit', 'cash', 'cheque'] as const
export type CustomerPaymentCode = (typeof CUSTOMER_PAYMENT_CODES)[number]

export const masterCustomerSectionThemes = {
  general: {
    icon: 'i-lucide-user-round',
    iconClass: 'bg-violet-100 text-violet-700 dark:bg-violet-950/60 dark:text-violet-300'
  },
  tax: {
    icon: 'i-lucide-receipt',
    iconClass: 'bg-amber-100 text-amber-700 dark:bg-amber-950/60 dark:text-amber-300'
  },
  billTo: {
    icon: 'i-lucide-map-pin',
    iconClass: 'bg-pink-100 text-pink-700 dark:bg-pink-950/60 dark:text-pink-300'
  },
  shipTo: {
    icon: 'i-lucide-map-pin',
    iconClass: 'bg-teal-100 text-teal-700 dark:bg-teal-950/60 dark:text-teal-300'
  }
} as const
