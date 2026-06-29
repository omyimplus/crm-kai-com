<script setup lang="ts">
import {
  kutoLeadKanbanColumns,
  kutoLeadPipelineTabs,
  kutoLeadsAllRows,
  kutoLeadsListSummaryMeta,
  type KutoLeadListRow,
  type KutoLeadPipelineTabKey,
  type KutoLeadViewMode
} from '~/config/kutoLeadsListMock'
import { kutoLeadScoreColor, kutoInboxChannelBars } from '~/config/kutoLeadsInboxMock'
import {
  kutoControlClass,
  kutoInboxSidebarWidthClass,
  kutoInputClass,
  kutoKpiGrid5Class,
  kutoSelectMenuUi,
  kutoShellCardClass
} from '~/config/kutoTheme'
import {
  kutoLeadSourceBadgeClass,
  kutoLeadPriorityBadgeClass,
  kutoLeadStatusBadgeClass
} from '~/utils/kutoLeadBadges'

const { t } = useI18n()
const route = useRoute()

const pipelineTab = ref<KutoLeadPipelineTabKey>('all')
const viewMode = ref<KutoLeadViewMode>('table')
const search = ref('')
const sourceFilter = ref<string | undefined>(undefined)
const selectedIds = ref<Set<string>>(new Set())
const selectedId = ref('1')

const sourceFilterItems = computed(() => [
  { label: t('kuto.leads.inbox.filters.source'), value: undefined },
  { label: t('kuto.leads.inbox.sources.website'), value: 'website' },
  { label: t('kuto.leads.inbox.sources.lineOa'), value: 'lineOa' },
  { label: t('kuto.leads.inbox.sources.facebook'), value: 'facebook' },
  { label: t('kuto.leads.inbox.sources.tender'), value: 'tender' }
])

