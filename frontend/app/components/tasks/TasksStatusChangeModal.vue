<script setup lang="ts">
import type { ModuleStatus, Task, TaskStatusHistoryInput } from '~/types/crm'
import {
  appFormErrorClass,
  appFormFieldClass,
  appFormHintClass,
  appSelectMenuUi
} from '~/config/appFormUi'
import {
  appendStatusChange,
  defaultTaskFormInput,
  statusHistoryEntriesToFormInput,
  taskDisplayName,
  taskFormModuleStatuses,
  taskToFormInput
} from '~/utils/masterTasks'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'
import { useTaskStatusLabel } from '~/composables/useTaskStatusLabel'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  task: Task | null
  statuses: ModuleStatus[]
}>()

const emit = defineEmits<{ saved: [] }>()

const { t } = useI18n()
const { update, listStatusHistory } = useTasks()
const { moduleStatusLabel, taskStatusLabel } = useTaskStatusLabel()

const saving = ref(false)
const errorMsg = ref('')
const historyLoading = ref(false)
const form = ref(defaultTaskFormInput())
const statusHistory = ref<TaskStatusHistoryInput[]>([])
const initialStatusId = ref<string | null>(null)

const statusOptions = computed(() => {
  if (!props.task) return []
  return taskFormModuleStatuses(props.statuses, props.task.module_status_id).map(row => ({
    label: moduleStatusLabel(row),
    value: row.id
  }))
})

const hasStatusOptions = computed(() => statusOptions.value.length > 0)

const canSave = computed(() => {
  if (!props.task || !form.value.module_status_id) return false
  if (form.value.module_status_id !== initialStatusId.value) return true
  return statusHistory.value.some(row => !row.id)
})

async function loadStatusHistory() {
  if (!props.task) return
  historyLoading.value = true
  try {
    const rows = await listStatusHistory(props.task.id)
    statusHistory.value = statusHistoryEntriesToFormInput(rows)
  } catch (error) {
    console.error(error)
    statusHistory.value = []
  } finally {
    historyLoading.value = false
  }
}

function resetForm() {
  if (!props.task) return
  form.value = taskToFormInput(props.task)
  initialStatusId.value = props.task.module_status_id
  statusHistory.value = []
  errorMsg.value = ''
  void loadStatusHistory()
}

watch(() => form.value.module_status_id, (statusId, prev) => {
  if (!statusId || !prev || statusId === prev) return
  statusHistory.value = appendStatusChange(statusHistory.value, statusId)
})

watch(open, (isOpen) => {
  if (isOpen) resetForm()
})

async function onSubmit() {
  if (!props.task || !canSave.value) return
  errorMsg.value = ''
  saving.value = true
  try {
    await update(props.task.id, {
      ...form.value,
      status_history: statusHistory.value
    })
    open.value = false
    emit('saved')
  } catch (error) {
    errorMsg.value = getSupabaseErrorMessage(error, t('tasks.errors.saveFailed'))
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="t('tasks.changeStatus.title')"
    :description="t('tasks.changeStatus.subtitle')"
    size="lg"
  >
    <form
      id="tasks-status-form"
      class="space-y-5"
      @submit.prevent="onSubmit"
    >
      <p
        v-if="errorMsg"
        :class="appFormErrorClass"
        role="alert"
      >
        {{ errorMsg }}
      </p>

      <div
        v-if="task"
        class="rounded-xl border border-gray-200 bg-gray-50/60 px-4 py-3 dark:border-gray-800 dark:bg-gray-900/30"
      >
        <p class="font-semibold text-gray-900 dark:text-gray-100">
          {{ taskDisplayName(task) }}
        </p>
        <p class="mt-1 font-mono text-xs text-gray-500 dark:text-gray-400">
          {{ task.task_code }}
        </p>
        <p class="mt-2 text-sm text-gray-600 dark:text-gray-400">
          {{ t('tasks.changeStatus.currentStatus') }}:
          <span class="font-medium text-gray-900 dark:text-gray-100">
            {{ taskStatusLabel(task.status_code, task.status_name) }}
          </span>
        </p>
      </div>

      <UFormField
        :label="t('tasks.fields.status')"
        required
      >
        <USelectMenu
          v-if="hasStatusOptions"
          v-model="form.module_status_id"
          size="lg"
          :items="statusOptions"
          value-key="value"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
        />
        <p
          v-else
          :class="appFormHintClass"
        >
          {{ t('tasks.statusesMissing') }}
        </p>
      </UFormField>

      <div
        v-if="form.module_status_id"
        class="rounded-xl border border-gray-200 p-4 dark:border-gray-800"
      >
        <div class="mb-3">
          <h3 class="text-sm font-semibold font-heading text-gray-900 dark:text-gray-100">
            {{ t('tasks.statusChangeLog.title') }}
          </h3>
          <p :class="appFormHintClass">
            {{ t('tasks.statusChangeLog.hint') }}
          </p>
        </div>

        <div
          v-if="historyLoading"
          class="py-4 text-sm text-gray-500 dark:text-gray-400"
        >
          {{ t('common.loading') }}
        </div>
        <TasksStatusChangeLog
          v-else
          v-model:history="statusHistory"
          :statuses="statuses"
        />
      </div>
    </form>

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          class="w-full sm:w-auto"
          type="submit"
          form="tasks-status-form"
          color="primary"
          size="lg"
          :loading="saving"
          :disabled="!canSave"
        >
          {{ t('tasks.changeStatus.save') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
