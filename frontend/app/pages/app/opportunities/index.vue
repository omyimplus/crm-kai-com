<script setup lang="ts">
import type { Opportunity, PipelineStage } from '~/types/crm'
import { appTableGridViewOptions, type AppTableGridViewMode } from '~/config/appViewMode'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTableTextClass
} from '~/config/appFormUi'
import {
  filterOpportunityRows,
  sortOpportunityRows,
  type OpportunityDateField
} from '~/utils/masterOpportunities'
import { currentMonthDateRange } from '~/utils/masterTasks'
import { stageOptionLabel } from '~/utils/masterOpportunities'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { pipelineStageLabel } = usePipelineStageLabel()
const { ensureProfile } = useProfile()
const { ensurePermissions, canWriteModule } = usePermissions()
const { list, remove, ensureDefaults } = useOpportunities()
const { getDefaultPipeline } = useDeals()

await ensureProfile()
await ensurePermissions()

const listLayoutOptions = computed(() => appTableGridViewOptions(t))
const listLayout = ref<AppTableGridViewMode>('table')

const opportunities = ref<Opportunity[]>([])
const stages = ref<PipelineStage[]>([])
const loading = ref(true)
const search = ref('')
const stageFilter = ref<string | null>(null)
const defaultDateRange = currentMonthDateRange()
const scheduleFrom = ref(defaultDateRange.from)
const scheduleTo = ref(defaultDateRange.to)
const dateField = ref<OpportunityDateField>('created')
const deleteOpen = ref(false)
const deleteTarget = ref<Opportunity | null>(null)

const canWrite = computed(() => canWriteModule('app.opportunity'))

const stageOptions = computed(() => [
  { label: t('opportunities.filters.allStages'), value: null as string | null },
  ...stages.value.map(stage => ({
    label: stageOptionLabel(stage, name => pipelineStageLabel(name)),
    value: stage.id
  }))
])

const dateFieldOptions = computed(() => [
  { label: t('opportunities.filters.dateField.created'), value: 'created' as const },
  { label: t('opportunities.filters.dateField.close'), value: 'close' as const }
])

function isDefaultDateRange(): boolean {
  const range = currentMonthDateRange()
  return scheduleFrom.value === range.from && scheduleTo.value === range.to
}

const listFilterOptions = computed(() => ({
  stageFilter: stageFilter.value,
  dateRange: {
    from: scheduleFrom.value,
    to: scheduleTo.value
  },
  dateField: dateField.value,
  search: search.value,
  stageLabel: (name: string | null | undefined) => pipelineStageLabel(name)
}))

const summaryOpportunities = computed(() =>
  filterOpportunityRows(opportunities.value, listFilterOptions.value)
)

const filteredOpportunities = computed(() =>
  sortOpportunityRows(filterOpportunityRows(opportunities.value, listFilterOptions.value))
)

const hasActiveFilters = computed(() =>
  search.value.trim().length > 0
  || stageFilter.value !== null
  || !isDefaultDateRange()
  || dateField.value !== 'created'
)

const wonDateRange = computed(() => ({
  from: scheduleFrom.value,
  to: scheduleTo.value
}))

async function refresh() {
  loading.value = true
  try {
    await ensureDefaults()
    const pipelineData = await getDefaultPipeline()
    stages.value = pipelineData.stages
    opportunities.value = await list()
  } catch (error) {
    console.error(error)
    opportunities.value = []
    stages.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

const {
  page,
  pagedItems,
  totalItems: paginationTotal,
  totalPages,
  rangeStart,
  rangeEnd,
  pageSize,
  resetPage: resetPagination
} = usePagination(filteredOpportunities)

watch([search, stageFilter, scheduleFrom, scheduleTo, dateField], () => resetPagination())

function clearFilters() {
  search.value = ''
  stageFilter.value = null
  dateField.value = 'created'
  const range = currentMonthDateRange()
  scheduleFrom.value = range.from
  scheduleTo.value = range.to
}

function openView(row: Opportunity) {
  navigateTo(`/app/opportunities/${row.id}`)
}

function openEdit(row: Opportunity) {
  navigateTo(`/app/opportunities/${row.id}/edit`)
}

function openDelete(row: Opportunity) {
  deleteTarget.value = row
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
    <div>
      <h1 class="text-2xl font-bold font-heading text-gray-900 dark:text-gray-100">
        {{ t('opportunities.pageTitle') }}
      </h1>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        {{ t('opportunities.pageSubtitle') }}
      </p>
    </div>

    <OpportunitiesSummaryCards
      :opportunities="summaryOpportunities"
      :won-date-range="wonDateRange"
      :filtered="hasActiveFilters"
    />

    <UCard>
      <div class="space-y-4">
        <div class="flex flex-col gap-3 lg:flex-row lg:items-center">
          <UInput
            v-model="search"
            icon="i-lucide-search"
            :placeholder="t('opportunities.filters.searchPlaceholder')"
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
            :group-aria-label="t('opportunities.filters.dateRange')"
            :from-aria-label="t('opportunities.filters.dateFrom')"
            :to-aria-label="t('opportunities.filters.dateTo')"
          />

          <USelectMenu
            v-model="stageFilter"
            :items="stageOptions"
            value-key="value"
            :class="[appFormFieldClass, 'w-full sm:w-[12rem]']"
            :ui="appSelectMenuUi"
            :placeholder="t('opportunities.filters.allStages')"
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
              {{ t('opportunities.filters.clear') }}
            </UButton>
          </div>
        </div>

        <p
          v-if="!loading"
          class="text-sm text-gray-500 dark:text-gray-400"
          :class="appTableTextClass"
        >
          {{
            filteredOpportunities.length
              ? t('opportunities.filters.displayCount', { count: filteredOpportunities.length })
              : t('opportunities.filters.noResults')
          }}
        </p>

        <div v-if="loading">
          <p class="text-gray-500 dark:text-gray-400">
            {{ t('common.loading') }}
          </p>
        </div>

        <template v-else-if="filteredOpportunities.length">
          <OpportunitiesTable
            v-if="listLayout === 'table'"
            :opportunities="pagedItems"
            :can-write="canWrite"
            @view="openView"
            @edit="openEdit"
            @delete="openDelete"
          />
          <OpportunitiesCard
            v-else
            :opportunities="pagedItems"
            :can-write="canWrite"
            @view="openView"
            @edit="openEdit"
            @delete="openDelete"
          />

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

        <div
          v-else
          class="rounded-2xl border border-dashed border-gray-200 px-6 py-12 text-center dark:border-gray-800"
        >
          <p class="text-gray-600 dark:text-gray-300">
            {{ t('opportunities.emptyAll') }}
          </p>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            {{ t('opportunities.emptyHint') }}
          </p>
          <UButton
            class="mt-4"
            to="/app/leads"
            variant="soft"
            icon="i-lucide-user-plus"
          >
            {{ t('opportunities.goToLeads') }}
          </UButton>
        </div>
      </div>
    </UCard>

    <AppDialog
      v-model:open="deleteOpen"
      :title="t('opportunities.deleteTitle')"
      size="sm"
    >
      <p class="text-sm text-gray-600 dark:text-gray-300">
        {{ t('opportunities.deleteConfirm', { name: deleteTarget?.title ?? '' }) }}
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
