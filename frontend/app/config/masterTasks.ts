export const TASK_TYPES = ['task', 'call', 'email', 'meeting', 'visit'] as const
export type TaskType = (typeof TASK_TYPES)[number]

export const TASK_PRIORITIES = ['high', 'medium', 'low'] as const
export type TaskPriority = (typeof TASK_PRIORITIES)[number]

/** Workflow status codes seeded for module_key = task */
export const TASK_STATUS_CODES = ['OPEN', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED'] as const
export type TaskStatusCode = (typeof TASK_STATUS_CODES)[number]

export const TASK_TYPE_ICONS: Record<TaskType, string> = {
  task: 'i-lucide-check-square',
  call: 'i-lucide-phone',
  email: 'i-lucide-mail',
  meeting: 'i-lucide-users',
  visit: 'i-lucide-map-pin'
}

/** Distinct accent per activity type — used in list, filters, form, calendar */
export const TASK_TYPE_COLORS: Record<TaskType, string> = {
  task: '#6366f1',
  call: '#16a34a',
  email: '#2563eb',
  meeting: '#9333ea',
  visit: '#ea580c'
}

export const TASK_PRIORITY_COLORS: Record<TaskPriority, string> = {
  high: '#ef4444',
  medium: '#f59e0b',
  low: '#94a3b8'
}

/** Solid badge — พื้นเข้ม ตัวอักษรขาว */
export const TASK_PRIORITY_SOLID_COLORS: Record<TaskPriority, string> = {
  high: '#b91c1c',
  medium: '#b45309',
  low: '#475569'
}

export const tasksSectionThemes = {
  taskInfo: {
    icon: 'i-lucide-clipboard-list',
    iconClass: 'bg-violet-100 text-violet-700 dark:bg-violet-950/60 dark:text-violet-300'
  },
  people: {
    icon: 'i-lucide-users',
    iconClass: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300'
  },
  details: {
    icon: 'i-lucide-file-text',
    iconClass: 'bg-pink-100 text-pink-700 dark:bg-pink-950/60 dark:text-pink-300'
  }
} as const
