<script setup lang="ts">
import {
  kutoAiInsights,
  kutoMyKpis,
  kutoMyOpportunities,
  kutoQuickActions,
  kutoTodayTasks
} from '~/config/kutoDashboardMock'
import { kutoDashboardTypes, type KutoDashboardTypeId } from '~/config/kutoMenu'
import { kutoControlClass, kutoInputClass, kutoSelectMenuUi, kutoShellCardClass } from '~/config/kutoTheme'

const { t, locale } = useI18n()

const dashboardType = ref<KutoDashboardTypeId>('my')
const periodTab = ref('today')
const filterSearch = ref('')
const filterToday = ref<string | undefined>(undefined)
const filterWeek = ref<string | undefined>(undefined)
const filterMonth = ref<string | undefined>(undefined)
const filterStatus = ref<string | undefined>(undefined)
const filterPriority = ref<string | undefined>(undefined)
const filterCustomer = ref<string | undefined>(undefined)

const opportunities = computed(() => kutoMyOpportunities)

const {
  page: oppsPage,
  pagedItems: pagedOpportunities,
  totalItems: oppsTotalItems,
  totalPages: oppsTotalPages,
  rangeStart: oppsRangeStart,
  rangeEnd: oppsRangeEnd,
  pageSize: oppsPageSize
} = useKutoPagination(opportunities, 2)

const periodTabs = ['today', 'week', 'month', 'quarter', 'year'] as const

const filterTodayItems = computed(() => periodTabs.map(tab => ({
  label: t(`kuto.dashboard.period.${tab}`),
  value: tab
})))

const filterStatusItems = computed(() => [
  { label: t('kuto.dashboard.tasks.status.today'), value: 'today' },
  { label: t('kuto.dashboard.tasks.status.overdue'), value: 'overdue' }
])

const filterPriorityItems = computed(() => [
  { label: t('kuto.dashboard.filters.priorityHigh'), value: 'high' },
  { label: t('kuto.dashboard.filters.priorityNormal'), value: 'normal' }
])

const filterCustomerItems = computed(() => [
  { label: t('kuto.dashboard.filters.customerAll'), value: 'all' }
])

function probColor(p: number) {
  if (p >= 75) return 'bg-teal-500'
  if (p >= 50) return 'bg-amber-500'
  return 'bg-red-500'
}
</script>

