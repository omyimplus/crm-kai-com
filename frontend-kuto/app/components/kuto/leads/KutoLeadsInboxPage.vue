<script setup lang="ts">
import {
  kutoInboxChannelBars,
  kutoLeadScoreColor,
  kutoLeadsInboxChips,
  kutoLeadsInboxRows,
  kutoLeadsInboxSummary,
  type KutoInboxLeadRow
} from '~/config/kutoLeadsInboxMock'
import {
  kutoControlClass,
  kutoInboxSidebarWidthClass,
  kutoInputClass,
  kutoKpiGridClass,
  kutoSelectMenuUi,
  kutoShellCardClass
} from '~/config/kutoTheme'

const { t } = useI18n()

const activeChip = ref('newToday')
const search = ref('')
const selectedId = ref('3')

const filterSource = ref<string | undefined>(undefined)
const filterStatus = ref<string | undefined>(undefined)
const filterScore = ref<string | undefined>(undefined)
const filterSales = ref<string | undefined>(undefined)
const filterDate = ref<string | undefined>(undefined)
const filterProduct = ref<string | undefined>(undefined)

const sourceFilterItems = computed(() => [
  { label: t('kuto.leads.inbox.filters.source'), value: undefined },
  { label: t('kuto.leads.inbox.sources.website'), value: 'website' },
  { label: t('kuto.leads.inbox.sources.lineOa'), value: 'lineOa' }
])

const statusFilterItems = computed(() => [
  { label: t('kuto.leads.inbox.filters.status'), value: undefined },
  { label: t('kuto.leads.inbox.status.new'), value: 'new' },
  { label: t('kuto.leads.inbox.status.pending'), value: 'pending' }
])

const scoreFilterItems = computed(() => [
  { label: t('kuto.leads.inbox.filters.score'), value: undefined },
  { label: t('kuto.leads.inbox.filters.scoreHigh'), value: 'high' },
  { label: t('kuto.leads.inbox.filters.scoreLow'), value: 'low' }
])

const salesFilterItems = computed(() => [
  { label: t('kuto.leads.inbox.filters.sales'), value: undefined },
  { label: t('kuto.sidebar.userName'), value: 'nicha' },
  { label: 'สมศักดิ์ ใจดี', value: 'somsak' }
])

const dateFilterItems = computed(() => [
  { label: t('kuto.leads.inbox.filters.dateCreated'), value: undefined },
  { label: t('kuto.dashboard.period.today'), value: 'today' },
  { label: t('kuto.dashboard.period.week'), value: 'week' }
])

const productFilterItems = computed(() => [
  { label: t('kuto.leads.inbox.filters.product'), value: undefined },
  { label: t('kuto.leads.inbox.products.m365'), value: 'm365' },
  { label: t('kuto.leads.inbox.products.firewall'), value: 'firewall' }
])

