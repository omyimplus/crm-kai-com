<script setup lang="ts">
import type { TaskType } from '~/config/masterTasks'
import { TASK_TYPE_ICONS } from '~/config/masterTasks'
import { appTableRowClass, appTableTextClass } from '~/config/appFormUi'
import { taskTypeTintStyle } from '~/utils/masterTasks'

const props = defineProps<{
  type: TaskType
  showIcon?: boolean
  rowStyle?: boolean
}>()

const { t } = useI18n()

const textClass = computed(() => props.rowStyle ? appTableRowClass : appTableTextClass)
</script>

<template>
  <UBadge
    variant="subtle"
    size="sm"
    :class="[textClass, 'inline-flex max-w-full items-center gap-1 truncate']"
    :style="taskTypeTintStyle(type)"
  >
    <UIcon
      v-if="showIcon"
      :name="TASK_TYPE_ICONS[type]"
      class="size-3.5 shrink-0"
    />
    {{ t(`tasks.options.type.${type}`) }}
  </UBadge>
</template>
