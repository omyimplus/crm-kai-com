<script setup lang="ts" generic="T extends Record<string, number | null | undefined>">
import { LineChart } from 'vue-chrts'
import {
  APP_CHART_DEFAULT_HEIGHT,
  APP_CHART_PADDING,
  type AppChartSeries,
  appChartCategories,
  appChartLineDashArray
} from '~/config/appChart'

const props = withDefaults(defineProps<{
  data: T[]
  series: AppChartSeries[]
  height?: number
  xLabel?: string
  yLabel?: string
  xFormatter?: (tick: number, index?: number) => string
  yFormatter?: (tick: number) => string
  yDomain?: [number | undefined, number | undefined]
  hideLegend?: boolean
  ariaLabel?: string
  xNumTicks?: number
}>(), {
  height: APP_CHART_DEFAULT_HEIGHT,
  hideLegend: false,
  xNumTicks: 6
})

const categories = computed(() => appChartCategories(props.series))
const lineDashArray = computed(() => appChartLineDashArray(props.series))

const xTickFormatter = computed(() => {
  if (props.xFormatter) {
    return (tick: number, index?: number) => props.xFormatter!(tick, index)
  }
  return (tick: number) => String(tick)
})

const yTickFormatter = computed(() => {
  if (props.yFormatter) {
    return (tick: number) => props.yFormatter!(tick)
  }
  return (tick: number) => String(tick)
})

const { t } = useI18n()
</script>

<template>
  <ClientOnly>
    <div
      class="w-full min-w-0"
      role="img"
      :aria-label="ariaLabel"
    >
      <LineChart
        :data="data"
        :categories="categories"
        :height="height"
        :padding="APP_CHART_PADDING"
        :x-label="xLabel"
        :y-label="yLabel"
        :x-formatter="xTickFormatter"
        :y-formatter="yTickFormatter"
        :y-domain="yDomain"
        :hide-legend="hideLegend"
        :line-dash-array="lineDashArray"
        :x-num-ticks="xNumTicks"
        :y-grid-line="true"
        hide-area
      />
    </div>
    <template #fallback>
      <div
        class="flex items-center justify-center rounded-xl border border-dashed border-gray-200 text-sm text-gray-500 dark:border-gray-700 dark:text-gray-400"
        :style="{ height: `${height}px` }"
      >
        {{ t('common.loading') }}
      </div>
    </template>
  </ClientOnly>
</template>
