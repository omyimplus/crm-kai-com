import type { Task, TaskFormInput, TaskStatusHistoryEntry, TaskStatusHistoryInput } from '~/types/crm'
import type { Contact, ModuleStatus } from '~/types/crm'
import type { TaskPriority, TaskType } from '~/config/masterTasks'
import { TASK_PRIORITIES, TASK_PRIORITY_COLORS, TASK_PRIORITY_SOLID_COLORS, TASK_TYPE_COLORS, TASK_TYPES } from '~/config/masterTasks'

export function getActiveModuleStatuses(statuses: ModuleStatus[]): ModuleStatus[] {
  return statuses
    .filter(row => row.status === 'active')
    .sort((a, b) => a.sort_order - b.sort_order || a.name.localeCompare(b.name, 'th'))
}

export function resolveDefaultModuleStatus(statuses: ModuleStatus[]): ModuleStatus | null {
  const active = getActiveModuleStatuses(statuses)
  return active.find(row => row.is_default) ?? active[0] ?? null
}

export function resolveDefaultStatusCode(statuses: ModuleStatus[]): string | null {
  return resolveDefaultModuleStatus(statuses)?.status_code ?? null
}

/** Selectable in task form — active rows + current row when editing (inactive but not deleted) */
export function taskFormModuleStatuses(
  statuses: ModuleStatus[],
  currentModuleStatusId?: string | null
): ModuleStatus[] {
  const active = getActiveModuleStatuses(statuses)
  if (!currentModuleStatusId) return active

  const current = statuses.find(row => row.id === currentModuleStatusId)
  if (!current || active.some(row => row.id === current.id)) return active

  return [...active, current].sort(
    (a, b) => a.sort_order - b.sort_order || a.name.localeCompare(b.name, 'th')
  )
}

export function isoToDateInput(value: string | null | undefined): string {
  if (!value) return ''
  return value.slice(0, 10)
}

export function dateInputToIso(value: string | null | undefined): string | null {
  const trimmed = value?.trim()
  if (!trimmed) return null
  return `${trimmed}T00:00:00.000Z`
}

export function isTaskType(value: string | null | undefined): value is TaskType {
  return Boolean(value && (TASK_TYPES as readonly string[]).includes(value))
}

export function taskTypeColor(type: TaskType): string {
  return TASK_TYPE_COLORS[type]
}

export function taskTypeTintStyle(type: TaskType): { backgroundColor: string, color: string } {
  const color = TASK_TYPE_COLORS[type]
  return { backgroundColor: `${color}22`, color }
}

export function taskTypeSolidStyle(type: TaskType): { backgroundColor: string, color: string, borderColor: string } {
  const color = TASK_TYPE_COLORS[type]
  return { backgroundColor: color, color: '#ffffff', borderColor: color }
}

export function taskTypeChipStyle(
  type: TaskType,
  selected: boolean
): { backgroundColor: string, color: string, borderColor: string } {
  const color = TASK_TYPE_COLORS[type]
  if (selected) return taskTypeSolidStyle(type)
  return {
    backgroundColor: `${color}14`,
    color,
    borderColor: `${color}55`
  }
}

export function taskPriorityTintStyle(priority: TaskPriority): { backgroundColor: string, color: string } {
  const color = TASK_PRIORITY_COLORS[priority]
  return { backgroundColor: `${color}22`, color }
}

export function taskPrioritySolidStyle(priority: TaskPriority): { backgroundColor: string, color: string } {
  return {
    backgroundColor: TASK_PRIORITY_SOLID_COLORS[priority],
    color: '#ffffff'
  }
}

export function findTaskContact(
  task: Pick<Task, 'contact_id'>,
  contacts: Contact[]
): Contact | null {
  if (!task.contact_id) return null
  return contacts.find(row => row.id === task.contact_id) ?? null
}

export function taskContactPhone(
  task: Pick<Task, 'contact_id'>,
  contacts: Contact[]
): string | null {
  const contact = findTaskContact(task, contacts)
  return contact?.phone?.trim() || contact?.mobile?.trim() || null
}

export function isTaskPriority(value: string | null | undefined): value is TaskPriority {
  return Boolean(value && (TASK_PRIORITIES as readonly string[]).includes(value))
}