const filteredRows = computed(() => {
  const q = search.value.trim().toLowerCase()
  return kutoLeadsInboxRows.filter((row) => {
    if (!q) return true
    return (
      row.code.toLowerCase().includes(q)
      || row.company.toLowerCase().includes(q)
      || row.contact.toLowerCase().includes(q)
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
} = useKutoPagination(filteredRows, 3)

const selectedLead = computed(() =>
  kutoLeadsInboxRows.find(row => row.id === selectedId.value) ?? pagedItems.value[0] ?? filteredRows.value[0]
)

watch(pagedItems, (rows) => {
  if (!rows.some(r => r.id === selectedId.value) && rows[0]) {
    selectedId.value = rows[0].id
  }
})

function selectRow(row: KutoInboxLeadRow) {
  selectedId.value = row.id
}

function statusBadgeClass(statusKey: string) {
  if (statusKey.includes('new')) return 'bg-blue-50 text-blue-700 ring-blue-200/80'
  if (statusKey.includes('pending')) return 'bg-amber-50 text-amber-700 ring-amber-200/80'
  if (statusKey.includes('review')) return 'bg-violet-50 text-violet-700 ring-violet-200/80'
  return 'bg-gray-50 text-gray-600 ring-gray-200/80'
}

function priorityBadgeClass(priorityKey: string) {
  if (priorityKey.includes('urgent')) return 'bg-red-50 text-red-700 ring-red-200/80'
  if (priorityKey.includes('high')) return 'bg-orange-50 text-orange-700 ring-orange-200/80'
  if (priorityKey.includes('normal')) return 'bg-sky-50 text-sky-700 ring-sky-200/80'
  if (priorityKey.includes('low')) return 'bg-gray-50 text-gray-500 ring-gray-200/80'
  return 'bg-gray-50 text-gray-600 ring-gray-200/80'
}

function sourceBadgeClass(sourceKey: string) {
  if (sourceKey.includes('website')) return 'bg-blue-50 text-blue-700 ring-blue-200/80'
  if (sourceKey.includes('lineOa')) return 'bg-violet-50 text-violet-700 ring-violet-200/80'
  if (sourceKey.includes('facebook')) return 'bg-indigo-50 text-indigo-700 ring-indigo-200/80'
  if (sourceKey.includes('marketplace')) return 'bg-amber-50 text-amber-700 ring-amber-200/80'
  if (sourceKey.includes('tender')) return 'bg-teal-50 text-teal-700 ring-teal-200/80'
  return 'bg-gray-50 text-gray-600 ring-gray-200/80'
}

const channelMax = Math.max(...kutoInboxChannelBars.map(b => b.value))
</script>

<template>
  <div class="space-y-4">
    <div>
      <h1 class="text-2xl font-bold tracking-tight text-gray-900">
        {{ t('kuto.leads.inbox.title') }}
      </h1>
      <p class="mt-1 text-sm text-shell-muted">
        {{ t('kuto.leads.inbox.subtitle') }}
      </p>
    </div>

    <!-- KPI เต็มความกว้าง -->
    <div :class="kutoKpiGridClass">
      <div
        v-for="card in kutoLeadsInboxSummary"
        :key="card.key"
        class="relative overflow-hidden rounded-xl bg-white shadow-[0_1px_3px_rgba(15,23,42,0.08)]"
        :style="{ borderLeft: `4px solid ${card.accent}` }"
      >
        <div class="flex items-start justify-between gap-2 py-3 pl-3.5 pr-3.5">
          <p class="text-xs font-medium text-gray-500">
            {{ t(card.labelKey) }}
          </p>
          <div
            class="flex size-8 shrink-0 items-center justify-center rounded-full"
            :class="card.iconBg"
          >
            <UIcon
              :name="card.icon"
              class="size-4"
            />
          </div>
        </div>
        <div class="px-3.5 pb-3.5">
          <div class="flex items-end gap-2">
            <p
              class="text-2xl font-bold leading-none"
              :style="{ color: card.accent }"
            >
              {{ card.value }}
            </p>
            <span
              v-if="card.trend"
              class="text-[11px] font-semibold"
              :class="card.trendDown ? 'text-red-500' : 'text-emerald-600'"
            >
              {{ card.trend }}
            </span>
          </div>
          <p
            v-if="card.subKey"
            class="mt-1.5 text-[11px] text-gray-400"
          >
            {{ t(card.subKey) }}
          </p>
        </div>
      </div>
    </div>

    <!-- ตารางซ้าย + การ์ดขวา 2 ใบ (ตรง figma — ไม่ใช่ split rail เต็มความสูง) -->
    <div class="flex items-start gap-4">
      <div
        class="min-w-0 flex-1 overflow-hidden"
        :class="kutoShellCardClass"
      >
        <div class="flex gap-1 overflow-x-auto border-b border-shell-border px-4">
          <button
            v-for="chip in kutoLeadsInboxChips"
            :key="chip.key"
            type="button"
            class="inline-flex shrink-0 items-center gap-1.5 border-b-2 px-3 py-3 text-xs font-semibold transition-colors"
            :class="activeChip === chip.key
              ? 'border-teal-500 text-teal-600'
              : 'border-transparent text-gray-500 hover:text-gray-700'"
            @click="activeChip = chip.key"
          >
            {{ t(chip.labelKey) }}
            <span
              v-if="chip.count !== undefined"
              class="rounded-full px-1.5 py-0.5 text-[10px] font-bold leading-none"
              :class="activeChip === chip.key ? 'bg-teal-100 text-teal-700' : 'bg-gray-100 text-gray-600'"
            >
              {{ chip.count }}
            </span>
          </button>
        </div>

        <div class="flex flex-col gap-2 border-b border-shell-border p-3 lg:flex-row lg:flex-wrap lg:items-center">
          <div class="relative min-w-0 flex-1 lg:min-w-[10rem]">
            <UIcon
              name="i-lucide-search"
              class="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-shell-muted"
            />
            <input
              v-model="search"
              type="search"
              :class="[kutoInputClass, 'py-2 pl-9 pr-3 text-sm']"
              :placeholder="t('kuto.leads.inbox.searchPlaceholder')"
            >
          </div>
          <USelectMenu
            v-model="filterSource"
            :items="sourceFilterItems"
            value-key="value"
            :placeholder="t('kuto.leads.inbox.filters.source')"
            class="w-full sm:w-36"
            :ui="kutoSelectMenuUi"
          />
          <USelectMenu
            v-model="filterStatus"
            :items="statusFilterItems"
            value-key="value"
            :placeholder="t('kuto.leads.inbox.filters.status')"
            class="w-full sm:w-36"
            :ui="kutoSelectMenuUi"
          />
          <USelectMenu
            v-model="filterScore"
            :items="scoreFilterItems"
            value-key="value"
            :placeholder="t('kuto.leads.inbox.filters.score')"
            class="w-full sm:w-32"
            :ui="kutoSelectMenuUi"
          />
          <USelectMenu
            v-model="filterSales"
            :items="salesFilterItems"
            value-key="value"
            :placeholder="t('kuto.leads.inbox.filters.sales')"
            class="w-full sm:w-32"
            :ui="kutoSelectMenuUi"
          />
          <USelectMenu
            v-model="filterDate"
            :items="dateFilterItems"
            value-key="value"
            :placeholder="t('kuto.leads.inbox.filters.dateCreated')"
            class="w-full sm:w-32"
            :ui="kutoSelectMenuUi"
          />
          <USelectMenu
            v-model="filterProduct"
            :items="productFilterItems"
            value-key="value"
            :placeholder="t('kuto.leads.inbox.filters.product')"
            class="w-full sm:w-36"
            :ui="kutoSelectMenuUi"
          />
        </div>

        <div class="overflow-x-auto">
          <table class="w-full min-w-[900px] text-left text-sm">
            <thead class="border-b border-shell-border bg-gray-50 text-xs font-semibold text-shell-muted">
              <tr>
                <th class="px-4 py-3">
                  {{ t('kuto.leads.inbox.col.code') }}
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
                <th class="px-3 py-3">
                  {{ t('kuto.leads.inbox.col.sales') }}
                </th>
                <th class="px-3 py-3">
                  {{ t('kuto.leads.inbox.col.date') }}
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
                class="cursor-pointer transition-colors hover:bg-teal-50/40"
                :class="selectedId === row.id ? 'bg-teal-50/60' : ''"
                @click="selectRow(row)"
              >
                <td class="px-4 py-3 font-mono text-xs font-semibold text-teal-700">
                  {{ row.code }}
                </td>
                <td class="max-w-[10rem] truncate px-3 py-3 font-medium text-shell-fg">
                  {{ row.company }}
                </td>
                <td class="max-w-[8rem] truncate px-3 py-3 text-shell-muted">
                  {{ row.contact }}
                </td>
                <td class="px-3 py-3">
                  <span
                    class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                    :class="sourceBadgeClass(row.sourceKey)"
                  >
                    {{ t(row.sourceKey) }}
                  </span>
                </td>
                <td class="max-w-[8rem] truncate px-3 py-3 text-shell-muted">
                  {{ t(row.productKey) }}
                </td>
                <td class="px-3 py-3">
                  <div class="flex min-w-[4.5rem] items-center gap-2">
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
                    :class="statusBadgeClass(row.statusKey)"
                  >
                    {{ t(row.statusKey) }}
                  </span>
                </td>
                <td class="px-3 py-3">
                  <span
                    class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                    :class="priorityBadgeClass(row.priorityKey)"
                  >
                    {{ t(row.priorityKey) }}
                  </span>
                </td>
                <td class="px-3 py-3 text-shell-muted">
                  {{ row.salesName ?? t('kuto.leads.inbox.unassigned') }}
                </td>
                <td class="whitespace-nowrap px-3 py-3 text-shell-muted">
                  {{ row.createdAt }}
                </td>
                <td class="px-3 py-3 text-center">
                  <button
                    type="button"
                    class="inline-flex size-8 items-center justify-center rounded-lg text-shell-muted hover:bg-gray-100 hover:text-teal-600"
                    :aria-label="t('kuto.leads.inbox.viewDetail')"
                    @click.stop="selectRow(row)"
                  >
                    <UIcon
                      name="i-lucide-eye"
                      class="size-4"
                    />
                  </button>
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

      <!-- การ์ดขวา 2 ใบ แยกกัน -->
      <div
        v-if="selectedLead"
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
              class="shrink-0 rounded-full bg-amber-50 px-2 py-0.5 text-[10px] font-semibold text-amber-700 ring-1 ring-amber-200/80"
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

          <button
            type="button"
            class="text-center text-xs font-semibold text-teal-600 hover:text-teal-700"
          >
            {{ t('kuto.leads.inbox.detail.openFull') }}
          </button>
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
