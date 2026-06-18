<script setup lang="ts">
import type { Opportunity } from '~/types/crm'
import { computeOpportunitySummary } from '~/utils/masterOpportunities'
import type { OpportunityDateRangeFilter } from '~/utils/masterOpportunities'

const props = defineProps<{
  opportunities: Opportunity[]
  wonDateRange: OpportunityDateRangeFilter
  filtered?: boolean
}>()

const { t } = useI18n()
const { formatCurrency } = useFormat()

const summary = computed(() =>
  computeOpportunitySummary(props.opportunities, props.wonDateRange)
)

const cards = computed(() => [
  {
    key: 'pipeline',
    label: props.filtered
      ? t('opportunities.summary.pipelineFiltered')
      : t('opportunities.summary.pipeline'),
    value: formatCurrency(summary.value.pipelineValue),
    icon: 'i-lucide-trending-up',
    iconClass: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300'
  },
  {
    key: 'won',
    label: t('opportunities.summary.wonPeriod'),
    value: formatCurrency(summary.value.wonValue),
    icon: 'i-lucide-circle-dollar-sign',
    iconClass: 'bg-green-100 text-green-700 dark:bg-green-950/60 dark:text-green-300'
  },
  {
    key: 'open',
    label: t('opportunities.summary.open'),
    value: String(summary.value.openCount),
    icon: 'i-lucide-lightbulb',
    iconClass: 'bg-sky-100 text-sky-700 dark:bg-sky-950/60 dark:text-sky-300'
  }
])
</script>

<template>
  <div class="grid gap-3 sm:grid-cols-3">
    <div
      v-for="card in cards"
      :key="card.key"
      class="rounded-2xl border border-gray-200 bg-white px-4 py-4 dark:border-gray-800 dark:bg-gray-900"
    >
      <div class="flex items-center gap-3">
        <span
          class="inline-flex size-10 shrink-0 items-center justify-center rounded-xl"
          :class="card.iconClass"
        >
          <UIcon
            :name="card.icon"
            class="size-5"
          />
        </span>
        <div class="min-w-0">
          <p class="truncate text-sm text-gray-500 dark:text-gray-400">
            {{ card.label }}
          </p>
          <p class="text-2xl font-semibold text-gray-900 dark:text-gray-100">
            {{ card.value }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