export function taskToFormInput(task: Task): TaskFormInput {
  return {
    subject: task.subject,
    task_type: task.task_type,
    module_status_id: task.module_status_id,
    priority: task.priority,
    start_at: isoToDateInput(task.start_at),
    end_at: isoToDateInput(task.end_at),
    assigned_by: task.assigned_by,
    assigned_to: task.assigned_to,
    sales_team_id: task.sales_team_id,
    company_id: task.company_id,
    contact_id: task.contact_id,
    description: task.description ?? '',
    status_history: []
  }
}

export function defaultTaskFormInput(): TaskFormInput {
  return {
    subject: '',
    task_type: 'task',
    module_status_id: null,
    priority: 'medium',
    start_at: '',
    end_at: '',
    assigned_by: null,
    assigned_to: null,
    sales_team_id: null,
    company_id: null,
    contact_id: null,
    description: '',
    status_history: []
  }
}

export function todayDateInput(): string {
  return new Date().toISOString().slice(0, 10)
}

/** `datetime-local` value in browser local timezone */
export function isoToDateTimeLocalInput(value: string | null | undefined): string {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  const pad = (part: number) => String(part).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
}

export function dateTimeLocalInputToIso(value: string | null | undefined): string | null {
  const trimmed = value?.trim()
  if (!trimmed) return null
  const date = new Date(trimmed)
  if (Number.isNaN(date.getTime())) return null
  return date.toISOString()
}

export function nowDateTimeLocalInput(): string {
  return isoToDateTimeLocalInput(new Date().toISOString())
}

export function statusHistoryEntriesToFormInput(
  entries: TaskStatusHistoryEntry[]
): TaskStatusHistoryInput[] {
  return entries.map(row => ({
    id: row.id,
    module_status_id: row.module_status_id,
    status_at: row.status_at,
    status_code: row.status_code,
    status_name: row.status_name,
    status_color: row.status_color,
    changed_by: row.changed_by,
    changed_by_name: row.changed_by_name
  }))
}

export function sortStatusHistoryEntries(
  entries: TaskStatusHistoryInput[]
): TaskStatusHistoryInput[] {
  return [...entries].sort(
    (a, b) => a.status_at.localeCompare(b.status_at) || (a.id ?? '').localeCompare(b.id ?? '')
  )
}

export function resolveModuleStatusById(
  statuses: ModuleStatus[],
  moduleStatusId: string | null | undefined
): ModuleStatus | null {
  if (!moduleStatusId) return null
  return statuses.find(row => row.id === moduleStatusId) ?? null
}

export function upsertStatusHistoryAt(
  history: TaskStatusHistoryInput[],
  target: TaskStatusHistoryInput,
  dateTimeInput: string
): TaskStatusHistoryInput[] {
  const iso = dateTimeLocalInputToIso(dateTimeInput)
  if (!iso) return history

  return history.map((row) => {
    if (target.id && row.id === target.id) return { ...row, status_at: iso }
    if (
      !target.id
      && !row.id
      && row.module_status_id === target.module_status_id
      && row.status_at === target.status_at
    ) {
      return { ...row, status_at: iso }
    }
    return row
  })
}

/** Drop unpersisted rows and append a new change for the selected status */
export function appendStatusChange(
  history: TaskStatusHistoryInput[],
  moduleStatusId: string,
  dateTimeInput?: string
): TaskStatusHistoryInput[] {
  const persisted = history.filter(row => row.id)
  const iso = dateTimeLocalInputToIso(dateTimeInput ?? nowDateTimeLocalInput())
  if (!iso) return persisted
  return [...persisted, { module_status_id: moduleStatusId, status_at: iso }]
}

export function initialStatusHistoryEntry(
  moduleStatusId: string,
  dateTimeInput?: string
): TaskStatusHistoryInput[] {
  const iso = dateTimeLocalInputToIso(dateTimeInput ?? nowDateTimeLocalInput())
  if (!iso) return []
  return [{ module_status_id: moduleStatusId, status_at: iso }]
}

function latestStatusChangeIso(
  history: TaskStatusHistoryInput[],
  moduleStatusId: string | null | undefined
): string | null {
  if (!moduleStatusId) return null
  const latest = sortStatusHistoryEntries(
    history.filter(row => row.module_status_id === moduleStatusId)
  ).at(-1)
  return latest?.status_at ?? null
}

