<script setup lang="ts">
import type { Lead, LeadSource, ModuleStatus } from '~/types/crm'
import { appTableGridViewOptions, type AppTableGridViewMode } from '~/config/appViewMode'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTableTextClass
} from '~/config/appFormUi'
import {
  leadDisplayName,
  filterLeadRows,
  sortLeadRows,
  type LeadDateField
} from '~/utils/masterLeads'
import { currentMonthDateRange, getActiveModuleStatuses } from '~/utils/masterTasks'
import { useLeadStatusLabel } from '~/composables/useLeadStatusLabel'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { leadStatusLabel } = useLeadStatusLabel()
const { ensureProfile } = useProfile()
const { ensurePermissions, canWriteModule } = usePermissions()
const { list, remove, ensureDefaults } = useLeads()
const { listByModule } = useModuleStatuses()
const { list: listLeadSources } = useLeadSources()

await ensureProfile()
await ensurePermissions()

const listLayoutOptions = computed(() => appTableGridViewOptions(t))
const listLayout = ref<AppTableGridViewMode>('table')

const leads = ref<Lead[]>([])
const statuses = ref<ModuleStatus[]>([])
const leadSources = ref<LeadSource[]>([])
const loading = ref(true)
const search = ref('')
const statusFilter = ref<string | null>(null)
const sourceFilter = ref<string | null>(null)
const hotFilter = ref(false)
const defaultDateRange = currentMonthDateRange()
const scheduleFrom = ref(defaultDateRange.from)
const scheduleTo = ref(defaultDateRange.to)
const dateField = ref<LeadDateField>('created')
const deleteOpen = ref(false)
const deleteTarget = ref<Lead | null>(null)

const canWrite = computed(() => canWriteModule('app.lead'))

const statusChips = computed(() =>
  getActiveModuleStatuses(statuses.value).map(row => ({
    code: row.status_code,
    label: leadStatusLabel(row.status_code, row.name),
    color: row.color ?? '#94a3b8'
  }))
)

const sourceOptions = computed(() => [
  { label: t('leads.filters.allSources'), value: null as string | null },
  ...leadSources.value
    .filter(row => row.status === 'active')
    .map(row => ({
      label: row.name,
      value: row.id
    }))
])

const dateFieldOptions = computed(() => [
  { label: t('leads.filters.dateField.created'), value: 'created' as const },
  { label: t('leads.filters.dateField.nextAction'), value: 'next_action' as const }
])

function isDefaultDateRange(): boolean {
  const range = currentMonthDateRange()
  return scheduleFrom.value === range.from && scheduleTo.value === range.to
}

const activeFilterLabel = computed(() => {
  if (hotFilter.value) return t('leads.filters.hotOnly')
  if (statusFilter.value) {
    return leadStatusLabel(
      statusFilter.value,
      statuses.value.find(row => row.status_code === statusFilter.value)?.name
    )
  }
  return t('leads.filters.allStatuses')
})

