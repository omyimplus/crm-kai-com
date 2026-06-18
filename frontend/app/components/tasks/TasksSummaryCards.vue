<script setup lang="ts">
import type { ModuleStatus, Task } from '~/types/crm'
import { getActiveModuleStatuses } from '~/utils/masterTasks'
import { useTaskStatusLabel } from '~/composables/useTaskStatusLabel'

const props = defineProps<{
  tasks: Task[]
  statuses: ModuleStatus[]
  activeStatus: string
}>()

const emit = defineEmits<{
  select: [statusCode: string]
}>()

const { t } = useI18n()
const { taskStatusLabel } = useTaskStatusLabel()

const cards = computed(() =>
  getActiveModuleStatuses(props.statuses).map((row) => {
    const code = row.status_code
    const count = props.tasks.filter(task => task.status_code === code).length
    return {
      code,
      label: taskStatusLabel(code, row.name),
      color: row.color ?? '#94a3b8',
      count
    }
  })
)

function isActive(code: string) {
  return props.activeStatus === code
}
</script>

<template>
  <div
    v-if="cards.length"
    class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
    role="tablist"
    :aria-label="t('tasks.filters.statusTabs')"
  >
    <button
      v-for="card in cards"
      :key="card.code"
      type="button"
      role="tab"
      :aria-selected="isActive(card.code)"
      class="rounded-2xl border bg-white px-4 py-4 text-start transition-all dark:bg-gray-900"
      :class="isActive(card.code)
        ? 'border-menu-section ring-2 ring-menu-section/30 shadow-sm dark:border-primary dark:ring-primary/30'
        : 'border-gray-200 hover:border-gray-300 hover:shadow-sm dark:border-gray-800 dark:hover:border-gray-700'"
      @click="emit('select', card.code)"
    >
      <div class="flex items-center gap-3">
        <span
          class="inline-flex size-10 shrink-0 items-center justify-center rounded-xl text-white"
          :style="{ backgroundColor: card.color }"
        >
          <UIcon
            name="i-lucide-clipboard-list"
            class="size-5"
          />
        </span>
        <div class="min-w-0">
          <p class="truncate text-sm text-gray-500 dark:text-gray-400">
            {{ card.label }}
          </p>
          <p class="text-2xl font-semibold text-gray-900 dark:text-gray-100">
            {{ card.count }}
          </p>
        </div>
      </div>
    </button>
  </div>

  <UCard v-else>
    <p class="text-sm text-gray-600 dark:text-gray-300">
      {{ t('tasks.noActiveStatuses') }}
    </p>
    <UButton
      class="mt-3"
      variant="soft"
      size="sm"
      icon="i-lucide-list-tree"
      to="/app/module-status?module=task"
    >
      {{ t('tasks.openModuleStatuses') }}
    </UButton>
  </UCard>
</template>
