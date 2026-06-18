<script setup lang="ts">
import type { Contact, Task } from '~/types/crm'
import { appTableBadgeClass, appTableCellLinkClass, appTableTextClass } from '~/config/appFormUi'
import { taskAssigneeDisplayName, taskContactPhone, taskDisplayName } from '~/utils/masterTasks'
import { useTaskStatusLabel } from '~/composables/useTaskStatusLabel'

const props = defineProps<{
  task: Task
  contacts: Contact[]
  canWrite: boolean
}>()

const emit = defineEmits<{
  edit: [task: Task]
  delete: [task: Task]
  customer: [task: Task]
  statusChange: [task: Task]
}>()

const { t } = useI18n()
const { taskStatusLabel } = useTaskStatusLabel()
const { formatDate } = useFormat()

const contactPhone = computed(() => taskContactPhone(props.task, props.contacts))
</script>

<template>
  <article
    class="flex cursor-pointer flex-col overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm transition-shadow hover:shadow-md dark:border-gray-800 dark:bg-gray-900"
    @click="emit('edit', task)"
  >
    <div
      class="h-1"
      :style="{ backgroundColor: task.status_color ?? '#94a3b8' }"
    />

    <div class="flex flex-1 flex-col p-4">
      <div class="mb-3 flex items-start justify-between gap-2">
        <TasksTypeIcon :type="task.task_type" />

        <div class="flex flex-col items-end gap-1.5">
          <TasksTypeBadge :type="task.task_type" />
          <UBadge
            variant="subtle"
            size="sm"
            :class="appTableBadgeClass"
            :style="task.status_color ? { backgroundColor: `${task.status_color}22`, color: task.status_color } : undefined"
          >
            {{ taskStatusLabel(task.status_code, task.status_name) }}
          </UBadge>
        </div>
      </div>

      <h3 class="line-clamp-2 text-base font-semibold font-heading text-gray-900 dark:text-gray-100">
        {{ taskDisplayName(task) }}
      </h3>

      <p class="mt-1 font-mono text-[11px] text-gray-500 dark:text-gray-400">
        {{ task.task_code }}
      </p>

      <dl
        class="mt-3 space-y-1.5 text-gray-600 dark:text-gray-400"
        :class="appTableTextClass"
      >
        <div class="flex items-center justify-between gap-2">
          <dt>{{ t('tasks.columns.priority') }}</dt>
          <dd>
            <TasksPriorityBadge :priority="task.priority" />
          </dd>
        </div>
        <div class="flex items-start justify-between gap-2">
          <dt class="shrink-0">{{ t('tasks.columns.customer') }}</dt>
          <dd
            class="min-w-0 text-end"
            @click.stop
          >
            <TasksCustomerLink
              :company-id="task.company_id"
              :name="task.company_name"
              @open="emit('customer', task)"
            />
          </dd>
        </div>
        <div class="flex items-start justify-between gap-2">
          <dt class="shrink-0">{{ t('tasks.columns.contact') }}</dt>
          <dd class="min-w-0 text-end">
            <span
              v-if="task.contact_name"
              class="block truncate text-gray-900 dark:text-gray-100"
              :class="appTableTextClass"
            >
              {{ task.contact_name }}
            </span>
            <span
              v-else
              class="text-gray-400 dark:text-gray-500"
              :class="appTableTextClass"
            >
              {{ t('tasks.emptyCell') }}
            </span>
            <a
              v-if="contactPhone"
              :href="`tel:${contactPhone}`"
              class="mt-0.5 block truncate"
              :class="appTableCellLinkClass"
              @click.stop
            >
              {{ contactPhone }}
            </a>
          </dd>
        </div>
        <div class="flex items-start justify-between gap-2">
          <dt class="shrink-0">{{ t('tasks.columns.assignedBy') }}</dt>
          <dd
            class="truncate text-end text-gray-900 dark:text-gray-100"
            :class="appTableTextClass"
          >
            {{ task.assigned_by_name || t('tasks.emptyCell') }}
          </dd>
        </div>
        <div class="flex items-start justify-between gap-2">
          <dt class="shrink-0">{{ t('tasks.columns.assignedTo') }}</dt>
          <dd
            class="truncate text-end text-gray-900 dark:text-gray-100"
            :class="appTableTextClass"
          >
            {{ taskAssigneeDisplayName(task, t('tasks.emptyCell')) }}
          </dd>
        </div>
        <div
          v-if="task.start_at"
          class="flex items-center justify-between gap-2"
        >
          <dt>{{ t('tasks.fields.startDate') }}</dt>
          <dd class="text-gray-900 dark:text-gray-100">
            {{ formatDate(task.start_at) }}
          </dd>
        </div>
        <div
          v-if="task.end_at"
          class="flex items-center justify-between gap-2"
        >
          <dt>{{ t('tasks.fields.endDate') }}</dt>
          <dd class="text-gray-900 dark:text-gray-100">
            {{ formatDate(task.end_at) }}
          </dd>
        </div>
      </dl>

      <div
        class="mt-4 flex items-center justify-end gap-1.5 border-t border-gray-100 pt-3 dark:border-gray-800"
        @click.stop
      >
        <AppIconButton
          v-if="canWrite"
          icon="i-lucide-arrow-left-right"
          color="primary"
          :aria-label="t('tasks.changeStatus.action')"
          @click="emit('statusChange', task)"
        />
        <AppIconButton
          v-if="canWrite"
          icon="i-lucide-pencil"
          :aria-label="t('common.edit')"
          @click="emit('edit', task)"
        />
        <AppIconButton
          v-if="canWrite"
          icon="i-lucide-trash-2"
          color="error"
          :aria-label="t('common.delete')"
          @click="emit('delete', task)"
        />
      </div>
    </div>
  </article>
</template>
