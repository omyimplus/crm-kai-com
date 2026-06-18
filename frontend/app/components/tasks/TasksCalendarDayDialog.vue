<script setup lang="ts">
import type { Task } from '~/types/crm'
import { appTableBadgeClass, appTableTextClass } from '~/config/appFormUi'
import { taskDisplayName } from '~/utils/masterTasks'
import { useTaskStatusLabel } from '~/composables/useTaskStatusLabel'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  dateKey: string | null
  tasks: Task[]
}>()

const emit = defineEmits<{ select: [task: Task] }>()

const { t } = useI18n()
const { formatDate } = useFormat()
const { taskStatusLabel } = useTaskStatusLabel()

const dialogTitle = computed(() => {
  if (!props.dateKey) return t('tasks.calendar.dayTitleFallback')
  return t('tasks.calendar.dayTitle', {
    date: formatDate(`${props.dateKey}T00:00:00.000Z`)
  })
})

function endDateLabel(task: Task) {
  return task.end_at ? formatDate(task.end_at) : t('tasks.emptyCell')
}

function onSelect(task: Task) {
  open.value = false
  emit('select', task)
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="dialogTitle"
    :description="t('tasks.calendar.dayHint')"
    size="lg"
  >
    <ul
      v-if="tasks.length"
      class="divide-y divide-gray-200 dark:divide-gray-800"
    >
      <li
        v-for="task in tasks"
        :key="task.id"
      >
        <button
          type="button"
          class="flex w-full gap-3 px-1 py-3 text-start transition-colors hover:bg-gray-50 dark:hover:bg-gray-900/50"
          @click="onSelect(task)"
        >
          <TasksTypeIcon
            :type="task.task_type"
            size="sm"
          />

          <span class="min-w-0 flex-1">
            <span class="block font-semibold text-gray-900 dark:text-gray-100">
              {{ taskDisplayName(task) }}
            </span>
            <span class="mt-1 flex flex-wrap items-center gap-2">
              <TasksTypeBadge
                :type="task.task_type"
                show-icon
              />
              <span class="font-mono text-[11px] text-gray-500 dark:text-gray-400">
                {{ task.task_code }}
              </span>
            </span>
            <span
              class="mt-2 flex flex-wrap items-center gap-2 text-sm"
              :class="appTableTextClass"
            >
              <UBadge
                variant="subtle"
                size="sm"
                :class="appTableBadgeClass"
                :style="task.status_color ? { backgroundColor: `${task.status_color}22`, color: task.status_color } : undefined"
              >
                {{ taskStatusLabel(task.status_code, task.status_name) }}
              </UBadge>
              <span class="text-gray-500 dark:text-gray-400">
                {{ t('tasks.columns.endDate') }}:
                <span class="text-gray-900 dark:text-gray-100">{{ endDateLabel(task) }}</span>
              </span>
            </span>
          </span>

          <UIcon
            name="i-lucide-chevron-right"
            class="mt-2 size-4 shrink-0 text-gray-400"
          />
        </button>
      </li>
    </ul>

    <p
      v-else
      class="text-sm text-gray-500 dark:text-gray-400"
    >
      {{ t('tasks.calendar.dayEmpty') }}
    </p>
  </AppDialog>
</template>
