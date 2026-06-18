<script setup lang="ts">
import type { TaskPriority } from '~/config/masterTasks'
import { taskPrioritySolidStyle } from '~/utils/masterTasks'

defineProps<{
  priority: TaskPriority
  rowStyle?: boolean
}>()

const { t } = useI18n()
</script>

<template>
  <span
    role="status"
    class="inline-flex min-w-[4.25rem] max-w-full items-center justify-center truncate rounded-md px-2.5 py-1 text-xs font-semibold leading-tight text-white shadow-sm"
    :style="taskPrioritySolidStyle(priority)"
  >
    {{ t(`tasks.options.priority.${priority}`) }}
  </span>
</template>
