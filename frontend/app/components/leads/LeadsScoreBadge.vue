<script setup lang="ts">
import { LEAD_SCORE_MAX } from '~/config/masterLeads'
import { leadScoreRingMetrics } from '~/utils/masterLeads'

const props = defineProps<{
  score: number
  size?: 'sm' | 'md'
}>()

const metrics = computed(() => leadScoreRingMetrics(props.score))

const boxClass = computed(() =>
  props.size === 'sm' ? 'size-8 text-[10px]' : 'size-10 text-xs'
)
</script>

<template>
  <span
    class="relative inline-flex shrink-0 items-center justify-center"
    :class="boxClass"
    :title="`${metrics.score}/${LEAD_SCORE_MAX}`"
  >
    <svg
      class="absolute inset-0 -rotate-90"
      viewBox="0 0 36 36"
      aria-hidden="true"
    >
      <circle
        cx="18"
        cy="18"
        r="16"
        fill="none"
        class="stroke-gray-200 dark:stroke-gray-700"
        stroke-width="3"
      />
      <circle
        cx="18"
        cy="18"
        r="16"
        fill="none"
        :stroke="metrics.color"
        stroke-width="3"
        stroke-linecap="round"
        :stroke-dasharray="metrics.circumference"
        :stroke-dashoffset="metrics.dashOffset"
        class="transition-[stroke-dashoffset] duration-300 ease-out"
      />
    </svg>
    <span
      class="relative font-bold tabular-nums leading-none"
      :class="metrics.score >= 80
        ? 'text-emerald-700 dark:text-emerald-300'
        : metrics.score >= 40
          ? 'text-orange-700 dark:text-orange-300'
          : 'text-red-700 dark:text-red-300'"
    >
      {{ metrics.score }}
    </span>
  </span>
</template>
