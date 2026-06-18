<script setup lang="ts">
import type { LeadPriority } from '~/config/masterLeads'
import { leadPrioritySolidStyle } from '~/utils/masterLeads'

defineProps<{
  priority: LeadPriority
  compact?: boolean
}>()

const { t } = useI18n()
</script>

<template>
  <span
    role="status"
    class="inline-flex max-w-full items-center justify-center truncate rounded-md font-semibold leading-tight text-white shadow-sm"
    :class="compact
      ? 'min-w-0 px-1.5 py-0.5 text-[10px]'
      : 'min-w-[4.25rem] px-2.5 py-1 text-xs'"
    :style="leadPrioritySolidStyle(priority)"
  >
    {{ t(`leads.options.priority.${priority}`) }}
  </span>
</template>
