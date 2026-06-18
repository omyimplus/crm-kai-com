<script setup lang="ts">
import type { SalesTarget } from '~/types/crm'
import { achievementColor, SALES_TARGET_PERIOD_TYPES, salesTargetYearOptions } from '~/config/masterSalesTarget'
import { appFormFieldClass, appSelectMenuUi, appTableTextClass } from '~/config/appFormUi'
import {
  formatSalesAmount,
  formatSalesTargetPeriod,
  profileDisplayName
} from '~/utils/masterSalesTarget'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t, locale } = useI18n()
const { profile, ensureProfile } = useProfile()
const { list, listDeleted } = useSalesTargets()
const { archiveTab, canViewDeletedRecords, isActiveArchive, ensureArchiveAccess } = useArchiveTabs()

await ensureProfile()
await ensureArchiveAccess()

const canManage = computed(() =>
  profile.value?.role === 'owner' || profile.value?.role === 'admin'
)

const rows = ref<SalesTarget[]>([])
const loading = ref(true)
const search = ref('')
const yearFilter = ref<number | null>(new Date().getFullYear())
const periodTypeFilter = ref<string | null>(null)
const deleteOpen = ref(false)
const deleteTarget = ref<SalesTarget | null>(null)
const restoreOpen = ref(false)
const restoreTarget = ref<SalesTarget | null>(null)

