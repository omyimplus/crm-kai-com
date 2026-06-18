export interface AppViewModeOption<T extends string = string> {
  value: T
  icon: string
  /** Accessible name (and visible label when showLabels) */
  label: string
}

export const APP_TABLE_GRID_VIEW_MODES = ['table', 'grid'] as const
export type AppTableGridViewMode = (typeof APP_TABLE_GRID_VIEW_MODES)[number]

export function appTableGridViewOptions(t: (key: string) => string): AppViewModeOption<AppTableGridViewMode>[] {
  return [
    { value: 'table', icon: 'i-lucide-list', label: t('common.viewMode.table') },
    { value: 'grid', icon: 'i-lucide-layout-grid', label: t('common.viewMode.grid') }
  ]
}

export const APP_LIST_CALENDAR_VIEW_MODES = ['list', 'calendar'] as const
export type AppListCalendarViewMode = (typeof APP_LIST_CALENDAR_VIEW_MODES)[number]

export function appListCalendarViewOptions(t: (key: string) => string): AppViewModeOption<AppListCalendarViewMode>[] {
  return [
    { value: 'list', icon: 'i-lucide-list', label: t('common.viewMode.list') },
    { value: 'calendar', icon: 'i-lucide-calendar', label: t('common.viewMode.calendar') }
  ]
}
