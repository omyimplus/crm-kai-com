<script setup lang="ts">
import {
  kutoContactRecentActivities,
  kutoContactStatusTabs,
  kutoContactsListRows,
  kutoContactsListSummaryMeta,
  type KutoContactListRow,
  type KutoContactStatusTabKey
} from '~/config/kutoContactsListMock'
import {
  kutoControlClass,
  kutoInboxSidebarWidthClass,
  kutoInputClass,
  kutoKpiGridClass,
  kutoSelectMenuUi,
  kutoShellCardClass
} from '~/config/kutoTheme'
import {
  kutoContactRoleBadgeClass,
  kutoContactStatusBadgeClass
} from '~/utils/kutoContactBadges'

const { t } = useI18n()

const statusTab = ref<KutoContactStatusTabKey>('all')
const search = ref('')
const companyFilter = ref<string | undefined>(undefined)
const roleFilter = ref<string | undefined>(undefined)
const selectedIds = ref<Set<string>>(new Set())
const selectedId = ref('1')

const companyFilterItems = computed(() => [
  { label: t('kuto.customers.contacts.list.filters.company'), value: undefined },
  { label: 'กลุ่มซีเมนต์ไทย', value: 'scg' },
  { label: 'Bangkok Technology', value: 'bkk' },
  { label: 'Example Hospital', value: 'hospital' }
])

const roleFilterItems = computed(() => [
  { label: t('kuto.customers.contacts.list.filters.role'), value: undefined },
  { label: t('kuto.customers.contacts.list.roles.decisionMaker'), value: 'decisionMaker' },
  { label: t('kuto.customers.contacts.list.roles.purchasing'), value: 'purchasing' },
  { label: t('kuto.customers.contacts.list.roles.it'), value: 'it' }
])

/** ลำดับตาม Figma — บริษัท → ตำแหน่ง → แผนก → บทบาท → … */
const contactFilterDefs = computed(() => [
  { key: 'company', labelKey: 'kuto.customers.contacts.list.filters.company', interactive: true },
  { key: 'position', labelKey: 'kuto.customers.contacts.list.filters.position', interactive: false },
  { key: 'department', labelKey: 'kuto.customers.contacts.list.filters.department', interactive: false },
  { key: 'role', labelKey: 'kuto.customers.contacts.list.filters.role', interactive: true },
  { key: 'status', labelKey: 'kuto.customers.contacts.list.filters.status', interactive: false },
  { key: 'primary', labelKey: 'kuto.customers.contacts.list.filters.primary', interactive: false },
  { key: 'owner', labelKey: 'kuto.customers.contacts.list.filters.owner', interactive: false },
  { key: 'industry', labelKey: 'kuto.customers.contacts.list.filters.industry', interactive: false },
  { key: 'province', labelKey: 'kuto.customers.contacts.list.filters.province', interactive: false },
  { key: 'lastContact', labelKey: 'kuto.customers.contacts.list.filters.lastContact', interactive: false },
  { key: 'opportunity', labelKey: 'kuto.customers.contacts.list.filters.opportunity', interactive: false },
  { key: 'ticket', labelKey: 'kuto.customers.contacts.list.filters.ticket', interactive: false }
] as const)

function mockFilterItems(labelKey: string) {
  const label = t(labelKey)
  return [{ label, value: undefined }]
}

function rowMatchesTab(row: KutoContactListRow): boolean {
  if (statusTab.value === 'all') return true
  return row.tabTags.includes(statusTab.value)
}