async function refresh() {
  loading.value = true
  try {
    rows.value = isActiveArchive.value ? await list() : await listDeleted()
  } catch (e) {
    console.error(e)
    rows.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

const yearOptions = computed(() => [
  { value: null, label: t('masterData.salesTarget.filters.allYears') },
  ...salesTargetYearOptions().map(year => ({ value: year, label: String(year) }))
])

const periodTypeOptions = computed(() => [
  { value: null, label: t('masterData.salesTarget.filters.allPeriodTypes') },
  ...SALES_TARGET_PERIOD_TYPES.map(value => ({
    value,
    label: t(`masterData.salesTarget.options.periodType.${value}`)
  }))
])

const filteredRows = computed(() => {
  let listRows = rows.value
  if (yearFilter.value != null) {
    listRows = listRows.filter(r => r.period_year === yearFilter.value)
  }
  if (periodTypeFilter.value) {
    listRows = listRows.filter(r => r.period_type === periodTypeFilter.value)
  }
  const q = search.value.trim().toLowerCase()
  if (!q) return listRows
  return listRows.filter((r) => {
    const name = profileDisplayName(r.profiles ?? {}).toLowerCase()
    const period = formatSalesTargetPeriod(r, t).toLowerCase()
    return name.includes(q) || period.includes(q)
  })
})

const {
  page,
  pagedItems,
  totalItems: paginationTotal,
  totalPages,
  rangeStart,
  rangeEnd,
  pageSize,
  resetPage: resetPagination
} = usePagination(filteredRows)

watch([search, yearFilter, periodTypeFilter], () => resetPagination())

watch(archiveTab, async () => {
  search.value = ''
  yearFilter.value = new Date().getFullYear()
  periodTypeFilter.value = null
  resetPagination()
  await refresh()
})

function rowLabel(row: SalesTarget) {
  return `${profileDisplayName(row.profiles ?? {})} · ${formatSalesTargetPeriod(row, t)}`
}

function openDelete(row: SalesTarget) {
  deleteTarget.value = row
  deleteOpen.value = true
}

function openRestore(row: SalesTarget) {
  restoreTarget.value = row
  restoreOpen.value = true
}

async function onDeleted() {
  deleteTarget.value = null
  await refresh()
  resetPagination()
}

async function onRestored() {
  restoreTarget.value = null
  await refresh()
  resetPagination()
}
</script>

<template>
  <div>
    <div class="mb-6 flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold font-heading">
          {{ t('masterData.salesTarget.listTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.salesTarget.listSubtitle') }}
        </p>
      </div>
      <UButton
        v-if="canManage && isActiveArchive"
        icon="i-lucide-plus"
        to="/app/sales-target/new"
      >
        {{ t('masterData.salesTarget.create') }}
      </UButton>
    </div>

    <AppArchiveTabs
      v-model:archive-tab="archiveTab"
      :can-view-deleted="canViewDeletedRecords"
      :active-label="t('masterData.salesTarget.filters.activeRecords')"
      :deleted-label="t('masterData.salesTarget.filters.deletedRecords')"
      :aria-label="t('masterData.salesTarget.filters.archiveTabs')"
    />

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!rows.length">
      <p class="text-gray-500">
        {{ isActiveArchive ? t('masterData.salesTarget.empty') : t('masterData.salesTarget.filters.emptyDeleted') }}
      </p>
      <UButton
        v-if="canManage && isActiveArchive"
        class="mt-4"
        size="sm"
        icon="i-lucide-plus"
        to="/app/sales-target/new"
      >
        {{ t('masterData.salesTarget.createFirst') }}
      </UButton>
    </UCard>

    <div v-else>
      <UCard class="mb-4">
        <div class="flex flex-wrap items-end gap-3">
          <UFormField
            :label="t('masterData.salesTarget.filters.year')"
            class="min-w-36"
          >
            <USelectMenu
              v-model="yearFilter"
              :items="yearOptions"
              value-key="value"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
          </UFormField>

          <UFormField
            :label="t('masterData.salesTarget.filters.periodType')"
            class="min-w-40"
          >
            <USelectMenu
              v-model="periodTypeFilter"
              :items="periodTypeOptions"
              value-key="value"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
          </UFormField>

          <UInput
            v-model="search"
            class="min-w-0 flex-1"
            icon="i-lucide-search"
            :placeholder="t('masterData.salesTarget.filters.search')"
          />
        </div>
      </UCard>

      <AppDataTable>
        <template #head>
          <AppDataTableRow>
            <AppDataTableTh>{{ t('masterData.salesTarget.fields.assignee') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('masterData.salesTarget.fields.period') }}</AppDataTableTh>
            <AppDataTableTh class="text-right">
              {{ t('masterData.salesTarget.fields.targetAmount') }}
            </AppDataTableTh>
            <AppDataTableTh
              v-if="isActiveArchive"
              class="text-right"
            >
              {{ t('masterData.salesTarget.fields.currentAmount') }}
            </AppDataTableTh>
            <AppDataTableTh
              v-if="isActiveArchive"
              class="min-w-[10rem]"
            >
              {{ t('masterData.salesTarget.fields.progress') }}
            </AppDataTableTh>
            <AppDataTableTh class="w-28" />
          </AppDataTableRow>
        </template>

        <AppDataTableRow
          v-for="row in pagedItems"
          :key="row.id"
        >
          <AppDataTableTd :class="appTableTextClass">
            <NuxtLink
              :to="`/app/sales-target/${row.id}`"
              class="font-medium text-primary hover:underline"
            >
              {{ profileDisplayName(row.profiles ?? {}) }}
            </NuxtLink>
          </AppDataTableTd>
          <AppDataTableTd :class="appTableTextClass">
            {{ formatSalesTargetPeriod(row, t) }}
          </AppDataTableTd>
          <AppDataTableTd class="text-right tabular-nums">
            {{ formatSalesAmount(row.target_amount, row.currency, locale) }}
          </AppDataTableTd>
          <AppDataTableTd
            v-if="isActiveArchive"
            class="text-right tabular-nums"
          >
            {{ formatSalesAmount(row.current_amount ?? 0, row.currency, locale) }}
          </AppDataTableTd>
          <AppDataTableTd
            v-if="isActiveArchive"
          >
            <div class="flex min-w-[9rem] items-center gap-2">
              <UProgress
                class="min-w-0 flex-1"
                :model-value="Math.min(row.achievement_pct ?? 0, 100)"
                :color="achievementColor(row.achievement_pct ?? 0)"
                size="sm"
              />
              <span class="w-10 shrink-0 text-right text-xs tabular-nums text-gray-500 dark:text-gray-400">
                {{ row.achievement_pct ?? 0 }}%
              </span>
            </div>
          </AppDataTableTd>
          <AppDataTableTd align="right">
            <div class="flex items-center justify-end gap-1">
              <template v-if="isActiveArchive">
                <AppIconButton
                  icon="i-lucide-eye"
                  :aria-label="t('masterData.salesTarget.view')"
                  :to="`/app/sales-target/${row.id}`"
                />
                <AppIconButton
                  v-if="canManage"
                  icon="i-lucide-pencil"
                  :aria-label="t('common.edit')"
                  :to="`/app/sales-target/${row.id}/edit`"
                />
                <AppIconButton
                  v-if="canManage"
                  icon="i-lucide-trash-2"
                  color="error"
                  :aria-label="t('common.delete')"
                  @click="openDelete(row)"
                />
              </template>
              <AppIconButton
                v-else-if="canViewDeletedRecords"
                icon="i-lucide-rotate-ccw"
                color="primary"
                :aria-label="t('common.restore')"
                @click="openRestore(row)"
              />
            </div>
          </AppDataTableTd>
        </AppDataTableRow>
      </AppDataTable>

      <AppPagination
        v-model:page="page"
        embedded
        :total-items="paginationTotal"
        :total-pages="totalPages"
        :range-start="rangeStart"
        :range-end="rangeEnd"
        :page-size="pageSize"
      />
    </div>

    <MasterDataSalesTargetDeleteModal
      v-if="deleteTarget"
      v-model:open="deleteOpen"
      :target-id="deleteTarget.id"
      :label="rowLabel(deleteTarget)"
      @deleted="onDeleted"
    />

    <MasterDataSalesTargetRestoreModal
      v-if="restoreTarget"
      v-model:open="restoreOpen"
      :target-id="restoreTarget.id"
      :label="rowLabel(restoreTarget)"
      @restored="onRestored"
    />
  </div>
</template>
