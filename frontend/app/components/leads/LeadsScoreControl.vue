<script setup lang="ts">
import {
  LEAD_HOT_SCORE_MIN,
  LEAD_SCORE_MAX,
  LEAD_SCORE_QUICK_PRESETS,
  LEAD_SCORE_TIER_ORDER,
  LEAD_WARM_SCORE_MIN,
  leadScoreTierThemes
} from '~/config/masterLeads'
import { leadScoreRingMetrics, leadScoreTier } from '~/utils/masterLeads'

const score = defineModel<number>({ required: true })

defineProps<{
  readonly?: boolean
}>()

const { t } = useI18n()

const metrics = computed(() => leadScoreRingMetrics(score.value))
const tierTheme = computed(() => leadScoreTierThemes[metrics.value.tier])

const quickScores = LEAD_SCORE_QUICK_PRESETS

const scaleMarks = [0, 25, 50, 75, LEAD_SCORE_MAX] as const

const tierLegend = computed(() =>
  LEAD_SCORE_TIER_ORDER.map(tier => ({
    tier,
    theme: leadScoreTierThemes[tier],
    range:
      tier === 'hot'
        ? `${LEAD_HOT_SCORE_MIN}–${LEAD_SCORE_MAX}`
        : tier === 'warm'
          ? `${LEAD_WARM_SCORE_MIN}–${LEAD_HOT_SCORE_MIN - 1}`
          : `0–${LEAD_WARM_SCORE_MIN - 1}`
  }))
)

function setScore(value: number) {
  score.value = Math.min(LEAD_SCORE_MAX, Math.max(0, value))
}
</script>

<template>
  <div
    class="rounded-xl border border-gray-200 bg-gradient-to-br from-white to-gray-50/80 p-4 dark:border-gray-800 dark:from-gray-900/60 dark:to-gray-900/30 sm:p-5"
  >
    <div class="flex flex-col gap-5 sm:flex-row sm:items-center">
      <div
        class="mx-auto flex shrink-0 flex-col items-center rounded-2xl px-4 py-3 sm:mx-0"
        :class="tierTheme.softBg"
      >
        <div class="relative size-24">
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
              class="stroke-gray-200/80 dark:stroke-gray-700"
              stroke-width="2.5"
            />
            <circle
              cx="18"
              cy="18"
              r="16"
              fill="none"
              :stroke="metrics.color"
              stroke-width="2.5"
              stroke-linecap="round"
              :stroke-dasharray="metrics.circumference"
              :stroke-dashoffset="metrics.dashOffset"
              class="transition-[stroke-dashoffset] duration-300 ease-out"
            />
          </svg>
          <div class="absolute inset-0 flex flex-col items-center justify-center">
            <span
              class="text-3xl font-bold tabular-nums leading-none"
              :class="tierTheme.softText"
            >
              {{ metrics.score }}
            </span>
            <span class="mt-0.5 text-[10px] font-medium uppercase tracking-wide text-gray-500 dark:text-gray-400">
              / {{ LEAD_SCORE_MAX }}
            </span>
          </div>
        </div>
        <UBadge
          :color="tierTheme.badge"
          variant="subtle"
          size="sm"
          class="mt-2"
        >
          {{ t(`leads.options.scoreTier.${metrics.tier}`) }}
        </UBadge>
      </div>

      <div class="min-w-0 flex-1 space-y-4">
        <div>
          <p class="text-sm font-semibold text-gray-900 dark:text-gray-100">
            {{ t('leads.fields.leadScore') }}
          </p>
          <p class="mt-0.5 text-xs text-gray-500 dark:text-gray-400">
            {{ t('leads.fields.leadScoreHint') }}
          </p>
        </div>

        <input
          v-model.number="score"
          type="range"
          min="0"
          :max="LEAD_SCORE_MAX"
          step="1"
          :disabled="readonly"
          class="leads-score-slider w-full"
          :aria-valuenow="metrics.score"
          aria-valuemin="0"
          :aria-valuemax="LEAD_SCORE_MAX"
          :aria-label="t('leads.fields.leadScore')"
        >

        <div class="flex justify-between text-[11px] tabular-nums text-gray-400 dark:text-gray-500">
          <span
            v-for="mark in scaleMarks"
            :key="mark"
          >{{ mark }}</span>
        </div>

        <div
          v-if="!readonly"
          class="flex flex-wrap gap-2"
        >
          <UButton
            v-for="value in quickScores"
            :key="value"
            type="button"
            size="xs"
            :color="leadScoreTier(value) === metrics.tier ? tierTheme.badge : 'neutral'"
            :variant="score === value ? 'solid' : 'outline'"
            class="tabular-nums"
            @click="setScore(value)"
          >
            {{ value }}
          </UButton>
        </div>
      </div>
    </div>

    <div class="mt-4 grid grid-cols-3 gap-2 border-t border-gray-200 pt-4 dark:border-gray-800">
      <div
        v-for="item in tierLegend"
        :key="item.tier"
        class="rounded-lg px-2 py-1.5 text-center"
        :class="[
          item.theme.softBg,
          metrics.tier === item.tier ? 'ring-1 ring-inset ring-gray-300 dark:ring-gray-600' : ''
        ]"
      >
        <p
          class="text-[11px] font-semibold"
          :class="item.theme.softText"
        >
          {{ t(`leads.options.scoreTier.${item.tier}`) }}
        </p>
        <p class="text-[10px] tabular-nums text-gray-500 dark:text-gray-400">
          {{ item.range }}
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.leads-score-slider {
  -webkit-appearance: none;
  appearance: none;
  height: 0.5rem;
  border-radius: 9999px;
  background: linear-gradient(
    to right,
    #ef4444 0%,
    #ef4444 39%,
    #f97316 40%,
    #f97316 79%,
    #22c55e 80%,
    #22c55e 100%
  );
  cursor: pointer;
}

.leads-score-slider:disabled {
  cursor: not-allowed;
  opacity: 0.55;
}

.leads-score-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 1.125rem;
  height: 1.125rem;
  border-radius: 9999px;
  border: 2px solid #fff;
  background: #111827;
  box-shadow: 0 1px 3px rgb(0 0 0 / 0.25);
}

.leads-score-slider::-moz-range-thumb {
  width: 1.125rem;
  height: 1.125rem;
  border-radius: 9999px;
  border: 2px solid #fff;
  background: #111827;
  box-shadow: 0 1px 3px rgb(0 0 0 / 0.25);
}

:global(.dark) .leads-score-slider::-webkit-slider-thumb,
:global(.dark) .leads-score-slider::-moz-range-thumb {
  border-color: #374151;
  background: #f9fafb;
}
</style>