function normalizeStatusHistoryPayload(
  history: TaskStatusHistoryInput[]
): TaskStatusHistoryInput[] {
  return history
    .filter(row => row.id)
    .map((entry) => {
      const iso = entry.status_at.includes('T')
        ? entry.status_at
        : dateTimeLocalInputToIso(isoToDateTimeLocalInput(entry.status_at))
          ?? dateInputToIso(isoToDateInput(entry.status_at))
      if (!iso) return null
      return { id: entry.id, module_status_id: entry.module_status_id, status_at: iso }
    })
    .filter((entry): entry is TaskStatusHistoryInput => entry !== null)
}

function resolveTaskAssignTarget(form: TaskFormInput) {
  if (form.sales_team_id) {
    return { sales_team_id: form.sales_team_id, assigned_to: null as string | null }
  }
  return { sales_team_id: null as string | null, assigned_to: form.assigned_to }
}

export function formToTaskPayload(form: TaskFormInput) {
  const assignTarget = resolveTaskAssignTarget(form)
  return {
    subject: form.subject.trim(),
    task_type: form.task_type,
    module_status_id: form.module_status_id,
    priority: form.priority,
    start_at: dateInputToIso(form.start_at),
    end_at: dateInputToIso(form.end_at),
    assigned_by: form.assigned_by,
    assigned_to: assignTarget.assigned_to,
    sales_team_id: assignTarget.sales_team_id,
    company_id: form.company_id,
    contact_id: form.contact_id,
    description: form.description.trim() || null,
    status_changed_at: latestStatusChangeIso(form.status_history, form.module_status_id)
      ?? dateTimeLocalInputToIso(nowDateTimeLocalInput()),
    status_history: normalizeStatusHistoryPayload(form.status_history)
  }
}

/** Calendar index — group tasks by start date only */
export function groupTasksByStartDate(tasks: Task[]): Map<string, Task[]> {
  const map = new Map<string, Task[]>()
  for (const task of tasks) {
    if (!task.start_at) continue
    const key = task.start_at.slice(0, 10)
    const list = map.get(key) ?? []
    list.push(task)
    map.set(key, list)
  }
  for (const list of map.values()) {
    list.sort((a, b) => a.subject.localeCompare(b.subject, 'th') || a.task_code.localeCompare(b.task_code))
  }
  return map
}

/** @deprecated Calendar uses start date only — see groupTasksByStartDate */
export function taskCalendarDateKeys(task: Pick<Task, 'start_at' | 'end_at'>): string[] {
  const keys = new Set<string>()
  if (task.start_at) keys.add(task.start_at.slice(0, 10))
  if (task.end_at) keys.add(task.end_at.slice(0, 10))
  return [...keys]
}

export function formatTaskScheduleShort(
  task: Pick<Task, 'start_at' | 'end_at'>,
  formatDate: (value: string | null | undefined) => string
): string | null {
  const start = task.start_at ? formatDate(task.start_at) : null
  const end = task.end_at ? formatDate(task.end_at) : null
  if (start && end) return start === end ? start : `${start} – ${end}`
  return start ?? end
}

export function taskScheduleDateKey(
  task: Pick<Task, 'start_at' | 'created_at'>,
  useCreatedFallback = true
): string | null {
  const source = task.start_at ?? (useCreatedFallback ? task.created_at : null)
  if (!source) return null
  return source.slice(0, 10)
}

export function currentMonthDateRange(base = new Date()): { from: string, to: string } {
  const year = base.getFullYear()
  const month = base.getMonth()
  const monthPart = String(month + 1).padStart(2, '0')
  const lastDay = new Date(year, month + 1, 0).getDate()
  return {
    from: `${year}-${monthPart}-01`,
    to: `${year}-${monthPart}-${String(lastDay).padStart(2, '0')}`
  }
}

export interface TaskDateRangeFilter {
  from: string
  to: string
}

export function taskMatchesDateRange(
  task: Task,
  range: TaskDateRangeFilter
): boolean {
  const key = taskScheduleDateKey(task)
  const from = range.from.trim()
  const to = range.to.trim()
  const hasFilter = Boolean(from || to)

  if (!key) return !hasFilter
  if (from && key < from) return false
  if (to && key > to) return false
  return true
}

export function taskDisplayName(task: Pick<Task, 'subject' | 'task_code'>) {
  return task.subject.trim() || task.task_code
}

/** Assignee column — person OR sales team (mutually exclusive) */
export function taskAssigneeDisplayName(
  task: Pick<Task, 'assigned_to_name' | 'sales_team_name'>,
  emptyLabel: string
) {
  return task.assigned_to_name?.trim() || task.sales_team_name?.trim() || emptyLabel
}
