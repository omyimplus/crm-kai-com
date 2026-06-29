<script setup lang="ts">
import {
  kutoContactHistoryRows,
  kutoContactHistoryTabs,
  type KutoContactHistoryRow,
  type KutoContactHistoryTabKey
} from '~/config/kutoContactHistoryMock'
import {
  kutoControlClass,
  kutoInputClass,
  kutoSelectMenuUi,
  kutoShellCardClass
} from '~/config/kutoTheme'
import {
  kutoContactHistoryStatusBadgeClass,
  kutoContactHistoryTypeColor
} from '~/utils/kutoContactHistoryBadges'

const { t } = useI18n()

type ViewMode = 'timeline' | 'table'

const activeTab = ref<KutoContactHistoryTabKey>('all')
const viewMode = ref<ViewMode>('timeline')
const search = ref('')
const selectedId = ref('1')

const contactHistoryFilterDefs = computed(() => [
  { key: 'contact', labelKey: 'kuto.customers.contactHistory.filters.contact' },
  { key: 'company', labelKey: 'kuto.customers.contactHistory.filters.company' },
  { key: 'type', labelKey: 'kuto.customers.contactHistory.filters.type' },
  { key: 'owner', labelKey: 'kuto.customers.contactHistory.filters.owner' },
  { key: 'dateRange', labelKey: 'kuto.customers.contactHistory.filters.dateRange' },
  { key: 'status', labelKey: 'kuto.customers.contactHistory.filters.status' },
  { key: 'opportunity', labelKey: 'kuto.customers.contactHistory.filters.opportunity' },
  { key: 'ticket', labelKey: 'kuto.customers.contactHistory.filters.ticket' }
] as const)

function mockFilterItems(labelKey: string) {
  const label = t(labelKey)
  return [{ label, value: undefined }]
}

function rowMatchesTab(row: KutoContactHistoryRow): boolean {
  if (activeTab.value === 'all') return true
  return row.tabTags.includes(activeTab.value)
}

const filteredRows = computed(() => {
  const q = search.value.trim().toLowerCase()
  return kutoContactHistoryRows.filter((row) => {
    if (!rowMatchesTab(row)) return false
    if (!q) return true
    return (
      t(row.titleKey).toLowerCase().includes(q)
      || row.contactName.toLowerCase().includes(q)
      || row.companyName.toLowerCase().includes(q)
      || row.ownerName.includes(q)
    )
  })
})

const groupedRows = computed(() => {
  const groups = new Map<string, KutoContactHistoryRow[]>()
  for (const row of filteredRows.value) {
    const key = row.dateGroupKey
    const list = groups.get(key) ?? []
    list.push(row)
    groups.set(key, list)
  }
  return [...groups.entries()].map(([groupKey, rows]) => ({ groupKey, rows }))
})

const selectedRow = computed(() =>
  kutoContactHistoryRows.find(r => r.id === selectedId.value)
)

function selectRow(row: KutoContactHistoryRow) {
  selectedId.value = row.id
}

function toggleViewMode() {
  viewMode.value = viewMode.value === 'timeline' ? 'table' : 'timeline'
}

function statusLabelKey(statusKey: string) {
  return `kuto.customers.contactHistory.status.${statusKey}` as const
}
</script>

