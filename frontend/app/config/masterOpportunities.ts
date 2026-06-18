export const OPPORTUNITY_STATUSES = ['open', 'won', 'lost'] as const
export type OpportunityStatus = (typeof OPPORTUNITY_STATUSES)[number]

/** ประเภทโปรเจกต์ — dropdown v1 (เก็บ slug ใน DB) */
export const OPPORTUNITY_PROJECT_TYPES = [
  'installation',
  'maintenance',
  'renovation',
  'supply',
  'service',
  'other'
] as const
export type OpportunityProjectType = (typeof OPPORTUNITY_PROJECT_TYPES)[number]

export const OPPORTUNITY_PROJECT_SUB_TYPES = [
  'phase_1',
  'phase_2',
  'warranty',
  'upgrade',
  'other'
] as const
export type OpportunityProjectSubType = (typeof OPPORTUNITY_PROJECT_SUB_TYPES)[number]

export const opportunitiesSectionThemes = {
  opportunity: {
    icon: 'i-lucide-sparkles',
    iconClass: 'bg-violet-100 text-violet-700 dark:bg-violet-950/60 dark:text-violet-300'
  },
  project: {
    icon: 'i-lucide-briefcase',
    iconClass: 'bg-teal-100 text-teal-700 dark:bg-teal-950/60 dark:text-teal-300'
  },
  people: {
    icon: 'i-lucide-users',
    iconClass: 'bg-rose-100 text-rose-700 dark:bg-rose-950/60 dark:text-rose-300'
  },
  address: {
    icon: 'i-lucide-map-pin',
    iconClass: 'bg-blue-100 text-blue-700 dark:bg-blue-950/60 dark:text-blue-300'
  }
} as const
