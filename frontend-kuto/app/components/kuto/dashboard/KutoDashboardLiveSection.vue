<script setup lang="ts">
import { kutoLiveKpis } from '~/config/kutoDashboardMock'
import { kutoKpiGridClass } from '~/config/kutoTheme'

const { t, locale } = useI18n()

function onRefresh() {
  // TODO: wire Supabase live KPI refresh
}
</script>

<template>
  <section class="space-y-3">
    <!-- Title row -->
    <div class="flex items-start justify-between gap-4">
      <h1 class="text-2xl font-bold tracking-tight text-gray-900">
        {{ t('kuto.dashboard.live.pageTitle') }}
      </h1>
      <span
        class="shrink-0 rounded-full px-3 py-1 text-xs font-semibold"
        :class="locale === 'th'
          ? 'bg-teal-50 text-teal-700 ring-1 ring-teal-200/80'
          : 'bg-amber-50 text-amber-700 ring-1 ring-amber-200/80'"
      >
        {{ locale === 'th' ? t('kuto.dashboard.modeTh') : t('kuto.dashboard.modeEn') }}
      </span>
    </div>

    <!-- Live data + refresh -->
    <div class="flex items-center justify-between gap-4">
      <p class="text-sm text-gray-400">
        {{ t('kuto.dashboard.live.liveDataHint') }}
      </p>
      <button
        type="button"
        class="inline-flex shrink-0 items-center gap-1.5 text-sm text-gray-400 transition-colors hover:text-teal-600"
        @click="onRefresh"
      >
        <UIcon
          name="i-lucide-refresh-cw"
          class="size-3.5"
        />
        {{ t('kuto.dashboard.live.refresh') }}
      </button>
    </div>

    <!-- KPI cards -->
    <div :class="kutoKpiGridClass">
      <div
        v-for="kpi in kutoLiveKpis"
        :key="kpi.key"
        class="relative overflow-hidden rounded-xl bg-white shadow-[0_1px_3px_rgba(15,23,42,0.08)]"
        :style="{ borderLeft: `4px solid ${kpi.accent}` }"
      >
        <div class="flex items-start justify-between gap-2 py-3.5 pl-3.5 pr-3.5">
          <p class="text-xs font-medium text-gray-500">
            {{ t(kpi.labelKey) }}
          </p>
          <div
            class="flex size-8 shrink-0 items-center justify-center rounded-full"
            :class="kpi.iconBg"
          >
            <UIcon
              :name="kpi.icon"
              class="size-4"
            />
          </div>
        </div>

        <div class="px-3.5 pb-3.5 pl-3.5">
          <p
            class="text-2xl font-bold leading-none"
            :style="{ color: kpi.accent }"
          >
            {{ kpi.value }}
          </p>
          <p class="mt-1.5 text-[11px] text-gray-400">
            {{ t(kpi.subKey) }}
          </p>
        </div>
      </div>
    </div>
  </section>
</template>