async function refresh() {
  loading.value = true
  try {
    await ensureDefaults()
    const [statusRows, sourceRows] = await Promise.all([
      listByModule('lead'),
      listLeadSources()
    ])
    statuses.value = statusRows
    leadSources.value = sourceRows
    leads.value = await list()
  } catch (error) {
    console.error(error)
    leads.value = []
    statuses.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

const listFilterOptions = computed(() => ({
  statusFilter: statusFilter.value,
  sourceFilter: sourceFilter.value,
  dateRange: {
    from: scheduleFrom.value,
    to: scheduleTo.value
  },
  dateField: dateField.value,
  search: search.value,
  statusLabel: leadStatusLabel
}))

/** การ์ดสรุป — ตามตัวกรองทั้งหมด ยกเว้นกรอง「ลีดร้อนแรง」 (ให้เห็นจำนวน hot ในชุดที่กรองแล้ว) */
const summaryLeads = computed(() =>
  filterLeadRows(leads.value, listFilterOptions.value)
)

const filteredLeads = computed(() =>
  sortLeadRows(filterLeadRows(leads.value, {
    ...listFilterOptions.value,
    hotFilter: hotFilter.value
  }))
)

const hasActiveFilters = computed(() =>
  search.value.trim().length > 0
  || statusFilter.value !== null
  || sourceFilter.value !== null
  || hotFilter.value
  || !isDefaultDateRange()
  || dateField.value !== 'created'
)

const {
  page,
  pagedItems,
  totalItems: paginationTotal,
  totalPages,
  rangeStart,
  rangeEnd,
  pageSize,
  resetPage: resetPagination
} = usePagination(filteredLeads)

watch([search, statusFilter, sourceFilter, hotFilter, scheduleFrom, scheduleTo, dateField], () => resetPagination())

function selectStatus(code: string | null) {
  statusFilter.value = code
  hotFilter.value = false
  resetPagination()
}

function toggleHotFilter() {
  hotFilter.value = !hotFilter.value
  if (hotFilter.value) statusFilter.value = null
  resetPagination()
}

function showAllLeads() {
  hotFilter.value = false
  statusFilter.value = null
  resetPagination()
}

function clearFilters() {
  search.value = ''
  statusFilter.value = null
  sourceFilter.value = null
  hotFilter.value = false
  dateField.value = 'created'
  const range = currentMonthDateRange()
  scheduleFrom.value = range.from
  scheduleTo.value = range.to
}

function openEdit(lead: Lead) {
  navigateTo(`/app/leads/${lead.id}/edit`)
}

function openDelete(lead: Lead) {
  deleteTarget.value = lead
  deleteOpen.value = true
}

async function confirmDelete() {
  if (!deleteTarget.value) return
  try {
    await remove(deleteTarget.value.id)
    deleteOpen.value = false
    deleteTarget.value = null
    await refresh()
  } catch (error) {
    console.error(error)
  }
}
</script>

<template>
  <div class="space-y-5">
    <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold font-heading text-gray-900 dark:text-gray-100">
          {{ t('leads.pageTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('leads.pageSubtitle') }}
        </p>
      </div>
      <UButton
        v-if="canWrite"
        to="/app/leads/new"
        color="primary"
        size="lg"
        icon="i-lucide-plus"
      >
        {{ t('leads.newLead') }}
      </UButton>
    </div>

    <LeadsSummaryCards
      :leads="summaryLeads"
      :hot-filter-active="hotFilter"
      :filtered="hasActiveFilters"
      @toggle-hot="toggleHotFilter"
      @show-all="showAllLeads"
    />

    <UCard>
      <div class="space-y-4">
        <div class="flex flex-col gap-3 lg:flex-row lg:items-center">
          <UInput
            v-model="search"
            icon="i-lucide-search"
            :placeholder="t('leads.filters.searchPlaceholder')"
            :class="[appFormFieldClass, 'min-w-0 flex-1']"
            :ui="appInputUi"
          />

          <USelectMenu
            v-model="dateField"
            :items="dateFieldOptions"
            value-key="value"
            :class="[appFormFieldClass, 'w-full sm:w-[11rem]']"
            :ui="appSelectMenuUi"
          />

          <AppDateRangeFilter
            v-model:from="scheduleFrom"
            v-model:to="scheduleTo"
            :group-aria-label="t('leads.filters.dateRange')"
            :from-aria-label="t('leads.filters.dateFrom')"
            :to-aria-label="t('leads.filters.dateTo')"
          />

          <USelectMenu
            v-model="sourceFilter"
            :items="sourceOptions"
            value-key="value"
            :class="[appFormFieldClass, 'w-full sm:w-[12rem]']"
            :ui="appSelectMenuUi"
            :placeholder="t('leads.filters.allSources')"
          />

          <div class="flex flex-wrap items-center gap-2 lg:shrink-0">
            <AppViewModeToggle
              v-model="listLayout"
              :options="listLayoutOptions"
              :group-aria-label="t('common.viewMode.groupLabel')"
            />

            <UButton
              v-if="hasActiveFilters"
              variant="soft"
              color="neutral"
              icon="i-lucide-rotate-ccw"
              @click="clearFilters"
            >
              {{ t('leads.filters.clear') }}
            </UButton>
          </div>
        </div>

        <div
          v-if="statusChips.length"
          class="flex flex-wrap gap-2"
          role="group"
          :aria-label="t('leads.filters.statusTabs')"
        >
          <UButton
            size="sm"
            :variant="statusFilter === null && !hotFilter ? 'solid' : 'soft'"
            :color="statusFilter === null && !hotFilter ? 'primary' : 'neutral'"
            @click="selectStatus(null)"
          >
            {{ t('leads.filters.allStatuses') }}
          </UButton>
          <UButton
            v-for="chip in statusChips"
            :key="chip.code"
            size="sm"
            variant="outline"
            color="neutral"
            :class="statusFilter === chip.code ? 'ring-2 ring-offset-1' : ''"
            :style="statusFilter === chip.code
              ? { borderColor: chip.color, color: chip.color, '--tw-ring-color': chip.color }
              : { borderColor: `${chip.color}55` }"
            @click="selectStatus(chip.code)"
          >
            {{ chip.label }}
          </UButton>
        </div>
      </div>
    </UCard>

    <UCard v-if="loading">
      <p class="text-gray-500 dark:text-gray-400">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!leads.length">
      <div class="py-8 text-center">
        <p class="text-gray-600 dark:text-gray-300">
          {{ t('leads.emptyAll') }}
        </p>
        <UButton
          v-if="canWrite"
          class="mt-4"
          to="/app/leads/new"
          color="primary"
          icon="i-lucide-plus"
        >
          {{ t('leads.createFirst') }}
        </UButton>
      </div>
    </UCard>

    <div v-else>
      <p
        class="mb-3 text-gray-600 dark:text-gray-400"
        :class="appTableTextClass"
      >
        {{
          t('leads.filters.displayCount', {
            count: paginationTotal,
            filter: activeFilterLabel
          })
        }}
      </p>

      <div
        v-if="!filteredLeads.length"
        class="rounded-2xl border border-gray-200 bg-white px-4 py-10 text-center dark:border-gray-800 dark:bg-gray-900"
      >
        <p class="text-gray-500 dark:text-gray-400">
          {{ t('leads.filters.noResults') }}
        </p>
        <UButton
          class="mt-4"
          size="sm"
          variant="soft"
          icon="i-lucide-rotate-ccw"
          @click="clearFilters"
        >
          {{ t('leads.filters.clear') }}
        </UButton>
      </div>

      <template v-else>
        <div
          v-if="listLayout === 'table'"
          class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
        >
          <LeadsLeadTable
            :leads="pagedItems"
            :can-write="canWrite"
            @edit="openEdit"
            @delete="openDelete"
          />
        </div>

        <div
          v-else
          class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3"
        >
          <LeadsLeadCard
            v-for="lead in pagedItems"
            :key="lead.id"
            :lead="lead"
            :can-write="canWrite"
            @edit="openEdit"
            @delete="openDelete"
          />
        </div>

        <AppPagination
          v-model:page="page"
          class="mt-4"
          :total-items="paginationTotal"
          :total-pages="totalPages"
          :range-start="rangeStart"
          :range-end="rangeEnd"
          :page-size="pageSize"
        />
      </template>
    </div>

    <AppDialog
      v-model:open="deleteOpen"
      :title="t('leads.deleteTitle')"
      size="sm"
    >
      <p class="text-sm text-gray-600 dark:text-gray-300">
        {{ t('leads.deleteConfirm', { name: deleteTarget ? leadDisplayName(deleteTarget) : '' }) }}
      </p>
      <template #footer>
        <AppDialogFooter @cancel="deleteOpen = false">
          <UButton
            color="error"
            @click="confirmDelete"
          >
            {{ t('common.delete') }}
          </UButton>
        </AppDialogFooter>
      </template>
    </AppDialog>
  </div>
</template>
