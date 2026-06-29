<script setup lang="ts">
import type { DashboardMockStatusTone } from '~/config/dashboardMock'

const props = withDefaults(defineProps<{
  tone?: DashboardMockStatusTone
}>(), {
  tone: 'emerald'
})

const toneClass: Record<DashboardMockStatusTone, string> = {
  emerald: 'bg-green-50 text-green-700 ring-green-200 dark:bg-green-950/40 dark:text-green-300 dark:ring-green-900/50',
  amber: 'bg-amber-50 text-amber-700 ring-amber-200 dark:bg-amber-950/40 dark:text-amber-300 dark:ring-amber-900/50',
  red: 'bg-red-50 text-red-700 ring-red-200 dark:bg-red-950/40 dark:text-red-300 dark:ring-red-900/50',
  blue: 'bg-blue-50 text-blue-700 ring-blue-200 dark:bg-blue-950/40 dark:text-blue-300 dark:ring-blue-900/50'
}
</script>

<template>
  <span
    class="inline-flex whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-semibold ring-1"
    :class="toneClass[props.tone]"
  >
    <slot />
  </span>
</template>
