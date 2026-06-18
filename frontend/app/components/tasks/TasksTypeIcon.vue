<script setup lang="ts">
import type { TaskType } from '~/config/masterTasks'
import { TASK_TYPE_ICONS } from '~/config/masterTasks'
import { taskTypeTintStyle } from '~/utils/masterTasks'

withDefaults(defineProps<{
  type: TaskType
  size?: 'sm' | 'md'
}>(), {
  size: 'md'
})
</script>

<template>
  <span
    class="inline-flex shrink-0 items-center justify-center rounded-lg"
    :class="size === 'sm' ? 'size-8' : 'size-9'"
    :style="taskTypeTintStyle(type)"
  >
    <UIcon
      :name="TASK_TYPE_ICONS[type]"
      class="size-4"
    />
  </span>
</template>
