<script setup lang="ts">
import type { Unit } from '~/types/crm'
import { appFormFieldClass, appSelectMenuUi, appTableTextClass } from '~/config/appFormUi'
import { UNIT_STATUSES } from '~/config/masterUnit'
import { unitDisplayLabel } from '~/utils/masterUnit'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { formatDateTime } = useFormat()
const { ensureProfile } = useProfile()
const { list, listDeleted } = useUnits()
const { archiveTab, canViewDeletedRecords, isActiveArchive, ensureArchiveAccess } = useArchiveTabs()

await ensureProfile()
await ensureArchiveAccess()

const units = ref<Unit[]>([])
const loading = ref(true)
const search = ref('')
const statusFilter = ref<string | null>(null)
const deleteOpen = ref(false)
const deleteTarget = ref<Unit | null>(null)
const restoreOpen = ref(false)
const restoreTarget = ref<Unit | null>(null)

async function refresh() {
  loading.value = true
  try {
    units.value = isActiveArchive.value
      ? await list()
      : await listDeleted()
  } catch (e) {
    console.error(e)
    units.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

const statusFilterOptions = computed(() => [
  { value: null, label: t('masterData.unit.filters.allStatuses') },
  ...UNIT_STATUSES.map(value => ({
    value,
    label: t(`masterData.unit.options.status.${value}`)
  }))
])

const filteredUnits = computed(() => {
  let rows = units.value
  if (isActiveArchive.value && statusFilter.value) {
    rows = rows.filter(u => u.status === statusFilter.value)
  }

  const q = search.value.trim().toLowerCase()
  if (!q) return rows
  return rows.filter((u) => {
    const code = u.unit_code.toLowerCase()
    const name = u.name.toLowerCase()
    return code.includes(q) || name.includes(q)
  })
})

const hasActiveFilters = computed(() =>
  search.value.trim().length > 0 || (isActiveArchive.value && statusFilter.value !== null)
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
} = usePagination(filteredUnits)

function openDelete(unit: Unit) {
  deleteTarget.value = unit
  deleteOpen.value = true
}

function openRestore(unit: Unit) {
  restoreTarget.value = unit
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

watch([search, statusFilter], () => {
  resetPagination()
})

watch(archiveTab, async () => {
  search.value = ''
  statusFilter.value = null
  resetPagination()
  await refresh()
})

function clearFilters() {
  search.value = ''
  statusFilter.value = null
  resetPagination()
}
</script>

<template>
  <div>
    <div class="mb-6 flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold font-heading">
          {{ t('masterData.unit.listTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.unit.listSubtitle') }}
        </p>
      </div>
      <UButton
        v-if="isActiveArchive"
        icon="i-lucide-plus"
        to="/app/unit/new"
      >
        {{ t('masterData.unit.create') }}
      </UButton>
    </div>

    <AppArchiveTabs
      v-model:archive-tab="archiveTab"
      :can-view-deleted="canViewDeletedRecords"
      :active-label="t('masterData.unit.filters.activeRecords')"
      :deleted-label="t('masterData.unit.filters.deletedRecords')"
      :aria-label="t('masterData.unit.filters.archiveTabs')"
    />

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!units.length">
      <p class="text-gray-500">
        {{ isActiveArchive ? t('masterData.unit.empty') : t('masterData.unit.filters.emptyDeleted') }}
      </p>
      <UButton
        v-if="isActiveArchive"
        class="mt-4"
        size="sm"
        icon="i-lucide-plus"
        to="/app/unit/new"
      >
        {{ t('masterData.unit.createFirst') }}
      </UButton>
    </UCard>

    <div v-else>
      <UCard class="mb-4">
        <div class="flex flex-wrap items-end gap-3">
          <UFormField
            v-if="isActiveArchive"
            :label="t('masterData.unit.filters.byStatus')"
            class="min-w-44"
          >
            <USelectMenu
              v-model="statusFilter"
              :items="statusFilterOptions"
              value-key="value"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
          </UFormField>

          <UInput
            v-model="search"
            class="min-w-0 flex-1"
            icon="i-lucide-search"
            :placeholder="t('masterData.unit.filters.search')"
          />

          <UButton
            v-if="hasActiveFilters"
            variant="soft"
            color="neutral"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.unit.filters.viewAll') }}
          </UButton>
        </div>
      </UCard>

      <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800">
        <p
          class="border-b border-gray-200 px-3 py-2 text-gray-600 dark:border-gray-800 dark:text-gray-400"
          :class="appTableTextClass"
        >
          {{ t('masterData.unit.filters.displayCount', { count: paginationTotal }) }}
        </p>

        <div
          v-if="!filteredUnits.length"
          class="px-4 py-8 text-center"
        >
          <p class="text-gray-500">
            {{ t('masterData.unit.filters.noResults') }}
          </p>
          <UButton
            class="mt-4"
            size="sm"
            variant="soft"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.unit.filters.viewAll') }}
          </UButton>
        </div>

        <AppDataTable
          v-else
          embedded
        >
          <template #head>
            <tr>
              <AppDataTableTh>{{ t('masterData.unit.fields.name') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.unit.fields.sortOrder') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.unit.fields.status') }}</AppDataTableTh>
              <AppDataTableTh v-if="canViewDeletedRecords && !isActiveArchive">
                {{ t('masterData.unit.filters.deletedAt') }}
              </AppDataTableTh>
              <AppDataTableTh />
            </tr>
          </template>

          <AppDataTableRow
            v-for="unit in pagedItems"
            :key="unit.id"
          >
            <AppDataTableTd>
              <NuxtLink
                v-if="isActiveArchive"
                :to="`/app/unit/${unit.id}`"
                class="font-medium text-primary hover:underline"
              >
                {{ unit.name }}
              </NuxtLink>
              <span
                v-else
                class="font-medium"
              >
                {{ unit.name }}
              </span>
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ unit.sort_order }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              <UBadge
                :color="unit.status === 'active' ? 'success' : 'neutral'"
                variant="subtle"
                size="xs"
              >
                {{ t(`masterData.unit.options.status.${unit.status}`) }}
              </UBadge>
            </AppDataTableTd>
            <AppDataTableTd
              v-if="canViewDeletedRecords && !isActiveArchive"
              muted
            >
              {{ formatDateTime(unit.deleted_at) }}
            </AppDataTableTd>
            <AppDataTableTd align="right">
              <div class="flex items-center justify-end gap-1">
                <template v-if="isActiveArchive">
                  <AppIconButton
                    icon="i-lucide-eye"
                    :aria-label="t('masterData.unit.view')"
                    :to="`/app/unit/${unit.id}`"
                  />
                  <AppIconButton
                    icon="i-lucide-pencil"
                    :aria-label="t('common.edit')"
                    :to="`/app/unit/${unit.id}/edit`"
                  />
                  <AppIconButton
                    icon="i-lucide-trash-2"
                    color="error"
                    :aria-label="t('common.delete')"
                    @click="openDelete(unit)"
                  />
                </template>
                <AppIconButton
                  v-else-if="canViewDeletedRecords"
                  icon="i-lucide-rotate-ccw"
                  color="primary"
                  :aria-label="t('common.restore')"
                  @click="openRestore(unit)"
                />
              </div>
            </AppDataTableTd>
          </AppDataTableRow>
        </AppDataTable>

        <AppPagination
          v-if="filteredUnits.length"
          v-model:page="page"
          embedded
          :total-items="paginationTotal"
          :total-pages="totalPages"
          :range-start="rangeStart"
          :range-end="rangeEnd"
          :page-size="pageSize"
        />
      </div>
    </div>

    <MasterDataUnitDeleteModal
      v-if="deleteTarget"
      v-model:open="deleteOpen"
      :unit-id="deleteTarget.id"
      :unit-name="unitDisplayLabel(deleteTarget)"
      @deleted="onDeleted"
    />

    <MasterDataUnitRestoreModal
      v-if="restoreTarget"
      v-model:open="restoreOpen"
      :unit-id="restoreTarget.id"
      :unit-name="unitDisplayLabel(restoreTarget)"
      @restored="onRestored"
    />
  </div>
</template>