const filteredRows = computed(() => {
  const q = search.value.trim().toLowerCase()
  return kutoContactsListRows.filter((row) => {
    if (!rowMatchesTab(row)) return false
    if (companyFilter.value === 'scg' && !row.companyName.includes('ซีเมนต์')) return false
    if (companyFilter.value === 'bkk' && !row.companyName.includes('Bangkok')) return false
    if (companyFilter.value === 'hospital' && !row.companyName.includes('Hospital')) return false
    if (roleFilter.value && !row.roleKey.includes(roleFilter.value)) return false
    if (!q) return true
    return (
      row.code.toLowerCase().includes(q)
      || row.fullName.toLowerCase().includes(q)
      || row.companyName.toLowerCase().includes(q)
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

const selectedContact = computed(() =>
  kutoContactsListRows.find(row => row.id === selectedId.value)
  ?? pagedItems.value[0]
  ?? filteredRows.value[0]
)

const selectedCount = computed(() => selectedIds.value.size)
const allVisibleSelected = computed(() =>
  pagedItems.value.length > 0
  && pagedItems.value.every(r => selectedIds.value.has(r.id))
)

function onKpiClick(tabKey: KutoContactStatusTabKey) {
  statusTab.value = tabKey
}

function selectRow(row: KutoContactListRow) {
  selectedId.value = row.id
}

function toggleSelectAll() {
  if (allVisibleSelected.value) {
    selectedIds.value = new Set()
  } else {
    selectedIds.value = new Set(pagedItems.value.map(r => r.id))
  }
}

function toggleRow(row: KutoContactListRow) {
  const next = new Set(selectedIds.value)
  if (next.has(row.id)) next.delete(row.id)
  else next.add(row.id)
  selectedIds.value = next
}

function clearFilters() {
  search.value = ''
  statusTab.value = 'all'
  companyFilter.value = undefined
  roleFilter.value = undefined
}

const hasActiveFilters = computed(() =>
  search.value.trim().length > 0
  || statusTab.value !== 'all'
  || companyFilter.value !== undefined
  || roleFilter.value !== undefined
)

watch([statusTab, companyFilter, roleFilter], () => {
  selectedIds.value = new Set()
})

watch(pagedItems, (rows) => {
  if (!rows.some(r => r.id === selectedId.value) && rows[0]) {
    selectedId.value = rows[0].id
  }
})
</script>

<template>
  <div class="space-y-4">
    <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900">
          {{ t('kuto.customers.contacts.list.title') }}
        </h1>
        <p class="mt-1 text-sm text-shell-muted">
          {{ t('kuto.customers.contacts.list.subtitle') }}
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <button
          type="button"
          :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-2 text-sm font-semibold opacity-60']"
          disabled
        >
          <UIcon
            name="i-lucide-download"
            class="size-4"
          />
          {{ t('kuto.customers.contacts.list.actions.export') }}
        </button>
        <button
          type="button"
          :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-2 text-sm font-semibold opacity-60']"
          disabled
        >
          <UIcon
            name="i-lucide-upload"
            class="size-4"
          />
          {{ t('kuto.customers.contacts.list.actions.import') }}
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
          {{ t('kuto.customers.contacts.list.actions.new') }}
        </button>
      </div>
    </div>

    <div :class="kutoKpiGridClass">
      <KutoKpiCard
        v-for="meta in kutoContactsListSummaryMeta"
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

    <div class="flex items-start gap-4">
      <div
        class="min-w-0 flex-1 overflow-hidden"
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
                :placeholder="t('kuto.customers.contacts.list.searchPlaceholder')"
              >
            </div>
            <div class="flex min-w-0 flex-1 items-center gap-2 overflow-x-auto pb-0.5">
            <template
              v-for="filter in contactFilterDefs"
              :key="filter.key"
            >
              <USelectMenu
                v-if="filter.key === 'company'"
                v-model="companyFilter"
                :items="companyFilterItems"
                value-key="value"
                :placeholder="t(filter.labelKey)"
                :ui="kutoSelectMenuUi"
                class="w-36 shrink-0"
              />
              <USelectMenu
                v-else-if="filter.key === 'role'"
                v-model="roleFilter"
                :items="roleFilterItems"
                value-key="value"
                :placeholder="t(filter.labelKey)"
                :ui="kutoSelectMenuUi"
                class="w-36 shrink-0"
              />
              <USelectMenu
                v-else
                :items="mockFilterItems(filter.labelKey)"
                value-key="value"
                :placeholder="t(filter.labelKey)"
                :ui="kutoSelectMenuUi"
                disabled
                class="w-36 shrink-0 opacity-60"
              />
            </template>
            <button
              v-if="hasActiveFilters"
              type="button"
              class="shrink-0 text-xs font-semibold text-teal-600 hover:text-teal-700"
              @click="clearFilters"
            >
              {{ t('kuto.customers.contacts.list.clearFilters') }}
            </button>
            </div>
          </div>
        </div>

        <div class="flex gap-1 overflow-x-auto border-b border-shell-border px-4">
          <button
            v-for="tab in kutoContactStatusTabs"
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
            {{ t('kuto.customers.contacts.list.bulk.selected', { count: selectedCount }) }}
          </span>
          <button
            type="button"
            class="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-3 py-1.5 text-xs font-semibold text-white opacity-60"
            disabled
          >
            {{ t('kuto.customers.contacts.list.bulk.update') }}
          </button>
          <span class="text-[11px] text-shell-muted">
            {{ t('kuto.customers.contacts.list.bulk.mockHint') }}
          </span>
        </div>

        <div class="overflow-x-auto">
          <table class="w-full min-w-[1050px] text-left text-sm">
            <thead class="border-b border-shell-border bg-gray-50 text-xs font-semibold text-shell-muted">
              <tr>
                <th class="w-10 px-3 py-3">
                  <input
                    type="checkbox"
                    class="size-4 rounded border-gray-300 text-teal-600 focus:ring-teal-500/30"
                    :checked="allVisibleSelected"
                    :aria-label="t('kuto.customers.contacts.list.selectAll')"
                    @change="toggleSelectAll"
                  >
                </th>
                <th class="min-w-[11rem] px-3 py-3">
                  {{ t('kuto.customers.contacts.list.col.contact') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.contacts.list.col.company') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.contacts.list.col.position') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.contacts.list.col.department') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.contacts.list.col.phone') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.contacts.list.col.email') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.contacts.list.col.role') }}
                </th>
                <th class="px-3 py-3 text-center">
                  {{ t('kuto.customers.contacts.list.col.primary') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.contacts.list.col.status') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.contacts.list.col.owner') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.customers.contacts.list.col.lastContact') }}
                </th>
                <th class="px-3 py-3 text-center">
                  {{ t('kuto.customers.contacts.list.col.actions') }}
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
                    <div class="min-w-0">
                      <p class="truncate font-medium text-shell-fg">
                        {{ row.fullName }}
                      </p>
                      <p class="font-mono text-[10px] font-semibold text-teal-700">
                        {{ row.code }}
                      </p>
                    </div>
                  </div>
                </td>
                <td class="max-w-[8rem] truncate px-3 py-3 text-shell-fg">
                  {{ row.companyName }}
                </td>
                <td class="max-w-[7rem] truncate px-3 py-3 text-shell-muted">
                  {{ row.jobTitle }}
                </td>
                <td class="max-w-[6rem] truncate px-3 py-3 text-shell-muted">
                  {{ row.department }}
                </td>
                <td class="whitespace-nowrap px-3 py-3 text-shell-muted">
                  {{ row.phone }}
                </td>
                <td class="max-w-[8rem] truncate px-3 py-3 text-teal-700">
                  {{ row.email }}
                </td>
                <td class="px-3 py-3">
                  <span
                    class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                    :class="kutoContactRoleBadgeClass(row.roleKey)"
                  >
                    {{ t(row.roleKey) }}
                  </span>
                </td>
                <td class="px-3 py-3 text-center">
                  <UIcon
                    v-if="row.isMainContact"
                    name="i-lucide-check"
                    class="mx-auto size-4 text-teal-600"
                  />
                  <span
                    v-else
                    class="text-shell-muted"
                  >—</span>
                </td>
                <td class="px-3 py-3">
                  <span
                    class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                    :class="kutoContactStatusBadgeClass(row.statusLabelKey)"
                  >
                    {{ t(row.statusLabelKey) }}
                  </span>
                </td>
                <td class="max-w-[7rem] truncate px-3 py-3 text-shell-muted">
                  {{ row.ownerName }}
                </td>
                <td class="whitespace-nowrap px-3 py-3 text-shell-muted">
                  {{ t(row.lastActivityKey) }}
                </td>
                <td
                  class="px-3 py-3"
                  @click.stop
                >
                  <div class="flex items-center justify-center gap-0.5">
                    <button
                      type="button"
                      class="inline-flex size-7 items-center justify-center rounded-md text-shell-muted hover:bg-gray-100 hover:text-teal-600"
                      :title="t('kuto.customers.contacts.list.actions.view')"
                      @click="selectRow(row)"
                    >
                      <UIcon
                        name="i-lucide-eye"
                        class="size-3.5"
                      />
                    </button>
                    <button
                      type="button"
                      class="inline-flex size-7 items-center justify-center rounded-md text-shell-muted opacity-50"
                      disabled
                    >
                      <UIcon
                        name="i-lucide-phone"
                        class="size-3.5"
                      />
                    </button>
                    <button
                      type="button"
                      class="inline-flex size-7 items-center justify-center rounded-md text-shell-muted opacity-50"
                      disabled
                    >
                      <UIcon
                        name="i-lucide-mail"
                        class="size-3.5"
                      />
                    </button>
                    <button
                      type="button"
                      class="inline-flex size-7 items-center justify-center rounded-md text-shell-muted opacity-50"
                      disabled
                    >
                      <UIcon
                        name="i-lucide-calendar-plus"
                        class="size-3.5"
                      />
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
          {{ t('kuto.customers.contacts.list.empty') }}
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
        v-if="selectedContact"
        class="hidden shrink-0 flex-col gap-4 lg:flex lg:sticky lg:top-4"
        :class="kutoInboxSidebarWidthClass"
      >
        <div
          class="flex flex-col gap-3 p-4"
          :class="kutoShellCardClass"
        >
          <p class="text-sm font-bold text-shell-fg">
            {{ t('kuto.customers.contacts.list.detail.quickTitle') }}
          </p>

          <div class="flex items-start gap-3">
            <span
              class="flex size-10 shrink-0 items-center justify-center rounded-xl text-sm font-bold text-white"
              :class="selectedContact.avatarBg"
            >
              {{ selectedContact.initials }}
            </span>
            <div class="min-w-0 flex-1">
              <h2 class="text-base font-bold leading-snug text-shell-fg">
                {{ selectedContact.fullName }}
              </h2>
              <p class="mt-0.5 text-xs text-shell-muted">
                {{ selectedContact.jobTitle }} · {{ selectedContact.department }}
              </p>
              <div class="mt-2 flex flex-wrap gap-1">
                <span
                  v-if="selectedContact.isMainContact"
                  class="inline-flex rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-semibold text-amber-800 ring-1 ring-inset ring-amber-200/80"
                >
                  {{ t('kuto.customers.contacts.list.badges.primary') }}
                </span>
                <span
                  class="inline-flex rounded-full px-2 py-0.5 text-[10px] font-semibold ring-1 ring-inset"
                  :class="kutoContactRoleBadgeClass(selectedContact.roleKey)"
                >
                  {{ t(selectedContact.roleKey) }}
                </span>
                <span
                  class="inline-flex rounded-full px-2 py-0.5 text-[10px] font-semibold ring-1 ring-inset"
                  :class="kutoContactStatusBadgeClass(selectedContact.statusLabelKey)"
                >
                  {{ t(selectedContact.statusLabelKey) }}
                </span>
              </div>
            </div>
          </div>

          <dl class="space-y-1.5 text-xs">
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.contacts.list.detail.company') }}
              </dt>
              <dd class="max-w-[9rem] truncate text-right font-medium text-shell-fg">
                {{ selectedContact.companyName }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.contacts.list.detail.department') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ selectedContact.department }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.contacts.list.detail.phone') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ selectedContact.phone }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.contacts.list.detail.email') }}
              </dt>
              <dd class="max-w-[9rem] truncate text-right font-medium text-teal-700">
                {{ selectedContact.email }}
              </dd>
            </div>
            <div
              v-if="selectedContact.lineId"
              class="flex justify-between gap-2"
            >
              <dt class="text-shell-muted">
                {{ t('kuto.customers.contacts.list.detail.line') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ selectedContact.lineId }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.contacts.list.detail.owner') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ selectedContact.ownerName }}
              </dd>
            </div>
            <div class="flex justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.contacts.list.detail.lastContact') }}
              </dt>
              <dd class="text-right font-medium text-shell-fg">
                {{ t(selectedContact.lastActivityKey) }}
              </dd>
            </div>
            <div class="flex items-center justify-between gap-2">
              <dt class="text-shell-muted">
                {{ t('kuto.customers.contacts.list.detail.satisfaction') }}
              </dt>
              <dd class="flex gap-0.5">
                <UIcon
                  v-for="i in 5"
                  :key="i"
                  name="i-lucide-star"
                  class="size-3.5"
                  :class="i <= selectedContact.starRating ? 'text-amber-400' : 'text-gray-200'"
                />
              </dd>
            </div>
          </dl>

          <div
            v-if="selectedContact.relatedOpp || selectedContact.relatedQuotation || selectedContact.relatedTicket"
            class="space-y-1 rounded-lg bg-gray-50 p-2.5 text-[11px]"
          >
            <p class="font-semibold text-shell-fg">
              {{ t('kuto.customers.contacts.list.detail.relatedTitle') }}
            </p>
            <p
              v-if="selectedContact.relatedOpp"
              class="text-shell-muted"
            >
              {{ t('kuto.customers.contacts.list.detail.relatedOpp') }}: <span class="font-mono font-semibold text-teal-700">{{ selectedContact.relatedOpp }}</span>
            </p>
            <p
              v-if="selectedContact.relatedQuotation"
              class="text-shell-muted"
            >
              {{ t('kuto.customers.contacts.list.detail.relatedQuotation') }}: <span class="font-mono font-semibold text-teal-700">{{ selectedContact.relatedQuotation }}</span>
            </p>
            <p
              v-if="selectedContact.relatedTicket"
              class="text-shell-muted"
            >
              {{ t('kuto.customers.contacts.list.detail.relatedTicket') }}: <span class="font-mono font-semibold text-teal-700">{{ selectedContact.relatedTicket }}</span>
            </p>
          </div>

          <div class="rounded-lg border border-teal-100 bg-teal-50/80 px-3 py-2.5 text-xs leading-relaxed text-teal-800">
            <div class="mb-1 flex items-center gap-1 font-semibold">
              <UIcon
                name="i-lucide-sparkles"
                class="size-3.5"
              />
              {{ t('kuto.customers.contacts.list.detail.aiTitle') }}
            </div>
            {{ t(selectedContact.aiInsightKey) }}
          </div>

          <button
            type="button"
            class="inline-flex w-full items-center justify-center gap-1.5 rounded-lg bg-teal-500 py-2.5 text-sm font-semibold text-white opacity-60"
            disabled
          >
            <UIcon
              name="i-lucide-phone"
              class="size-4"
            />
            {{ t('kuto.customers.contacts.list.actions.call') }}
          </button>

          <div class="grid grid-cols-2 gap-2">
            <button
              type="button"
              class="rounded-lg border border-shell-border bg-white px-2 py-2 text-[11px] font-semibold text-shell-fg opacity-60"
              disabled
            >
              {{ t('kuto.customers.contacts.list.actions.email') }}
            </button>
            <button
              type="button"
              class="rounded-lg border border-shell-border bg-white px-2 py-2 text-[11px] font-semibold text-shell-fg opacity-60"
              disabled
            >
              {{ t('kuto.customers.contacts.list.actions.addActivity') }}
            </button>
            <button
              type="button"
              class="rounded-lg border border-shell-border bg-white px-2 py-2 text-[11px] font-semibold text-shell-fg opacity-60"
              disabled
            >
              {{ t('kuto.customers.contacts.list.actions.addOpp') }}
            </button>
            <button
              type="button"
              class="rounded-lg border border-shell-border bg-white px-2 py-2 text-[11px] font-semibold text-shell-fg opacity-60"
              disabled
            >
              {{ t('kuto.customers.contacts.list.actions.addTicket') }}
            </button>
          </div>

          <NuxtLink
            :to="`/app/customers/${selectedContact.companyId}`"
            class="text-center text-xs font-semibold text-teal-600 hover:text-teal-700"
          >
            {{ t('kuto.customers.contacts.list.actions.openDetail') }}
          </NuxtLink>
        </div>

        <div
          class="p-4"
          :class="kutoShellCardClass"
        >
          <p class="mb-3 text-sm font-bold text-shell-fg">
            {{ t('kuto.customers.contacts.list.recent.title') }}
          </p>
          <div class="space-y-3">
            <div
              v-for="item in kutoContactRecentActivities"
              :key="item.key"
              class="flex gap-2.5 text-xs"
            >
              <span
                class="mt-0.5 flex size-7 shrink-0 items-center justify-center rounded-lg"
                :style="{ backgroundColor: `${item.color}18`, color: item.color }"
              >
                <UIcon
                  :name="item.icon"
                  class="size-3.5"
                />
              </span>
              <div class="min-w-0 flex-1">
                <p class="font-medium text-shell-fg">
                  {{ t(item.titleKey) }}
                </p>
                <p class="text-[11px] text-shell-muted">
                  {{ t(item.dateKey) }}
                </p>
              </div>
            </div>
          </div>
          <NuxtLink
            to="/app/customers/contact-history"
            class="mt-3 block w-full text-center text-xs font-semibold text-teal-600 hover:text-teal-700"
          >
            {{ t('kuto.customers.contacts.list.recent.viewAll') }}
          </NuxtLink>
        </div>
      </div>
    </div>
  </div>
</template>
