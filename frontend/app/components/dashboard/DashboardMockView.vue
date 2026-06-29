<script setup lang="ts">
import {
  dashboardMockCustomer360Cards,
  dashboardMockCustomer360Tabs,
  dashboardMockCustomers,
  dashboardMockKpis,
  dashboardMockStatusBadges
} from '~/config/dashboardMock'
import {
  appShellAccentLabelClass,
  appShellAccentSoftClass,
  appShellControlClass,
  appShellCtaClass,
  appShellHoverRowClass,
  appShellInputClass,
  appShellMutedTextClass,
  appShellPanelMutedClass
} from '~/config/appShellTheme'

const { t, locale } = useI18n()

const customerSearch = ref('')
const customer360Tab = ref(0)

const tableHeaders = [
  'dashboard.mock.table.customerName',
  'dashboard.mock.table.customerCode',
  'dashboard.mock.table.industry',
  'dashboard.mock.table.customerType',
  'dashboard.mock.table.accountOwner',
  'dashboard.mock.table.customerTier',
  'dashboard.mock.table.totalRevenue',
  'dashboard.mock.table.openPipeline',
  'dashboard.mock.table.openTickets',
  'dashboard.mock.table.healthScore'
] as const
</script>

<template>
  <div class="space-y-6">
    <div>
      <p :class="appShellAccentLabelClass">
        {{ locale === 'th' ? t('dashboard.mock.modeTh') : t('dashboard.mock.modeEn') }}
      </p>
      <h1 class="mt-1 text-3xl font-extrabold text-shell-fg md:text-4xl">
        {{ t('dashboard.mock.title') }}
      </h1>
      <p :class="['mt-2 max-w-4xl text-sm', appShellMutedTextClass]">
        {{ t('dashboard.mock.subtitle') }}
      </p>
    </div>

    <section class="grid gap-4 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-6">
      <DashboardShellCard
        v-for="kpi in dashboardMockKpis"
        :key="kpi.key"
        class="p-5"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <p class="text-sm font-semibold text-shell-fg/80">
              {{ t(kpi.labelKey) }}
            </p>
            <p class="mt-3 text-2xl font-extrabold text-shell-fg">
              {{ kpi.value }}
            </p>
          </div>
          <div :class="['shrink-0', appShellAccentSoftClass]">
            <UIcon
              :name="kpi.icon"
              class="size-5"
            />
          </div>
        </div>
      </DashboardShellCard>
    </section>

    <div class="grid gap-6 xl:grid-cols-[1fr_360px]">
      <div class="space-y-6">
        <DashboardShellCard class="overflow-hidden">
          <div class="flex flex-col gap-4 border-b border-shell-border p-5 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h2 class="text-2xl font-extrabold text-shell-fg">
                {{ t('dashboard.mock.customerList.title') }}
              </h2>
              <p :class="['mt-1 text-sm', appShellMutedTextClass]">
                {{ t('dashboard.mock.customerList.hint') }}
              </p>
            </div>
            <NuxtLink
              to="/app/customer/new"
              :class="[appShellCtaClass, 'shrink-0']"
            >
              {{ t('dashboard.mock.customerList.newCustomer') }}
            </NuxtLink>
          </div>

          <div :class="['grid gap-3 border-b border-shell-border p-4 md:grid-cols-[1fr_auto]', appShellPanelMutedClass]">
            <input
              v-model="customerSearch"
              type="search"
              :class="[appShellInputClass, 'px-4 py-3']"
              :placeholder="t('dashboard.mock.customerList.searchPlaceholder')"
            >
            <button
              type="button"
              :class="[appShellControlClass, 'inline-flex items-center justify-center px-4 py-3 text-sm font-medium text-shell-fg']"
            >
              <UIcon
                name="i-lucide-filter"
                class="mr-2 size-4"
              />
              {{ t('dashboard.mock.customerList.filter') }}
            </button>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full min-w-[1100px] text-left text-sm">
              <thead class="bg-shell-card text-xs">
                <tr>
                  <th
                    v-for="header in tableHeaders"
                    :key="header"
                    class="px-4 py-3 font-bold text-shell-fg/80"
                  >
                    {{ t(header) }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="row in dashboardMockCustomers"
                  :key="row.id"
                  :class="['border-t border-shell-border', appShellHoverRowClass]"
                >
                  <td class="px-4 py-3 font-medium text-shell-fg">
                    {{ row.name }}
                  </td>
                  <td :class="['px-4 py-3', appShellMutedTextClass]">
                    {{ row.code }}
                  </td>
                  <td :class="['px-4 py-3', appShellMutedTextClass]">
                    {{ row.industry }}
                  </td>
                  <td :class="['px-4 py-3', appShellMutedTextClass]">
                    {{ row.customerType }}
                  </td>
                  <td :class="['px-4 py-3', appShellMutedTextClass]">
                    {{ row.owner }}
                  </td>
                  <td :class="['px-4 py-3', appShellMutedTextClass]">
                    {{ row.tier }}
                  </td>
                  <td :class="['px-4 py-3', appShellMutedTextClass]">
                    {{ row.totalRevenue }}
                  </td>
                  <td :class="['px-4 py-3', appShellMutedTextClass]">
                    {{ row.openPipeline }}
                  </td>
                  <td :class="['px-4 py-3', appShellMutedTextClass]">
                    {{ row.openTickets }}
                  </td>
                  <td class="px-4 py-3">
                    <DashboardMockBadge>{{ row.healthScore }}</DashboardMockBadge>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </DashboardShellCard>

        <DashboardShellCard class="p-5">
          <h2 class="text-2xl font-extrabold text-shell-fg">
            {{ t('dashboard.mock.customer360.title') }}
          </h2>
          <div class="mt-4 flex gap-2 overflow-x-auto pb-1">
            <button
              v-for="(tab, index) in dashboardMockCustomer360Tabs"
              :key="tab"
              type="button"
              class="shrink-0 rounded-2xl px-4 py-2 text-sm font-medium transition"
              :class="customer360Tab === index
                ? 'bg-primary text-white'
                : 'bg-shell-input text-shell-fg/80'"
              @click="customer360Tab = index"
            >
              {{ t(`dashboard.mock.customer360.tabs.${tab}`) }}
            </button>
          </div>
          <div class="mt-5 grid gap-4 md:grid-cols-3">
            <div
              v-for="card in dashboardMockCustomer360Cards"
              :key="card"
              :class="['rounded-2xl p-4', appShellPanelMutedClass]"
            >
              <p class="font-bold text-shell-fg">
                {{ t(`dashboard.mock.customer360.cards.${card}`) }}
              </p>
              <p :class="['mt-2 text-sm', appShellMutedTextClass]">
                {{ t('dashboard.mock.customer360.sampleHint') }}
              </p>
            </div>
          </div>
        </DashboardShellCard>
      </div>

      <aside class="sticky top-24 h-fit">
        <DashboardShellCard class="p-5 shadow-lg dark:shadow-none">
          <UIcon
            name="i-lucide-sparkles"
            class="mb-3 size-5 text-green-600 dark:text-green-400"
          />
          <h2 class="text-xl font-extrabold text-shell-fg">
            {{ t('dashboard.mock.aiPanel.title') }}
          </h2>
          <div class="mt-4 space-y-3">
            <DashboardMockBadge tone="amber">
              {{ t('dashboard.mock.aiPanel.atRisk') }}
            </DashboardMockBadge>
            <p :class="['text-sm', appShellMutedTextClass]">
              {{ t('dashboard.mock.aiPanel.renewalHint') }}
            </p>
            <button
              type="button"
              class="w-full rounded-2xl bg-primary px-4 py-3 text-sm font-bold text-white"
            >
              {{ t('dashboard.mock.aiPanel.createActivity') }}
            </button>
            <button
              type="button"
              class="w-full rounded-2xl bg-green-600 px-4 py-3 text-sm font-bold text-white"
            >
              {{ t('dashboard.mock.aiPanel.createOpportunity') }}
            </button>
            <button
              type="button"
              class="w-full rounded-2xl bg-amber-500 px-4 py-3 text-sm font-bold text-white"
            >
              {{ t('dashboard.mock.aiPanel.createTicket') }}
            </button>
          </div>
        </DashboardShellCard>
      </aside>
    </div>

    <DashboardShellCard class="p-5">
      <h2 class="text-2xl font-extrabold text-shell-fg">
        {{ t('dashboard.mock.statusBadges.title') }}
      </h2>
      <div class="mt-4 flex flex-wrap gap-2">
        <DashboardMockBadge
          v-for="badge in dashboardMockStatusBadges"
          :key="badge.key"
          :tone="badge.tone"
        >
          {{ t(badge.labelKey) }}
        </DashboardMockBadge>
      </div>
    </DashboardShellCard>
  </div>
</template>
