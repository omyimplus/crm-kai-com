<script setup lang="ts">
import type { ModuleStatus, TaskStatusHistoryInput } from '~/types/crm'
import {
  appFormFieldClass,
  appFormHintClass,
  appInputUi
} from '~/config/appFormUi'
import {
  isoToDateTimeLocalInput,
  resolveModuleStatusById,
  sortStatusHistoryEntries,
  upsertStatusHistoryAt
} from '~/utils/masterTasks'
import { useTaskStatusLabel } from '~/composables/useTaskStatusLabel'

const props = defineProps<{
  statuses: ModuleStatus[]
}>()

const history = defineModel<TaskStatusHistoryInput[]>('history', { required: true })

const { t } = useI18n()
const { formatDateTime } = useFormat()
const { profile } = useProfile()
const { taskStatusLabel, moduleStatusLabel } = useTaskStatusLabel()

const entries = computed(() => sortStatusHistoryEntries(history.value))

function entryLabel(entry: TaskStatusHistoryInput) {
  const status = resolveModuleStatusById(props.statuses, entry.module_status_id)
  if (status) return moduleStatusLabel(status)
  if (entry.status_code) return taskStatusLabel(entry.status_code, entry.status_name)
  return entry.status_name ?? entry.module_status_id
}

function entryColor(entry: TaskStatusHistoryInput) {
  const status = resolveModuleStatusById(props.statuses, entry.module_status_id)
  return status?.color ?? entry.status_color ?? '#64748b'
}

function entryDateTimeInput(entry: TaskStatusHistoryInput): string {
  return isoToDateTimeLocalInput(entry.status_at)
}

function onDateTimeChange(entry: TaskStatusHistoryInput, value: string) {
  history.value = upsertStatusHistoryAt(history.value, entry, value)
}

function entryChangedByName(entry: TaskStatusHistoryInput): string | null {
  const saved = entry.changed_by_name?.trim()
  if (saved) return saved
  if (!entry.id) {
    return profile.value?.full_name?.trim()
      || profile.value?.username?.trim()
      || null
  }
  return null
}
</script>

<template>
  <div
    v-if="entries.length"
    class="space-y-3"
    role="list"
    :aria-label="t('tasks.statusChangeLog.listLabel')"
  >
    <div
      v-for="(entry, index) in entries"
      :key="entry.id ?? `${entry.module_status_id}-${index}`"
      role="listitem"
      class="flex flex-col gap-2 rounded-xl border border-gray-200 bg-white p-3 sm:flex-row sm:items-start sm:gap-4 dark:border-gray-700 dark:bg-gray-900/40"
    >
      <div class="min-w-0 flex-1 pt-1">
        <div class="flex items-center gap-2">
          <span
            class="inline-flex size-2.5 shrink-0 rounded-full"
            :style="{ backgroundColor: entryColor(entry) }"
            aria-hidden="true"
          />
          <span class="truncate text-sm font-medium text-gray-900 dark:text-gray-100">
            {{ entryLabel(entry) }}
          </span>
        </div>
        <p class="mt-1 ms-4 text-xs text-gray-500 dark:text-gray-400">
          {{ formatDateTime(entry.status_at) }}
          <template v-if="entryChangedByName(entry)">
            · {{ t('tasks.statusChangeLog.changedBy', { name: entryChangedByName(entry) }) }}
          </template>
        </p>
      </div>

      <UFormField
        :label="t('tasks.fields.statusChangedAt')"
        class="mb-0 w-full sm:w-56"
        :ui="{ label: 'text-xs text-gray-500 dark:text-gray-400' }"
      >
        <UInput
          :model-value="entryDateTimeInput(entry)"
          type="datetime-local"
          size="md"
          :class="appFormFieldClass"
          :ui="appInputUi"
          :aria-label="t('tasks.statusChangeLog.dateTimeFor', { status: entryLabel(entry) })"
          @update:model-value="onDateTimeChange(entry, String($event ?? ''))"
        />
      </UFormField>
    </div>
  </div>

  <p
    v-else
    :class="appFormHintClass"
  >
    {{ t('tasks.statusChangeLog.empty') }}
  </p>
</template>