const filteredRows = computed(() => {
  const q = search.value.trim().toLowerCase()
  return kutoLeadsAllRows.filter((row) => {
    if (pipelineTab.value !== 'all' && row.pipelineStatus !== pipelineTab.value) return false
    if (sourceFilter.value) {
      const key = row.sourceKey.toLowerCase()
      if (!key.includes(sourceFilter.value)) return false
    }
    if (!q) return true
    return (
      row.code.toLowerCase().includes(q)
      || row.company.toLowerCase().includes(q)
      || row.contact.toLowerCase().includes(q)
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
} = useKutoPagination(filteredRows, 5)

const selectedCount = computed(() => selectedIds.value.size)
const allVisibleSelected = computed(() =>
  pagedItems.value.length > 0
  && pagedItems.value.every(r => selectedIds.value.has(r.id))
)

const selectedLead = computed(() =>
  filteredRows.value.find(row => row.id === selectedId.value)
  ?? pagedItems.value[0]
  ?? filteredRows.value[0]
)

const channelMax = computed(() =>
  Math.max(...kutoInboxChannelBars.map(b => b.value))
)

watch(pagedItems, (rows) => {
  if (!rows.some(r => r.id === selectedId.value) && rows[0]) {
    selectedId.value = rows[0].id
  }
})

function selectRow(row: KutoLeadListRow) {
  selectedId.value = row.id
}

function kanbanRowsFor(pipelineStatus: string) {
  return filteredRows.value.filter(r => r.pipelineStatus === pipelineStatus)
}

function toggleSelectAll() {
  if (allVisibleSelected.value) {
    selectedIds.value = new Set()
  } else {
    selectedIds.value = new Set(pagedItems.value.map(r => r.id))
  }
}

function toggleRow(row: KutoLeadListRow) {
  const next = new Set(selectedIds.value)
  if (next.has(row.id)) next.delete(row.id)
  else next.add(row.id)
  selectedIds.value = next
}

function onKpiClick(tabKey: KutoLeadPipelineTabKey) {
  pipelineTab.value = tabKey
}

function clearFilters() {
  search.value = ''
  pipelineTab.value = 'all'
  sourceFilter.value = undefined
}

const hasActiveFilters = computed(() =>
  search.value.trim().length > 0
  || pipelineTab.value !== 'all'
  || sourceFilter.value !== undefined
)

watch(pipelineTab, () => {
  selectedIds.value = new Set()
})

onMounted(() => {
  const q = route.query.pipeline
  if (typeof q === 'string' && kutoLeadPipelineTabs.some(tab => tab.key === q)) {
    pipelineTab.value = q as KutoLeadPipelineTabKey
  }
  if (route.query.view === 'kanban') viewMode.value = 'kanban'
})
</script>

<template>
  <div class="space-y-4">
    <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900">
          {{ t('kuto.leads.list.title') }}
        </h1>
        <p class="mt-1 text-sm text-shell-muted">
          {{ t('kuto.leads.list.subtitle') }}
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <NuxtLink
          to="/app/leads/inbox"
          :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-2 text-sm font-semibold text-shell-fg']"
        >
          <UIcon
            name="i-lucide-inbox"
            class="size-4"
          />
          {{ t('kuto.leads.list.actions.inbox') }}
        </NuxtLink>
        <NuxtLink
          to="/app/leads/import"
          :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-2 text-sm font-semibold text-shell-fg']"
        >
          <UIcon
            name="i-lucide-upload"
            class="size-4"
          />
          {{ t('kuto.leads.list.actions.import') }}
        </NuxtLink>
        <NuxtLink
          to="/app/leads/duplicates"
          :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-2 text-sm font-semibold text-shell-fg']"
        >
          <UIcon
            name="i-lucide-copy"
            class="size-4"
          />
          {{ t('kuto.leads.list.actions.duplicates') }}
        </NuxtLink>
        <NuxtLink
          to="/app/leads/new"
          class="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-teal-600"
        >
          <UIcon
            name="i-lucide-plus"
            class="size-4"
          />
          {{ t('kuto.leads.list.actions.new') }}
        </NuxtLink>
      </div>
    </div>

    <div :class="kutoKpiGrid5Class">
      <KutoKpiCard
        v-for="meta in kutoLeadsListSummaryMeta"
        :key="meta.key"
        :label="t(meta.labelKey)"
        :value="meta.value"
        :accent="meta.accent"
        :icon="meta.icon"
        :icon-bg="meta.iconBg"
        :sub-label="t(meta.subKey)"
        :trend="meta.trend"
        :interactive="true"
        :active="pipelineTab === meta.tabKey"
        class="h-full"
        @click="onKpiClick(meta.tabKey)"
      />
    </div>

    <!-- ตารางซ้าย + การ์ดขวา 2 ใบ (เหมือนกล่องรับเป้าหมาย) -->
    <div class="flex items-start gap-4">
      <div
        class="min-w-0 flex-1 overflow-hidden"
        :class="kutoShellCardClass"
      >
      <div class="flex gap-1 overflow-x-auto border-b border-shell-border px-4">
        <button
          v-for="tab in kutoLeadPipelineTabs"
          :key="tab.key"
          type="button"
          class="inline-flex shrink-0 items-center gap-1.5 border-b-2 px-3 py-3 text-xs font-semibold transition-colors"
          :class="pipelineTab === tab.key
            ? 'border-teal-500 text-teal-600'
            : 'border-transparent text-gray-500 hover:text-gray-700'"
          @click="pipelineTab = tab.key"
        >
          {{ t(tab.labelKey) }}
          <span
            class="rounded-full px-1.5 py-0.5 text-[10px] font-bold leading-none"
            :class="pipelineTab === tab.key ? 'bg-teal-100 text-teal-700' : 'bg-gray-100 text-gray-600'"
          >
            {{ tab.count.toLocaleString() }}
          </span>
        </button>
      </div>

      <div class="flex flex-col gap-3 border-b border-shell-border p-3 lg:flex-row lg:flex-wrap lg:items-center">
        <div class="relative min-w-0 flex-1 lg:min-w-[12rem]">
          <UIcon
            name="i-lucide-search"
            class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-shell-muted"
          />
          <input
            v-model="search"
            type="search"
            :class="[kutoInputClass, 'py-2 pl-9 pr-3 text-sm']"
            :placeholder="t('kuto.leads.list.searchPlaceholder')"
          >
        </div>
        <USelectMenu
          v-model="sourceFilter"
          :items="sourceFilterItems"
          value-key="value"
          :placeholder="t('kuto.leads.inbox.filters.source')"
          class="w-full sm:w-40"
          :ui="kutoSelectMenuUi"
        />
        <div class="flex items-center gap-1 rounded-lg border border-shell-border bg-white p-1">
          <button
            type="button"
            class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-semibold transition-colors"
            :class="viewMode === 'table' ? 'bg-teal-500 text-white' : 'text-shell-muted hover:bg-gray-50'"
            @click="viewMode = 'table'"
          >
            <UIcon
              name="i-lucide-table"
              class="size-3.5"
            />
            {{ t('kuto.leads.list.view.table') }}
          </button>
          <button
            type="button"
            class="inline-flex items-center gap-1 rounded-md px-2.5 py-1.5 text-xs font-semibold transition-colors"
            :class="viewMode === 'kanban' ? 'bg-teal-500 text-white' : 'text-shell-muted hover:bg-gray-50'"
            @click="viewMode = 'kanban'"
          >
            <UIcon
              name="i-lucide-columns-3"
              class="size-3.5"
            />
            {{ t('kuto.leads.list.view.kanban') }}
          </button>
        </div>
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
          {{ t('kuto.leads.list.clearFilters') }}
        </button>
      </div>

      <div
        v-if="selectedCount > 0"
        class="flex flex-wrap items-center gap-3 border-b border-shell-border bg-gray-50 px-4 py-2 text-sm"
      >
        <span class="font-medium text-shell-fg">
          {{ t('kuto.leads.list.bulk.selected', { count: selectedCount }) }}
        </span>
        <button
          type="button"
          class="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-3 py-1.5 text-xs font-semibold text-white opacity-60"
          disabled
        >
          <UIcon
            name="i-lucide-user-plus"
            class="size-3.5"
          />
          {{ t('kuto.leads.list.bulk.assign') }}
        </button>
        <span class="text-[11px] text-shell-muted">
          {{ t('kuto.leads.list.bulk.mockHint') }}
        </span>
      </div>

      <div v-if="viewMode === 'table'">
        <div class="overflow-x-auto">
          <table class="w-full min-w-[960px] text-left text-sm">
          <thead class="border-b border-shell-border bg-gray-50 text-xs font-semibold text-shell-muted">
            <tr>
              <th class="w-10 px-3 py-3">
                <input
                  type="checkbox"
                  class="size-4 rounded border-gray-300 text-teal-600 focus:ring-teal-500/30"
                  :checked="allVisibleSelected"
                  :aria-label="t('kuto.leads.list.selectAll')"
                  @change="toggleSelectAll"
                >
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.leads.list.col.leadId') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.leads.inbox.col.company') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.leads.inbox.col.contact') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.leads.inbox.col.source') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.leads.inbox.col.product') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.leads.inbox.col.score') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.leads.inbox.col.status') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.leads.inbox.col.priority') }}
              </th>
              <th class="px-3 py-3 text-center">
                {{ t('kuto.leads.inbox.col.action') }}
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
                selectedId === row.id ? 'bg-teal-50/60' : ''
              ]"
              @click="selectRow(row)"
            >
              <td class="px-3 py-3" @click.stop>
                <input
                  type="checkbox"
                  class="size-4 rounded border-gray-300 text-teal-600 focus:ring-teal-500/30"
                  :checked="selectedIds.has(row.id)"
                  @change="toggleRow(row)"
                >
              </td>
              <td class="px-3 py-3 font-mono text-xs font-semibold text-teal-700">
                {{ row.code }}
              </td>
              <td class="max-w-[11rem] truncate px-3 py-3 font-medium text-shell-fg">
                {{ row.company }}
              </td>
              <td class="max-w-[9rem] truncate px-3 py-3 text-shell-muted">
                {{ row.contact }}
              </td>
              <td class="px-3 py-3">
                <span
                  class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                  :class="kutoLeadSourceBadgeClass(row.sourceKey)"
                >
                  {{ t(row.sourceKey) }}
                </span>
              </td>
              <td class="max-w-[8rem] truncate px-3 py-3 text-shell-muted">
                {{ t(row.productKey) }}
              </td>
              <td class="px-3 py-3">
                <div class="flex min-w-[4rem] items-center gap-2">
                  <div class="h-1.5 flex-1 rounded-full bg-gray-200">
                    <div
                      class="h-1.5 rounded-full"
                      :style="{
                        width: `${row.score}%`,
                        backgroundColor: kutoLeadScoreColor(row.score)
                      }"
                    />
                  </div>
                  <span class="w-6 text-xs font-bold text-shell-muted">{{ row.score }}</span>
                </div>
              </td>
              <td class="px-3 py-3">
                <span
                  class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                  :class="kutoLeadStatusBadgeClass(row.statusKey)"
                >
                  {{ t(row.statusKey) }}
                </span>
              </td>
              <td class="px-3 py-3">
                <span
                  class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                  :class="kutoLeadPriorityBadgeClass(row.priorityKey)"
                >
                  {{ t(row.priorityKey) }}
                </span>
              </td>
              <td class="px-3 py-3 text-center" @click.stop>
                <NuxtLink
                  :to="`/app/leads/${row.id}`"
                  class="inline-flex size-8 items-center justify-center rounded-lg text-shell-muted hover:bg-gray-100 hover:text-teal-600"
                  :aria-label="t('kuto.leads.inbox.viewDetail')"
                  @click="selectRow(row)"
                >
                  <UIcon
                    name="i-lucide-eye"
                    class="size-4"
                  />
                </NuxtLink>
              </td>
            </tr>
          </tbody>
        </table>
        </div>

        <KutoPagination
          v-model:page="page"
          :total-items="totalItems"
          :total-pages="totalPages"
          :range-start="rangeStart"
          :range-end="rangeEnd"
          :page-size="pageSize"
        />
      </div>

      <div
        v-else
        class="grid gap-3 p-4 sm:grid-cols-2 xl:grid-cols-3"
      >
        <div
          v-for="col in kutoLeadKanbanColumns"
          :key="col.key"
          class="flex min-h-[12rem] flex-col rounded-lg border border-shell-border bg-gray-50/80"
        >
          <div class="border-b border-shell-border px-3 py-2 text-xs font-bold text-shell-fg">
            {{ t(col.labelKey) }}
            <span class="ml-1 text-shell-muted">({{ kanbanRowsFor(col.pipelineStatus).length }})</span>
          </div>
          <div class="flex flex-1 flex-col gap-2 p-2">
            <div
              v-for="row in kanbanRowsFor(col.pipelineStatus)"
              :key="row.id"
              class="rounded-lg border border-shell-border bg-white p-3 shadow-sm"
            >
              <p class="font-mono text-[10px] font-semibold text-teal-700">
                {{ row.code }}
              </p>
              <p class="mt-0.5 text-sm font-semibold text-shell-fg">
                {{ row.company }}
              </p>
              <p class="mt-1 text-xs text-shell-muted">
                {{ row.contact }}
              </p>
              <div class="mt-2 flex items-center justify-between text-xs">
                <span
                  class="font-bold"
                  :style="{ color: kutoLeadScoreColor(row.score) }"
                >
                  {{ row.score }}
                </span>
                <span class="text-shell-muted">{{ row.budget }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div
        v-if="!filteredRows.length"
        class="px-4 py-12 text-center text-sm text-shell-muted"
      >
        {{ t('kuto.leads.list.empty') }}
      </div>
      </div>

      <!-- การ์ดขวา 2 ใบ — โหมดตารางเท่านั้น -->
      <div
        v-if="viewMode === 'table' && selectedLead"
        class="hidden shrink-0 flex-col gap-4 lg:flex lg:sticky lg:top-4"
        :class="kutoInboxSidebarWidthClass"
      >
        <div
          class="flex flex-col gap-3 p-4"
          :class="kutoShellCardClass"
        >
          <div class="flex items-start justify-between gap-2">
            <p class="text-sm font-bold text-shell-fg">
              {{ t('kuto.leads.inbox.detail.quickTitle') }}
            </p>
            <span
              class="shrink-0 rounded-full px-2 py-0.5 text-[10px] font-semibold ring-1 ring-inset"
              :class="kutoLeadStatusBadgeClass(selectedLead.statusKey)"
            >
              {{ t(selectedLead.statusKey) }}
            </span>
          </div>

          <div>
            <h2 class="text-base font-bold leading-snug text-shell-fg">
              {{ selectedLead.company }}
            </h2>
            <p class="mt-0.5 font-mono text-[11px] font-semibold text-teal-700">
              {{ selectedLead.code }}
            </p>
          </div>

          <div>
            <div class="mb-1 flex items-center justify-between text-xs">
              <span class="font-medium text-shell-muted">{{ t('kuto.leads.inbox.detail.scoreLabel') }}</span>
              <span
                class="text-lg font-bold"
                :style="{ color: kutoLeadScoreColor(selectedLead.score) }"
              >
                {{ selectedLead.score }}
              </span>
            </div>
            <div class="h-2 rounded-full bg-gray-200">
              <div
                class="h-2 rounded-full transition-all"
                :style="{
                  width: `${selectedLead.score}%`,
                  backgroundColor: kutoLeadScoreColor(selectedLead.score)
                }"
              />
            </div>
          </div>

          <dl class="space-y-1.5 text-xs">
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.leads.inbox.detail.contact') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ selectedLead.contact }}
              </dd>
            </div>
            <div
              v-if="selectedLead.positionKey"
              class="flex justify-between gap-2"
            >
              <dt class="text-shell-muted">
                {{ t('kuto.leads.inbox.detail.position') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ t(selectedLead.positionKey) }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.leads.inbox.detail.phone') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ selectedLead.phone }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.leads.inbox.detail.email') }}
              </dt>
              <dd class="max-w-[9rem] truncate text-right font-medium text-shell-fg">
                {{ selectedLead.email }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.leads.inbox.col.sales') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ selectedLead.salesName ?? t('kuto.leads.inbox.unassigned') }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.leads.inbox.detail.source') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ t(selectedLead.sourceKey) }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.leads.inbox.detail.product') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ t(selectedLead.productKey) }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.leads.inbox.detail.budget') }}
              </dt>
              <dd class="text-right font-semibold text-shell-fg">
                {{ selectedLead.budget }}
              </dd>
            </div>
          </dl>

          <div class="rounded-lg border border-teal-100 bg-teal-50/80 px-3 py-2.5 text-xs leading-relaxed text-teal-800">
            <div class="mb-1 flex items-center gap-1 font-semibold">
              <UIcon
                name="i-lucide-lightbulb"
                class="size-3.5"
              />
              {{ t('kuto.leads.inbox.detail.aiTitle') }}
            </div>
            {{ t(selectedLead.aiInsightKey) }}
          </div>

          <div
            v-if="selectedLead.actionKey"
            class="rounded-lg bg-amber-50 px-3 py-2 text-xs font-semibold text-amber-800 ring-1 ring-amber-100"
          >
            {{ t('kuto.leads.inbox.detail.actionToday') }}: {{ t(selectedLead.actionKey) }}
          </div>

          <div class="grid grid-cols-2 gap-2">
            <button
              type="button"
              class="inline-flex items-center justify-center gap-1.5 rounded-lg bg-teal-500 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-teal-600"
            >
              <UIcon
                name="i-lucide-phone"
                class="size-4"
              />
              {{ t('kuto.leads.inbox.detail.call') }}
            </button>
            <button
              type="button"
              :class="[kutoControlClass, 'inline-flex items-center justify-center gap-1.5 py-2.5 text-sm font-semibold text-teal-700']"
            >
              <UIcon
                name="i-lucide-mail"
                class="size-4"
              />
              {{ t('kuto.leads.inbox.detail.emailAction') }}
            </button>
          </div>

          <NuxtLink
            :to="`/app/leads/${selectedLead.id}`"
            class="text-center text-xs font-semibold text-teal-600 hover:text-teal-700"
          >
            {{ t('kuto.leads.inbox.detail.openFull') }}
          </NuxtLink>
        </div>

        <div
          class="p-4"
          :class="kutoShellCardClass"
        >
          <p class="mb-3 text-sm font-bold text-shell-fg">
            {{ t('kuto.leads.inbox.channels.title') }}
          </p>
          <div class="space-y-2.5">
            <div
              v-for="bar in kutoInboxChannelBars"
              :key="bar.key"
              class="flex items-center gap-2 text-[11px]"
            >
              <span class="w-[4.5rem] shrink-0 truncate text-shell-muted">{{ t(bar.labelKey) }}</span>
              <div class="h-2 flex-1 rounded-full bg-gray-100">
                <div
                  class="h-2 rounded-full"
                  :style="{
                    width: `${(bar.value / channelMax) * 100}%`,
                    backgroundColor: bar.color
                  }"
                />
              </div>
              <span class="w-6 text-right font-semibold text-shell-fg">{{ bar.value }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
