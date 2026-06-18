export const SALES_TEAM_STATUSES = ['active', 'inactive'] as const
export type SalesTeamStatus = (typeof SALES_TEAM_STATUSES)[number]

export const masterSalesTeamSectionThemes = {
  basicInfo: {
    icon: 'i-lucide-users',
    iconClass: 'bg-sky-100 text-sky-700 dark:bg-sky-950/60 dark:text-sky-300'
  },
  members: {
    icon: 'i-lucide-user-plus',
    iconClass: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300'
  },
  settings: {
    icon: 'i-lucide-sliders-horizontal',
    iconClass: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300'
  }
} as const
