<script setup lang="ts">
import {
  kutoCustomerStatusTabs,
  kutoCustomersListRows,
  kutoCustomersListSummaryMeta,
  type KutoCustomerListRow,
  type KutoCustomerStatusTabKey
} from '~/config/kutoCustomersListMock'
import {
  kutoControlClass,
  kutoInboxSidebarWidthClass,
  kutoInputClass,
  kutoKpiGridClass,
  kutoSelectMenuUi,
  kutoShellCardClass
} from '~/config/kutoTheme'
import {
  kutoCustomerHealthColor,
  kutoCustomerRenewalBadgeClass,
  kutoCustomerTierBadgeClass,
  kutoCustomerTypeBadgeClass
} from '~/utils/kutoCustomerBadges'

const { t } = useI18n()

const statusTab = ref<KutoCustomerStatusTabKey>('all')
const search = ref('')
const tierFilter = ref<string | undefined>(undefined)
const ownerFilter = ref<string | undefined>(undefined)
const selectedIds = ref<Set<string>>(new Set())
const selectedId = ref('1')

const tierFilterItems = computed(() => [
  { label: t('kuto.customers.list.filters.tier'), value: undefined },
  { label: t('kuto.customers.list.tiers.platinum'), value: 'platinum' },
  { label: t('kuto.customers.list.tiers.gold'), value: 'gold' },
  { label: t('kuto.customers.list.tiers.silver'), value: 'silver' }
])

const ownerFilterItems = computed(() => [
  { label: t('kuto.customers.list.filters.owner'), value: undefined },
  { label: 'นิชา ศรีวงศ์', value: 'nicha' },
  { label: 'สมศักดิ์ ใจดี', value: 'somsak' }
])

const filterPlaceholders = computed(() => [
  t('kuto.customers.list.filters.group'),
  t('kuto.customers.list.filters.health'),
  t('kuto.customers.list.filters.status'),
  t('kuto.customers.list.filters.customerType'),
  t('kuto.customers.list.filters.businessType'),
  t('kuto.customers.list.filters.province'),
  t('kuto.customers.list.filters.revenue'),
  t('kuto.customers.list.filters.renewal'),
  t('kuto.customers.list.filters.ticket')
])

function rowMatchesTab(row: KutoCustomerListRow): boolean {
  if (statusTab.value === 'all') return true
  return row.statusTags.includes(statusTab.value)
}

const filteredRows = computed(() => {
  const q = search.value.trim().toLowerCase()
  return kutoCustomersListRows.filter((row) => {
    if (!rowMatchesTab(row)) return false
    if (tierFilter.value && !row.tierKey.includes(tierFilter.value)) return false
    if (ownerFilter.value === 'nicha' && !row.ownerName.includes('นิชา')) return false
    if (ownerFilter.value === 'somsak' && !row.ownerName.includes('สมศักดิ์')) return false
    if (!q) return true
    return (
      row.code.toLowerCase().includes(q)
      || row.name.toLowerCase().includes(q)
      || row.taxId.includes(q)
      || row.email.toLowerCase().includes(q)
      || row.phone.includes(q)
    )
  })
})

const {
  page,
  pagedItems,
  totalItems,
  totalPages,
  rangeStart,
  rangeEnd,
  pageSize
} = useKutoPagination(filteredRows, 8)

const selectedCustomer = computed(() =>
  kutoCustomersListRows.find(row => row.id === selectedId.value)
  ?? pagedItems.value[0]
  ?? filteredRows.value[0]
)

const selectedCount = computed(() => selectedIds.value.size)
const allVisibleSelected = computed(() =>
  pagedItems.value.length > 0
  && pagedItems.value.every(r => selectedIds.value.has(r.id))
)

function onKpiClick(tabKey: KutoCustomerStatusTabKey) {
  statusTab.value = tabKey
}

function selectRow(row: KutoCustomerListRow) {
  selectedId.value = row.id
}

function toggleSelectAll() {
  if (allVisibleSelected.value) {
    selectedIds.value = new Set()
  } else {
    selectedIds.value = new Set(pagedItems.value.map(r => r.id))
  }
}

