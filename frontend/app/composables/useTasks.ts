import type { Task, TaskAssignee, TaskFormInput, TaskStatusHistoryEntry } from '~/types/crm'
import { formToTaskPayload } from '~/utils/masterTasks'

export function useTasks() {
  const supabase = useSupabaseClient()

  async function list(statusCode?: string | null) {
    const { data, error } = await supabase.rpc('list_tasks', {
      p_status_code: statusCode ?? null
    })
    if (error) throw error
    return (data ?? []) as Task[]
  }

  async function listStatusHistory(taskId: string) {
    const { data, error } = await supabase.rpc('list_task_status_history', {
      p_task_id: taskId
    })
    if (error) throw error
    return (data ?? []) as TaskStatusHistoryEntry[]
  }

  async function create(form: TaskFormInput) {
    const { data: id, error } = await supabase.rpc('create_task', {
      p_payload: formToTaskPayload(form)
    })
    if (error) throw error
    const rows = await list()
    const created = rows.find(row => row.id === String(id))
    if (!created) throw new Error('Task not found after create')
    return created
  }

  async function update(id: string, form: TaskFormInput) {
    const { error } = await supabase.rpc('update_task', {
      p_task_id: id,
      p_payload: formToTaskPayload(form)
    })
    if (error) throw error
    const rows = await list()
    const updated = rows.find(row => row.id === id)
    if (!updated) throw new Error('Task not found after update')
    return updated
  }

  async function remove(id: string) {
    const { error } = await supabase.rpc('soft_delete_task', {
      p_task_id: id
    })
    if (error) throw error
  }

  async function listAssignees() {
    const { data, error } = await supabase.rpc('list_org_assignees')
    if (error) throw error
    return (data ?? []) as TaskAssignee[]
  }

  /** Lazy seed OPEN / IN_PROGRESS / COMPLETED / CANCELLED + job code sequence for task module */
  async function ensureDefaults() {
    const { error } = await supabase.rpc('ensure_task_module_defaults')
    if (error) throw error
  }

  return { list, listStatusHistory, create, update, remove, listAssignees, ensureDefaults }
}