<template>
  <div class="space-y-4">
    <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900">
          {{ t('kuto.customers.contactHistory.title') }}
        </h1>
        <p class="mt-1 text-sm text-shell-muted">
          {{ t('kuto.customers.contactHistory.subtitle') }}
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <NuxtLink
          to="/app/activities"
          :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-2 text-sm font-semibold text-shell-fg']"
        >
          <UIcon
            name="i-lucide-list-todo"
            class="size-4"
          />
          {{ t('kuto.customers.contactHistory.actions.myTasks') }}
        </NuxtLink>
        <button
          type="button"
          :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-2 text-sm font-semibold text-shell-fg']"
          @click="toggleViewMode"
        >
          <UIcon
            :name="viewMode === 'timeline' ? 'i-lucide-table' : 'i-lucide-list'"
            class="size-4"
          />
          {{ viewMode === 'timeline'
            ? t('kuto.customers.contactHistory.view.table')
            : t('kuto.customers.contactHistory.view.timeline') }}
        </button>
        <button
          type="button"
          class="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-4 py-2 text-sm font-semibold text-white opacity-60"
          disabled
        >
          <UIcon
            name="i-lucide-plus"
            class="size-4"
          />
          {{ t('kuto.customers.contactHistory.actions.add') }}
        </button>
      </div>
    </div>

    <div
      class="overflow-hidden"
      :class="kutoShellCardClass"
    >
      <div class="border-b border-shell-border p-3">
        <div class="flex flex-col gap-2 lg:flex-row lg:items-center">
          <div class="relative shrink-0 lg:w-56 xl:w-64">
            <UIcon
              name="i-lucide-search"
              class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-shell-muted"
            />
            <input
              v-model="search"
              type="search"
              :class="[kutoInputClass, 'py-2 pl-9 pr-3 text-sm']"
              :placeholder="t('kuto.customers.contactHistory.searchPlaceholder')"
            >
          </div>
          <div class="flex min-w-0 flex-1 items-center gap-2 overflow-x-auto pb-0.5">
            <USelectMenu
              v-for="filter in contactHistoryFilterDefs"
              :key="filter.key"
              :items="mockFilterItems(filter.labelKey)"
              value-key="value"
              :placeholder="t(filter.labelKey)"
              :ui="kutoSelectMenuUi"
              disabled
              class="w-36 shrink-0 opacity-60"
            />
          </div>
        </div>
      </div>

      <div class="flex gap-1 overflow-x-auto border-b border-shell-border px-4">
        <button
          v-for="tab in kutoContactHistoryTabs"
          :key="tab.key"
          type="button"
          class="inline-flex shrink-0 items-center gap-1.5 border-b-2 px-3 py-3 text-xs font-semibold transition-colors"
          :class="activeTab === tab.key
            ? 'border-teal-500 text-teal-600'
            : 'border-transparent text-gray-500 hover:text-gray-700'"
          @click="activeTab = tab.key"
        >
          {{ t(tab.labelKey) }}
          <span
            v-if="tab.count !== undefined"
            class="rounded-full px-1.5 py-0.5 text-[10px] font-bold leading-none"
            :class="activeTab === tab.key ? 'bg-teal-100 text-teal-700' : 'bg-gray-100 text-gray-600'"
          >
            {{ tab.count.toLocaleString() }}
          </span>
        </button>
      </div>

      <!-- Timeline view (figma default) -->
      <div
        v-if="viewMode === 'timeline'"
        class="p-4"
      >
        <div
          v-if="!filteredRows.length"
          class="py-12 text-center text-sm text-shell-muted"
        >
          {{ t('kuto.customers.contactHistory.empty') }}
        </div>

        <div
          v-for="group in groupedRows"
          :key="group.groupKey"
          class="mb-6 last:mb-0"
        >
          <h2 class="mb-3 text-xs font-bold uppercase tracking-wide text-shell-muted">
            {{ t(group.groupKey) }}
          </h2>
          <div class="space-y-2">
            <button
              v-for="row in group.rows"
              :key="row.id"
              type="button"
              class="flex w-full items-start gap-3 rounded-xl border border-shell-border bg-white p-3 text-left transition-colors hover:border-teal-200 hover:bg-teal-50/30"
              :class="selectedId === row.id ? 'border-teal-300 bg-teal-50/50 ring-1 ring-inset ring-teal-200/60' : ''"
              @click="selectRow(row)"
            >
              <span
                class="mt-0.5 flex size-9 shrink-0 items-center justify-center rounded-lg"
                :style="{
                  backgroundColor: `${kutoContactHistoryTypeColor(row.typeKey)}18`,
                  color: kutoContactHistoryTypeColor(row.typeKey)
                }"
              >
                <UIcon
                  :name="row.icon"
                  class="size-4"
                />
              </span>
              <div class="min-w-0 flex-1">
                <div class="flex flex-wrap items-center gap-2">
                  <p class="font-semibold text-shell-fg">
                    {{ t(row.titleKey) }}
                  </p>
                  <span
                    class="inline-flex rounded-full px-2 py-0.5 text-[10px] font-semibold ring-1 ring-inset"
                    :class="kutoContactHistoryStatusBadgeClass(row.statusKey)"
                  >
                    {{ t(statusLabelKey(row.statusKey)) }}
                  </span>
                </div>
                <p class="mt-1 text-xs text-shell-muted">
                  <span class="font-medium text-shell-fg">{{ row.contactName }}</span>
                  · {{ row.companyName }}
                  · {{ t(row.dateLabelKey) }} {{ row.timeLabel }}
                  · {{ t('kuto.customers.contactHistory.col.owner') }}: {{ row.ownerName }}
                  <template v-if="row.relatedOpp">
                    · <span class="font-mono font-semibold text-teal-700">{{ row.relatedOpp }}</span>
                  </template>
                  <template v-if="row.relatedTicket">
                    · <span class="font-mono font-semibold text-red-600">{{ row.relatedTicket }}</span>
                  </template>
                  <template v-if="row.relatedQuotation">
                    · <span class="font-mono font-semibold text-teal-700">{{ row.relatedQuotation }}</span>
                  </template>
                </p>
              </div>
              <UIcon
                name="i-lucide-chevron-right"
                class="mt-2 size-4 shrink-0 text-shell-muted"
              />
            </button>
          </div>
        </div>
      </div>

      <!-- Table view (toggle) -->
      <div
        v-else
        class="overflow-x-auto"
      >
        <table class="w-full min-w-[900px] text-left text-sm">
          <thead class="border-b border-shell-border bg-gray-50 text-xs font-semibold text-shell-muted">
            <tr>
              <th class="px-3 py-3">
                {{ t('kuto.customers.contactHistory.col.activity') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.customers.contactHistory.col.type') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.customers.contactHistory.col.contact') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.customers.contactHistory.col.company') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.customers.contactHistory.col.date') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.customers.contactHistory.col.owner') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.customers.contactHistory.col.status') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-shell-border">
            <tr
              v-for="row in filteredRows"
              :key="row.id"
              class="cursor-pointer hover:bg-teal-50/30"
              :class="selectedId === row.id ? 'bg-teal-50/40' : ''"
              @click="selectRow(row)"
            >
              <td class="px-3 py-3 font-medium text-shell-fg">
                {{ t(row.titleKey) }}
              </td>
              <td class="px-3 py-3 text-shell-muted">
                {{ t(`kuto.customers.contactHistory.tabs.${row.typeKey}`) }}
              </td>
              <td class="px-3 py-3">
                {{ row.contactName }}
              </td>
              <td class="px-3 py-3">
                {{ row.companyName }}
              </td>
              <td class="whitespace-nowrap px-3 py-3 text-shell-muted">
                {{ t(row.dateLabelKey) }} {{ row.timeLabel }}
              </td>
              <td class="px-3 py-3 text-shell-muted">
                {{ row.ownerName }}
              </td>
              <td class="px-3 py-3">
                <span
                  class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                  :class="kutoContactHistoryStatusBadgeClass(row.statusKey)"
                >
                  {{ t(statusLabelKey(row.statusKey)) }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

  <!-- Selected detail strip (figma chevron → open customer) -->
    <div
      v-if="selectedRow"
      class="flex flex-col gap-3 p-4 sm:flex-row sm:items-center sm:justify-between"
      :class="kutoShellCardClass"
    >
      <div class="min-w-0">
        <p class="text-sm font-semibold text-shell-fg">
          {{ t(selectedRow.titleKey) }}
        </p>
        <p class="mt-0.5 text-xs text-shell-muted">
          {{ selectedRow.contactName }} · {{ selectedRow.companyName }}
        </p>
      </div>
      <div class="flex flex-wrap gap-2">
        <NuxtLink
          :to="`/app/customers/${selectedRow.companyId}`"
          class="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-3 py-2 text-sm font-semibold text-white hover:bg-teal-600"
        >
          {{ t('kuto.customers.contactHistory.actions.openC360') }}
        </NuxtLink>
        <button
          type="button"
          class="rounded-lg border border-shell-border bg-white px-3 py-2 text-sm font-semibold text-shell-fg opacity-60"
          disabled
        >
          {{ t('kuto.customers.contactHistory.actions.openContact') }}
        </button>
      </div>
    </div>
  </div>
</template>