function toggleRow(row: KutoCustomerListRow) {
  const next = new Set(selectedIds.value)
  if (next.has(row.id)) next.delete(row.id)
  else next.add(row.id)
  selectedIds.value = next
}

function clearFilters() {
  search.value = ''
  statusTab.value = 'all'
  tierFilter.value = undefined
  ownerFilter.value = undefined
}

const hasActiveFilters = computed(() =>
  search.value.trim().length > 0
  || statusTab.value !== 'all'
  || tierFilter.value !== undefined
  || ownerFilter.value !== undefined
)

watch([statusTab, tierFilter, ownerFilter], () => {
  selectedIds.value = new Set()
})

watch(pagedItems, (rows) => {
  if (!rows.some(r => r.id === selectedId.value) && rows[0]) {
    selectedId.value = rows[0].id
  }
})

/** การ์ดขวาใบที่ 2 — สรุปความสัมพันธ์ (mock) */
const kutoCustomerRelationBars = [
  { key: 'contacts', labelKey: 'kuto.customers.list.relations.contacts', value: 12, color: '#17A8A3' },
  { key: 'opps', labelKey: 'kuto.customers.list.relations.opps', value: 4, color: '#3B82F6' },
  { key: 'tickets', labelKey: 'kuto.customers.list.relations.tickets', value: 6, color: '#8B5CF6' },
  { key: 'contracts', labelKey: 'kuto.customers.list.relations.contracts', value: 3, color: '#F59E0B' }
] as const

const relationBarMax = Math.max(...kutoCustomerRelationBars.map(b => b.value))
</script>

