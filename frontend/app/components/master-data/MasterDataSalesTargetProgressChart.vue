<script setup lang="ts">
import {
  APP_CHART_COLORS,
  formatChartAxisAmount
} from '~/config/appChart'
import type { AppChartSeries } from '~/config/appChart'
import type { MasterSalesTargetFormInput } from '~/utils/masterSalesTarget'
import { formatSalesAmount } from '~/utils/masterSalesTarget'
import {
  buildSalesTargetProgressChartModel,
  formatSalesTargetChartDate
} from '~/utils/salesTargetProgressChart'

const props = defineProps<{
  form: MasterSalesTargetFormInput
}>()

const { t, locale } = useI18n()

const model = computed(() => buildSalesTargetProgressChartModel(props.form, locale.value))

const hasDealCloses = computed(() => model.value.dealCloses.length > 0)

const chartSeries = computed<AppChartSeries[]>(() => [
  {
    key: 'cumulative',
    label: t('masterData.salesTarget.progressChart.legendCumulative'),
    color: APP_CHART_COLORS.primary
  },
  {
    key: 'target',
    label: t('masterData.salesTarget.progressChart.legendTarget'),
    color: APP_CHART_COLORS.target,
    dashed: true
  }
])

const yDomain = computed<[number, number]>(() => {
  const max = Math.max(model.value.targetAmount, model.value.currentAmount, 1)
  return [0, Math.ceil(max * 1.08)]
})

function formatDealDate(date: Date) {
  return formatSalesTargetChartDate(date, locale.value, props.form.period_type)
}
</script>

<template>
  <div class="mt-6 space-y-3">
    <div class="flex flex-wrap items-center justify-between gap-2">
      <p class="text-sm font-medium text-gray-700 dark:text-gray-200">
        {{ t('masterData.salesTarget.progressChart.title') }}
      </p>
      <p class="text-xs text-gray-500 dark:text-gray-400">
        {{ t('masterData.salesTarget.progressChart.simulatedHint') }}
      </p>
    </div>

    <div
      v-if="!hasDealCloses"
      class="rounded-xl border border-dashed border-gray-200 px-4 py-8 text-center text-sm text-gray-500 dark:border-gray-700 dark:text-gray-400"
    >
      {{ t('masterData.salesTarget.progressChart.empty') }}
    </div>

    <div v-else>
      <AppLineChart
        :data="model.chartRows"
        :series="chartSeries"
        :y-domain="yDomain"
        :aria-label="t('masterData.salesTarget.progressChart.title')"
        :x-formatter="(_tick, index) => model.chartRows[index ?? 0]?.dateLabel ?? ''"
        :y-formatter="tick => formatChartAxisAmount(tick, locale)"
      />

      <ul class="mt-4 space-y-1.5 border-t border-gray-200 pt-4 dark:border-gray-800">
        <li
          v-for="(deal, index) in model.dealCloses"
          :key="`row-${index}`"
          class="flex flex-wrap items-center justify-between gap-2 text-sm"
        >
          <span class="inline-flex items-center gap-2 text-gray-600 dark:text-gray-300">
            <span class="inline-block size-2 shrink-0 rounded-full bg-primary" />
            {{ formatDealDate(deal.date) }}
          </span>
          <span class="font-medium tabular-nums text-gray-900 dark:text-gray-100">
            +{{ formatSalesAmount(deal.amount, form.currency, locale) }}
          </span>
        </li>
      </ul>
    </div>
  </div>
</template>