<template>
  <div class="space-y-4">
    <KutoDashboardLiveSection />

    <!-- Dashboard type picker -->
    <div :class="[kutoShellCardClass, 'p-3']">
      <div class="mb-2 flex items-center gap-2 text-xs font-semibold text-shell-muted">
        <UIcon
          name="i-lucide-filter"
          class="size-3.5"
        />
        {{ t('kuto.dashboard.selectType') }}
      </div>
      <div class="flex flex-wrap gap-2">
        <button
          v-for="type in kutoDashboardTypes"
          :key="type.id"
          type="button"
          class="flex items-center gap-1.5 rounded-lg px-3 py-2 text-xs font-semibold transition-colors"
          :class="dashboardType === type.id ? 'bg-teal-500 text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'"
          @click="dashboardType = type.id"
        >
          <UIcon
            :name="type.icon"
            class="size-3.5"
          />
          {{ t(type.labelKey) }}
        </button>
      </div>
    </div>

    <!-- My dashboard (active type) -->
    <template v-if="dashboardType === 'my'">
      <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p class="text-xs font-semibold text-teal-600/80">
            {{ locale === 'th' ? t('kuto.dashboard.modeTh') : t('kuto.dashboard.modeEn') }}
          </p>
          <h1 class="mt-1 text-xl font-bold text-shell-fg">
            {{ t('kuto.dashboard.myTitle') }}
          </h1>
          <p class="mt-1 text-sm text-shell-muted">
            {{ t('kuto.dashboard.mySubtitle') }}
          </p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <div class="flex rounded-lg border border-shell-border bg-white p-0.5 text-xs">
            <button
              v-for="tab in periodTabs"
              :key="tab"
              type="button"
              class="rounded-md px-2.5 py-1.5 font-medium transition-colors"
              :class="periodTab === tab ? 'bg-teal-500 text-white' : 'text-gray-500 hover:text-gray-700'"
              @click="periodTab = tab"
            >
              {{ t(`kuto.dashboard.period.${tab}`) }}
            </button>
          </div>
          <button
            type="button"
            :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-1.5']"
          >
            <UIcon
              name="i-lucide-download"
              class="size-3.5"
            />
            Export
          </button>
          <button
            type="button"
            :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-1.5']"
          >
            <UIcon
              name="i-lucide-refresh-cw"
              class="size-3.5"
            />
            Refresh
          </button>
          <button
            type="button"
            :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-1.5']"
          >
            <UIcon
              name="i-lucide-settings"
              class="size-3.5"
            />
            {{ t('kuto.dashboard.settings') }}
          </button>
        </div>
      </div>

      <!-- Filter row -->
      <div :class="[kutoShellCardClass, 'grid gap-3 p-3 md:grid-cols-2 lg:grid-cols-8']">
        <div class="relative lg:col-span-2">
          <UIcon
            name="i-lucide-search"
            class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-shell-muted"
          />
          <input
            v-model="filterSearch"
            type="search"
            :class="[kutoInputClass, 'py-2 pl-9']"
            :placeholder="t('kuto.dashboard.filterSearch')"
          >
        </div>
        <USelectMenu
          v-model="filterToday"
          :items="filterTodayItems"
          value-key="value"
          :placeholder="t('kuto.dashboard.period.today')"
          size="sm"
          :ui="kutoSelectMenuUi"
        />
        <USelectMenu
          v-model="filterWeek"
          :items="filterTodayItems"
          value-key="value"
          :placeholder="t('kuto.dashboard.period.week')"
          size="sm"
          :ui="kutoSelectMenuUi"
        />
        <USelectMenu
          v-model="filterMonth"
          :items="filterTodayItems"
          value-key="value"
          :placeholder="t('kuto.dashboard.period.month')"
          size="sm"
          :ui="kutoSelectMenuUi"
        />
        <USelectMenu
          v-model="filterStatus"
          :items="filterStatusItems"
          value-key="value"
          :placeholder="t('kuto.dashboard.filters.status')"
          size="sm"
          :ui="kutoSelectMenuUi"
        />
        <USelectMenu
          v-model="filterPriority"
          :items="filterPriorityItems"
          value-key="value"
          :placeholder="t('kuto.dashboard.filters.priority')"
          size="sm"
          :ui="kutoSelectMenuUi"
        />
        <USelectMenu
          v-model="filterCustomer"
          :items="filterCustomerItems"
          value-key="value"
          :placeholder="t('kuto.dashboard.filters.customer')"
          size="sm"
          :ui="kutoSelectMenuUi"
        />
      </div>

      <!-- My KPI cards -->
      <section class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-6">
        <div
          v-for="kpi in kutoMyKpis"
          :key="kpi.key"
          :class="[kutoShellCardClass, 'p-4']"
        >
          <div class="flex items-start justify-between gap-2">
            <div
              class="flex size-9 items-center justify-center rounded-full"
              :class="kpi.iconBg"
            >
              <UIcon
                :name="kpi.icon"
                class="size-4"
              />
            </div>
            <span
              v-if="kpi.trend"
              class="text-xs font-semibold"
              :class="kpi.trendDown ? 'text-red-500' : 'text-emerald-600'"
            >
              {{ kpi.trend }}
            </span>
          </div>
          <p class="mt-3 text-2xl font-bold text-shell-fg">
            {{ kpi.value }}
          </p>
          <p class="mt-1 text-xs text-shell-muted">
            {{ t(kpi.labelKey) }}
          </p>
        </div>
      </section>

      <div class="grid gap-4 xl:grid-cols-[1fr_300px]">
        <div class="space-y-4">
          <!-- Tasks today -->
          <div :class="kutoShellCardClass">
            <div class="flex items-center justify-between border-b border-shell-border px-5 py-4">
              <h2 class="font-semibold text-shell-fg">
                {{ t('kuto.dashboard.tasks.title') }}
              </h2>
              <button
                type="button"
                class="text-xs font-semibold text-teal-600 hover:text-teal-700"
              >
                {{ t('kuto.dashboard.viewAll') }} →
              </button>
            </div>
            <ul class="divide-y divide-shell-border">
              <li
                v-for="task in kutoTodayTasks"
                :key="task.id"
                class="flex items-center gap-3 px-5 py-3"
              >
                <div
                  class="flex size-9 shrink-0 items-center justify-center rounded-lg"
                  :class="task.iconColor"
                >
                  <UIcon
                    :name="task.icon"
                    class="size-4"
                  />
                </div>
                <div class="min-w-0 flex-1">
                  <p class="text-sm font-medium text-shell-fg">
                    {{ t(task.title) }}
                  </p>
                  <p class="text-xs text-shell-muted">
                    {{ t(task.meta) }}
                  </p>
                </div>
                <span
                  class="shrink-0 rounded-full px-2 py-0.5 text-[10px] font-semibold"
                  :class="task.statusTone === 'overdue' ? 'bg-red-50 text-red-700 ring-1 ring-red-200' : 'bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200'"
                >
                  {{ t(task.statusKey) }}
                </span>
              </li>
            </ul>
          </div>

          <!-- Opportunities -->
          <div :class="[kutoShellCardClass, 'overflow-hidden']">
            <div class="flex items-center justify-between border-b border-shell-border px-5 py-4">
              <h2 class="font-semibold text-shell-fg">
                {{ t('kuto.dashboard.opps.title') }}
              </h2>
              <button
                type="button"
                class="text-xs font-semibold text-teal-600 hover:text-teal-700"
              >
                {{ t('kuto.dashboard.viewAll') }} →
              </button>
            </div>
            <div class="overflow-x-auto">
              <table class="w-full min-w-[640px] text-left text-sm">
                <thead class="bg-gray-50 text-xs text-shell-muted">
                  <tr>
                    <th class="px-5 py-3 font-semibold">
                      {{ t('kuto.dashboard.opps.col.opportunity') }}
                    </th>
                    <th class="px-3 py-3 font-semibold">
                      {{ t('kuto.dashboard.opps.col.customer') }}
                    </th>
                    <th class="px-3 py-3 font-semibold">
                      {{ t('kuto.dashboard.opps.col.stage') }}
                    </th>
                    <th class="px-3 py-3 font-semibold">
                      {{ t('kuto.dashboard.opps.col.amount') }}
                    </th>
                    <th class="px-3 py-3 font-semibold">
                      {{ t('kuto.dashboard.opps.col.prob') }}
                    </th>
                    <th class="px-3 py-3 font-semibold" />
                  </tr>
                </thead>
                <tbody class="divide-y divide-shell-border">
                  <tr
                    v-for="opp in pagedOpportunities"
                    :key="opp.id"
                    class="hover:bg-gray-50/80"
                  >
                    <td class="px-5 py-3 font-medium text-shell-fg">
                      {{ opp.name }}
                    </td>
                    <td class="px-3 py-3 text-shell-muted">
                      {{ opp.customer }}
                    </td>
                    <td class="px-3 py-3">
                      <span class="rounded-full bg-teal-50 px-2 py-0.5 text-xs font-semibold text-teal-700 ring-1 ring-teal-200">
                        {{ t(opp.stageKey) }}
                      </span>
                    </td>
                    <td class="px-3 py-3 font-medium">
                      {{ opp.amount }}
                    </td>
                    <td class="px-3 py-3">
                      <div class="flex min-w-16 items-center gap-1.5">
                        <div class="h-1.5 flex-1 rounded-full bg-gray-200">
                          <div
                            class="h-1.5 rounded-full"
                            :class="probColor(opp.probability)"
                            :style="{ width: `${opp.probability}%` }"
                          />
                        </div>
                        <span class="w-8 text-[10px] font-bold text-shell-muted">{{ opp.probability }}%</span>
                      </div>
                    </td>
                    <td class="px-3 py-3">
                      <UIcon
                        name="i-lucide-arrow-right"
                        class="size-4 text-shell-muted"
                      />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <KutoPagination
              v-model:page="oppsPage"
              :total-items="oppsTotalItems"
              :total-pages="oppsTotalPages"
              :range-start="oppsRangeStart"
              :range-end="oppsRangeEnd"
              :page-size="oppsPageSize"
            />
          </div>
        </div>

        <div class="space-y-4">
          <!-- Quick actions -->
          <div :class="kutoShellCardClass">
            <div class="border-b border-shell-border px-4 py-3">
              <h2 class="text-sm font-semibold text-shell-fg">
                {{ t('kuto.dashboard.quickActions.title') }}
              </h2>
            </div>
            <div class="grid gap-2 p-3">
              <button
                v-for="action in kutoQuickActions"
                :key="action.key"
                type="button"
                class="flex items-center gap-2 rounded-lg border border-shell-border px-3 py-2.5 text-left text-sm font-medium text-shell-fg transition-colors hover:bg-teal-50 hover:border-teal-200"
              >
                <UIcon
                  :name="action.icon"
                  class="size-4 text-teal-600"
                />
                {{ t(action.labelKey) }}
              </button>
            </div>
          </div>

          <!-- AI insight -->
          <div class="overflow-hidden rounded-xl bg-gradient-to-br from-slate-800 to-slate-900 p-4 text-white shadow-sm">
            <div class="mb-3 flex items-center gap-2">
              <UIcon
                name="i-lucide-sparkles"
                class="size-4 text-amber-400"
              />
              <h2 class="text-sm font-semibold">
                {{ t('kuto.dashboard.ai.title') }}
              </h2>
            </div>
            <ul class="space-y-3 text-xs leading-relaxed text-white/90">
              <li
                v-for="item in kutoAiInsights"
                :key="item.key"
                class="rounded-lg bg-white/10 px-3 py-2"
              >
                {{ t(item.textKey) }}
              </li>
            </ul>
          </div>
        </div>
      </div>
    </template>

    <div
      v-else
      :class="[kutoShellCardClass, 'flex flex-col items-center justify-center py-16 text-shell-muted']"
    >
      <UIcon
        name="i-lucide-sparkles"
        class="mb-3 size-10 opacity-40"
      />
      <p class="font-semibold text-shell-fg">
        {{ t(kutoDashboardTypes.find(d => d.id === dashboardType)!.labelKey) }}
      </p>
      <p class="mt-1 text-sm">
        {{ t('kuto.dashboard.placeholder') }}
      </p>
    </div>
  </div>
</template>