<template>
  <div class="space-y-4">
    <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <h1 class="text-2xl font-bold tracking-tight text-gray-900">
            {{ t('kuto.customers.list.title') }}
          </h1>
          <p class="mt-1 text-sm text-shell-muted">
            {{ t('kuto.customers.list.subtitle') }}
          </p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <NuxtLink
            to="/app/customers/import"
            :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-2 text-sm font-semibold text-shell-fg']"
          >
            <UIcon
              name="i-lucide-upload"
              class="size-4"
            />
            {{ t('kuto.customers.list.actions.import') }}
          </NuxtLink>
          <button
            type="button"
            :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-2 text-sm font-semibold opacity-60']"
            disabled
          >
            <UIcon
              name="i-lucide-download"
              class="size-4"
            />
            {{ t('kuto.customers.list.actions.export') }}
          </button>
          <NuxtLink
            to="/app/customers/new"
            class="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-teal-600"
          >
            <UIcon
              name="i-lucide-plus"
              class="size-4"
            />
            {{ t('kuto.customers.list.actions.new') }}
          </NuxtLink>
        </div>
      </div>

      <div :class="kutoKpiGridClass">
        <KutoKpiCard
          v-for="meta in kutoCustomersListSummaryMeta"
          :key="meta.key"
          :label="t(meta.labelKey)"
          :value="meta.value"
          :accent="meta.accent"
          :icon="meta.icon"
          :icon-bg="meta.iconBg"
          :sub-label="t(meta.subKey)"
          :trend="meta.trend"
          :trend-down="'trendDown' in meta && meta.trendDown"
          :interactive="true"
          :active="statusTab === meta.tabKey"
          class="h-full"
          @click="onKpiClick(meta.tabKey)"
        />
      </div>

    <!-- ตารางซ้าย + การ์ดขวา 2 ใบ (pattern เดียวกับกล่องรับเป้าหมาย) -->
    <div class="flex items-start gap-4">
      <div
        class="min-w-0 flex-1 overflow-hidden"
        :class="kutoShellCardClass"
      >
        <div class="flex flex-col gap-3 border-b border-shell-border p-3 lg:flex-row lg:flex-wrap lg:items-center">
          <div class="relative min-w-0 flex-1 lg:min-w-[14rem]">
            <UIcon
              name="i-lucide-search"
              class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-shell-muted"
            />
            <input
              v-model="search"
              type="search"
              :class="[kutoInputClass, 'py-2 pl-9 pr-3 text-sm']"
              :placeholder="t('kuto.customers.list.searchPlaceholder')"
            >
          </div>
          <USelectMenu
            v-model="tierFilter"
            :items="tierFilterItems"
            value-key="value"
            :placeholder="t('kuto.customers.list.filters.tier')"
            class="w-full sm:w-36"
            :ui="kutoSelectMenuUi"
          />
          <USelectMenu
            v-model="ownerFilter"
            :items="ownerFilterItems"
            value-key="value"
            :placeholder="t('kuto.customers.list.filters.owner')"
            class="w-full sm:w-36"
            :ui="kutoSelectMenuUi"
          />
          <USelectMenu
            v-for="(label, idx) in filterPlaceholders"
            :key="idx"
            :items="[{ label, value: undefined }]"
            value-key="value"
            :placeholder="label"
            class="hidden w-36 xl:block"
            :ui="kutoSelectMenuUi"
            disabled
          />
          <button
            v-if="hasActiveFilters"
            type="button"
            :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-2 text-xs font-semibold']"
            @click="clearFilters"
          >
            <UIcon
              name="i-lucide-rotate-ccw"
              class="size-3.5"
            />
            {{ t('kuto.customers.list.clearFilters') }}
          </button>
        </div>

        <div class="flex gap-1 overflow-x-auto border-b border-shell-border px-4">
          <button
            v-for="tab in kutoCustomerStatusTabs"
            :key="tab.key"
            type="button"
            class="inline-flex shrink-0 items-center gap-1.5 border-b-2 px-3 py-3 text-xs font-semibold transition-colors"
            :class="statusTab === tab.key
              ? 'border-teal-500 text-teal-600'
              : 'border-transparent text-gray-500 hover:text-gray-700'"
            @click="statusTab = tab.key"
          >
            {{ t(tab.labelKey) }}
            <span
              class="rounded-full px-1.5 py-0.5 text-[10px] font-bold leading-none"
              :class="statusTab === tab.key ? 'bg-teal-100 text-teal-700' : 'bg-gray-100 text-gray-600'"
            >
              {{ tab.count.toLocaleString() }}
            </span>
          </button>
        </div>

        <div
          v-if="selectedCount > 0"
          class="flex flex-wrap items-center gap-3 border-b border-shell-border bg-gray-50 px-4 py-2 text-sm"
        >
          <span class="font-medium text-shell-fg">
            {{ t('kuto.customers.list.bulk.selected', { count: selectedCount }) }}
          </span>
          <button
            type="button"
            class="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-3 py-1.5 text-xs font-semibold text-white opacity-60"
            disabled
          >
            {{ t('kuto.customers.list.bulk.update') }}
          </button>
          <span class="text-[11px] text-shell-muted">
            {{ t('kuto.customers.list.bulk.mockHint') }}
          </span>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full min-w-[1100px] text-left text-sm">
            <thead class="border-b border-shell-border bg-gray-50 text-xs font-semibold text-shell-muted">
              <tr>
                <th class="w-10 px-3 py-3">
                  <input
                    type="checkbox"
                    class="size-4 rounded border-gray-300 text-teal-600 focus:ring-teal-500/30"
                    :checked="allVisibleSelected"
                    :aria-label="t('kuto.customers.list.selectAll')"
                    @change="toggleSelectAll"
                  >
                </th>
                <th class="min-w-[10rem] px-3 py-3">
                  {{ t('kuto.customers.list.col.customer') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.list.col.code') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.list.col.type') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.list.col.business') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.list.col.tier') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.list.col.owner') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.list.col.revenue') }}
                </th>
                <th class="px-3 py-3 text-center">
                  {{ t('kuto.customers.list.col.tickets') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.list.col.renewal') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.list.col.health') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.list.col.lastActivity') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.list.col.action') }}
                </th>
                <th class="px-3 py-3 text-center">
                  {{ t('kuto.customers.list.col.actions') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-shell-border">
              <tr
                v-for="row in pagedItems"
                :key="row.id"
                class="cursor-pointer transition-colors hover:bg-teal-50/30"
                :class="[
                  selectedIds.has(row.id) ? 'bg-teal-50/50' : '',
                  selectedId === row.id ? 'bg-teal-50/40 ring-1 ring-inset ring-teal-200/60' : ''
                ]"
                @click="selectRow(row)"
              >
                <td
                  class="px-3 py-3"
                  @click.stop
                >
                  <input
                    type="checkbox"
                    class="size-4 rounded border-gray-300 text-teal-600 focus:ring-teal-500/30"
                    :checked="selectedIds.has(row.id)"
                    @change="toggleRow(row)"
                  >
                </td>
                <td class="px-3 py-3">
                  <div class="flex min-w-0 items-center gap-2">
                    <span
                      class="flex size-8 shrink-0 items-center justify-center rounded-lg text-xs font-bold text-white"
                      :class="row.avatarBg"
                    >
                      {{ row.initials }}
                    </span>
                    <span class="truncate font-medium text-shell-fg">
                      {{ row.name }}
                    </span>
                  </div>
                </td>
                <td class="px-3 py-3 font-mono text-xs font-semibold text-teal-700">
                  {{ row.code }}
                </td>
                <td class="px-3 py-3">
                  <span
                    class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                    :class="kutoCustomerTypeBadgeClass(row.customerTypeKey)"
                  >
                    {{ t(row.customerTypeKey) }}
                  </span>
                </td>
                <td class="max-w-[7rem] truncate px-3 py-3 text-shell-muted">
                  {{ t(row.businessTypeKey) }}
                </td>
                <td class="px-3 py-3">
                  <span
                    class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                    :class="kutoCustomerTierBadgeClass(row.tierKey)"
                  >
                    {{ t(row.tierKey) }}
                  </span>
                </td>
                <td class="max-w-[7rem] truncate px-3 py-3 text-shell-muted">
                  {{ row.ownerName }}
                </td>
                <td class="px-3 py-3">
                  <p class="font-semibold text-shell-fg">
                    {{ row.revenueLabel }}
                  </p>
                  <p class="text-xs text-shell-muted">
                    {{ row.pipelineLabel }}
                  </p>
                </td>
                <td class="px-3 py-3 text-center">
                  <span
                    v-if="row.ticketCount > 0"
                    class="inline-flex size-6 items-center justify-center rounded-full bg-violet-100 text-xs font-bold text-violet-700"
                  >
                    {{ row.ticketCount }}
                  </span>
                  <span
                    v-else
                    class="text-shell-muted"
                  >—</span>
                </td>
                <td class="px-3 py-3">
                  <span
                    v-if="!row.renewalKey.includes('none')"
                    class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                    :class="kutoCustomerRenewalBadgeClass(row.renewalKey)"
                  >
                    {{ t(row.renewalKey) }}
                  </span>
                  <span
                    v-else
                    class="text-shell-muted"
                  >—</span>
                </td>
                <td class="px-3 py-3">
                  <div class="flex min-w-[4.5rem] items-center gap-2">
                    <div class="h-1.5 flex-1 rounded-full bg-gray-200">
                      <div
                        class="h-1.5 rounded-full"
                        :style="{
                          width: `${row.healthScore}%`,
                          backgroundColor: kutoCustomerHealthColor(row.healthScore)
                        }"
                      />
                    </div>
                    <span class="w-6 text-xs font-bold text-shell-muted">{{ row.healthScore }}</span>
                  </div>
                </td>
                <td class="whitespace-nowrap px-3 py-3 text-xs text-shell-muted">
                  {{ t(row.lastActivityKey) }}
                </td>
                <td class="px-3 py-3">
                  <button
                    v-if="row.actionKey"
                    type="button"
                    class="text-xs font-semibold text-teal-600 hover:text-teal-700"
                    @click.stop
                  >
                    {{ t(row.actionKey) }}
                  </button>
                  <span
                    v-else
                    class="text-shell-muted"
                  >—</span>
                </td>
                <td
                  class="px-3 py-3"
                  @click.stop
                >
                  <div class="flex items-center justify-center gap-0.5">
                    <NuxtLink
                      :to="`/app/customers/${row.id}`"
                      class="inline-flex size-7 items-center justify-center rounded-md text-shell-muted hover:bg-gray-100 hover:text-teal-600"
                      :aria-label="t('kuto.customers.list.viewDetail')"
                    >
                      <UIcon
                        name="i-lucide-eye"
                        class="size-3.5"
                      />
                    </NuxtLink>
                    <NuxtLink
                      :to="`/app/customers/${row.id}`"
                      class="inline-flex size-7 items-center justify-center rounded-md text-[10px] font-bold text-shell-muted hover:bg-gray-100 hover:text-teal-600"
                      :aria-label="t('kuto.customers.list.openC360')"
                    >
                      360
                    </NuxtLink>
                    <button
                      type="button"
                      class="inline-flex size-7 items-center justify-center rounded-md text-[10px] font-bold text-shell-muted opacity-50"
                      disabled
                    >
                      {{ t('kuto.customers.list.actions.opp') }}
                    </button>
                    <button
                      type="button"
                      class="inline-flex size-7 items-center justify-center rounded-md text-[10px] font-bold text-shell-muted opacity-50"
                      disabled
                    >
                      {{ t('kuto.customers.list.actions.quotation') }}
                    </button>
                    <button
                      type="button"
                      class="inline-flex size-7 items-center justify-center rounded-md text-[10px] font-bold text-shell-muted opacity-50"
                      disabled
                    >
                      {{ t('kuto.customers.list.actions.ticket') }}
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div
          v-if="!filteredRows.length"
          class="px-4 py-12 text-center text-sm text-shell-muted"
        >
          {{ t('kuto.customers.list.empty') }}
        </div>

        <KutoPagination
          v-if="filteredRows.length"
          v-model:page="page"
          :total-items="totalItems"
          :total-pages="totalPages"
          :range-start="rangeStart"
          :range-end="rangeEnd"
          :page-size="pageSize"
        />
      </div>

      <div
        v-if="selectedCustomer"
        class="hidden shrink-0 flex-col gap-4 lg:flex lg:sticky lg:top-4"
        :class="kutoInboxSidebarWidthClass"
      >
        <div
          class="flex flex-col gap-3 p-4"
          :class="kutoShellCardClass"
        >
          <div class="flex items-start justify-between gap-2">
            <p class="text-sm font-bold text-shell-fg">
              {{ t('kuto.customers.list.detail.quickTitle') }}
            </p>
            <span
              class="shrink-0 rounded-full px-2 py-0.5 text-[10px] font-semibold ring-1 ring-inset"
              :class="kutoCustomerTierBadgeClass(selectedCustomer.tierKey)"
            >
              {{ t(selectedCustomer.tierKey) }}
            </span>
          </div>

          <div class="flex items-start gap-3">
            <span
              class="flex size-10 shrink-0 items-center justify-center rounded-xl text-sm font-bold text-white"
              :class="selectedCustomer.avatarBg"
            >
              {{ selectedCustomer.initials }}
            </span>
            <div class="min-w-0 flex-1">
              <h2 class="text-base font-bold leading-snug text-shell-fg">
                {{ selectedCustomer.name }}
              </h2>
              <p class="mt-0.5 font-mono text-[11px] font-semibold text-teal-700">
                {{ selectedCustomer.code }}
              </p>
              <span class="mt-1.5 inline-flex rounded-full bg-emerald-50 px-2 py-0.5 text-[10px] font-semibold text-emerald-700 ring-1 ring-inset ring-emerald-200/80">
                {{ t(selectedCustomer.statusLabelKey) }}
              </span>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-2 text-center">
            <div class="rounded-lg bg-gray-50 px-2 py-2">
              <p class="text-[10px] text-shell-muted">
                {{ t('kuto.customers.list.detail.revenue') }}
              </p>
              <p class="text-sm font-bold text-shell-fg">
                {{ selectedCustomer.revenueLabel }}
              </p>
            </div>
            <div class="rounded-lg bg-gray-50 px-2 py-2">
              <p class="text-[10px] text-shell-muted">
                {{ t('kuto.customers.list.detail.pipeline') }}
              </p>
              <p class="text-sm font-bold text-shell-fg">
                {{ selectedCustomer.pipelineLabel }}
              </p>
            </div>
          </div>

          <div>
            <div class="mb-1 flex items-center justify-between text-xs">
              <span class="font-medium text-shell-muted">{{ t('kuto.customers.list.detail.health') }}</span>
              <span
                class="text-lg font-bold"
                :style="{ color: kutoCustomerHealthColor(selectedCustomer.healthScore) }"
              >
                {{ selectedCustomer.healthScore }}
              </span>
            </div>
            <div class="h-2 rounded-full bg-gray-200">
              <div
                class="h-2 rounded-full transition-all"
                :style="{
                  width: `${selectedCustomer.healthScore}%`,
                  backgroundColor: kutoCustomerHealthColor(selectedCustomer.healthScore)
                }"
              />
            </div>
          </div>

          <dl class="space-y-1.5 text-xs">
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.list.detail.industry') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ t(selectedCustomer.industryKey) }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.list.detail.type') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ t(selectedCustomer.customerTypeKey) }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.list.detail.owner') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ selectedCustomer.ownerName }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.list.detail.phone') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ selectedCustomer.phone }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.list.detail.email') }}
              </dt>
              <dd class="max-w-[9rem] truncate text-right font-medium text-shell-fg">
                {{ selectedCustomer.email }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.list.detail.lastActivity') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ t(selectedCustomer.lastActivityKey) }}
              </dd>
            </div>
          </dl>

          <div
            v-if="!selectedCustomer.renewalKey.includes('none')"
            class="rounded-lg bg-amber-50 px-3 py-2 text-xs font-semibold text-amber-800 ring-1 ring-amber-100"
          >
            {{ t('kuto.customers.list.detail.renewalAlert') }}: {{ t(selectedCustomer.renewalKey) }}
          </div>

          <div class="rounded-lg border border-teal-100 bg-teal-50/80 px-3 py-2.5 text-xs leading-relaxed text-teal-800">
            <div class="mb-1 flex items-center gap-1 font-semibold">
              <UIcon
                name="i-lucide-lightbulb"
                class="size-3.5"
              />
              {{ t('kuto.customers.list.detail.aiTitle') }}
            </div>
            {{ t(selectedCustomer.aiInsightKey) }}
          </div>

          <NuxtLink
            :to="`/app/customers/${selectedCustomer.id}`"
            class="inline-flex w-full items-center justify-center gap-1.5 rounded-lg bg-teal-500 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-teal-600"
          >
            {{ t('kuto.customers.list.actions.openC360') }}
          </NuxtLink>

          <div class="grid grid-cols-2 gap-2">
            <button
              type="button"
              class="rounded-lg border border-shell-border bg-white px-2 py-2 text-[11px] font-semibold text-shell-fg opacity-60"
              disabled
            >
              {{ t('kuto.customers.list.actions.addOpp') }}
            </button>
            <button
              type="button"
              class="rounded-lg border border-shell-border bg-white px-2 py-2 text-[11px] font-semibold text-shell-fg opacity-60"
              disabled
            >
              {{ t('kuto.customers.list.actions.addQuotation') }}
            </button>
            <button
              type="button"
              class="rounded-lg border border-shell-border bg-white px-2 py-2 text-[11px] font-semibold text-shell-fg opacity-60"
              disabled
            >
              {{ t('kuto.customers.list.actions.addTicket') }}
            </button>
            <button
              type="button"
              class="rounded-lg border border-shell-border bg-white px-2 py-2 text-[11px] font-semibold text-shell-fg opacity-60"
              disabled
            >
              {{ t('kuto.customers.list.actions.addActivity') }}
            </button>
          </div>
        </div>

        <div
          class="p-4"
          :class="kutoShellCardClass"
        >
          <p class="mb-3 text-sm font-bold text-shell-fg">
            {{ t('kuto.customers.list.relations.title') }}
          </p>
          <div class="space-y-2.5">
            <div
              v-for="bar in kutoCustomerRelationBars"
              :key="bar.key"
              class="flex items-center gap-2 text-[11px]"
            >
              <span class="w-[4.5rem] shrink-0 truncate text-shell-muted">{{ t(bar.labelKey) }}</span>
              <div class="h-2 flex-1 rounded-full bg-gray-100">
                <div
                  class="h-2 rounded-full"
                  :style="{
                    width: `${(bar.value / relationBarMax) * 100}%`,
                    backgroundColor: bar.color
                  }"
                />
              </div>
              <span class="w-6 text-right font-semibold text-shell-fg">{{ bar.value }}</span>
            </div>
          </div>
          <button
            type="button"
            class="mt-3 w-full text-center text-xs font-semibold text-teal-600 hover:text-teal-700"
          >
            {{ t('kuto.customers.list.relations.viewBranch') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
