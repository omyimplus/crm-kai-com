<script setup lang="ts">
import type { ModuleStatus } from '~/types/crm'
import type { ModuleStatusModuleKey } from '~/config/masterModuleStatus'
import { appFormFieldClass, appSelectMenuUi, appTableTextClass } from '~/config/appFormUi'
import { MODULE_STATUS_RECORD_STATUSES } from '~/config/masterModuleStatus'
import {
  moduleStatusDisplayLabel,
  moduleStatusModuleLabel,
  moduleStatusNewPath
} from '~/utils/masterModuleStatus'

const props = withDefaults(defineProps<{
  moduleKey: ModuleStatusModuleKey
  embedded?: boolean
}>(), {
  embedded: false
})

const emit = defineEmits<{
  changed: []
}>()

const { t } = useI18n()
const { formatDateTime } = useFormat()
const { listByModule, listDeleted } = useModuleStatuses()
const { archiveTab, canViewDeletedRecords, isActiveArchive, ensureArchiveAccess } = useArchiveTabs()

await ensureArchiveAccess()

const rows = ref<ModuleStatus[]>([])
const loading = ref(true)
const search = ref('')
const recordStatusFilter = ref<string | null>(null)
const deleteOpen = ref(false)
const deleteTarget = ref<ModuleStatus | null>(null)
const restoreOpen = ref(false)
const restoreTarget = ref<ModuleStatus | null>(null)

async function refresh() {
  loading.value = true
  try {
    if (isActiveArchive.value) {
      rows.value = await listByModule(props.moduleKey)
    } else {
      const deleted = await listDeleted()
      rows.value = deleted.filter(row => row.module_key === props.moduleKey)
    }
  } catch (e) {
    console.error(e)
    rows.value = []
  } finally {
    loading.value = false
  }
}

const recordStatusFilterOptions = computed(() => [
  { value: null, label: t('masterData.moduleStatuses.filters.allRecordStatuses') },
  ...MODULE_STATUS_RECORD_STATUSES.map(value => ({
    value,
    label: t(`masterData.moduleStatuses.options.recordStatus.${value}`)
  }))
])

const filteredRows = computed(() => {
  let items = rows.value

  if (isActiveArchive.value && recordStatusFilter.value) {
    items = items.filter(row => row.status === recordStatusFilter.value)
  }

  const q = search.value.trim().toLowerCase()
  if (!q) return items

  return items.filter((row) => {
    const code = row.status_code.toLowerCase()
    const name = row.name.toLowerCase()
    return code.includes(q) || name.includes(q)
  })
})

const hasActiveFilters = computed(() =>
  search.value.trim().length > 0
  || (isActiveArchive.value && recordStatusFilter.value !== null)
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
} = usePagination(filteredRows)

const moduleTitle = computed(() => moduleStatusModuleLabel(props.moduleKey, t))
const addPath = computed(() => moduleStatusNewPath(props.moduleKey))

function openDelete(row: ModuleStatus) {
  deleteTarget.value = row
  deleteOpen.value = true
}

function openRestore(row: ModuleStatus) {
  restoreTarget.value = row
  restoreOpen.value = true
}

async function onDeleted() {
  deleteTarget.value = null
  await refresh()
  resetPagination()
  emit('changed')
}

async function onRestored() {
  restoreTarget.value = null
  await refresh()
  resetPagination()
  emit('changed')
}

function resetFilters() {
  search.value = ''
  recordStatusFilter.value = null
  resetPagination()
}

watch([search, recordStatusFilter], () => {
  resetPagination()
})

watch(archiveTab, async () => {
  resetFilters()
  await refresh()
})

watch(() => props.moduleKey, async () => {
  resetFilters()
  await refresh()
}, { immediate: true })

function clearFilters() {
  resetFilters()
}
</script>

<template>
  <div>
    <UButton
      v-if="!embedded"
      to="/app/module-status"
      variant="ghost"
      color="neutral"
      icon="i-lucide-arrow-left"
      size="sm"
      class="mb-4"
    >
      {{ t('masterData.moduleStatuses.backToModules') }}
    </UButton>

    <div class="mb-6 flex flex-wrap items-center justify-between gap-4">
      <div>
        <component
          :is="embedded ? 'h2' : 'h1'"
          class="font-bold font-heading"
          :class="embedded ? 'text-lg font-semibold' : 'text-2xl'"
        >
          {{ moduleTitle }}
        </component>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.moduleStatuses.moduleListSubtitle') }}
        </p>
      </div>
      <UButton
        v-if="isActiveArchive"
        icon="i-lucide-plus"
        :to="addPath"
      >
        {{ t('masterData.moduleStatuses.createForModule') }}
      </UButton>
    </div>

    <AppArchiveTabs
      v-model:archive-tab="archiveTab"
      :can-view-deleted="canViewDeletedRecords"
      :active-label="t('masterData.moduleStatuses.filters.activeRecords')"
      :deleted-label="t('masterData.moduleStatuses.filters.deletedRecords')"
      :aria-label="t('masterData.moduleStatuses.filters.archiveTabs')"
    />

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!rows.length">
      <p class="text-gray-500">
        {{ isActiveArchive ? t('masterData.moduleStatuses.moduleEmpty') : t('masterData.moduleStatuses.filters.emptyDeleted') }}
      </p>
      <UButton
        v-if="isActiveArchive"
        class="mt-4"
        size="sm"
        icon="i-lucide-plus"
        :to="addPath"
      >
        {{ t('masterData.moduleStatuses.createFirstForModule') }}
      </UButton>
    </UCard>

    <div v-else>
      <UCard class="mb-4">
        <div class="flex flex-wrap items-end gap-3">
          <UFormField
            v-if="isActiveArchive"
            :label="t('masterData.moduleStatuses.filters.byRecordStatus')"
            class="min-w-44"
          >
            <USelectMenu
              v-model="recordStatusFilter"
              :items="recordStatusFilterOptions"
              value-key="value"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
          </UFormField>

          <UInput
            v-model="search"
            class="min-w-0 flex-1"
            icon="i-lucide-search"
            :placeholder="t('masterData.moduleStatuses.filters.searchInModule')"
          />

          <UButton
            v-if="hasActiveFilters"
            variant="soft"
            color="neutral"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.moduleStatuses.filters.viewAll') }}
          </UButton>
        </div>
      </UCard>

      <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800">
        <p
          class="border-b border-gray-200 px-3 py-2 text-gray-600 dark:border-gray-800 dark:text-gray-400"
          :class="appTableTextClass"
        >
          {{ t('masterData.moduleStatuses.filters.displayCount', { count: paginationTotal }) }}
        </p>

        <div
          v-if="!filteredRows.length"
          class="px-4 py-8 text-center"
        >
          <p class="text-gray-500">
            {{ t('masterData.moduleStatuses.filters.noResults') }}
          </p>
          <UButton
            class="mt-4"
            size="sm"
            variant="soft"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.moduleStatuses.filters.viewAll') }}
          </UButton>
        </div>

        <AppDataTable
          v-else
          embedded
        >
          <template #head>
            <tr>
              <AppDataTableTh>{{ t('masterData.moduleStatuses.fields.name') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.moduleStatuses.fields.code') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.moduleStatuses.fields.color') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.moduleStatuses.fields.sortOrder') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.moduleStatuses.fields.recordStatus') }}</AppDataTableTh>
              <AppDataTableTh v-if="canViewDeletedRecords && !isActiveArchive">
                {{ t('masterData.moduleStatuses.filters.deletedAt') }}
              </AppDataTableTh>
              <AppDataTableTh />
            </tr>
          </template>

          <AppDataTableRow
            v-for="row in pagedItems"
            :key="row.id"
          >
            <AppDataTableTd>
              <div class="flex items-center gap-2">
                <NuxtLink
                  v-if="isActiveArchive"
                  :to="`/app/module-status/${row.id}`"
                  class="font-medium text-primary hover:underline"
                >
                  {{ row.name }}
                </NuxtLink>
                <span
                  v-else
                  class="font-medium"
                >
                  {{ row.name }}
                </span>
                <UBadge
                  v-if="row.is_default && isActiveArchive"
                  color="primary"
                  variant="subtle"
                  size="xs"
                >
                  {{ t('masterData.moduleStatuses.fields.defaultBadge') }}
                </UBadge>
              </div>
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ row.status_code }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              <span
                v-if="row.color"
                class="inline-block size-6 rounded-md border border-gray-200 dark:border-gray-700"
                :style="{ backgroundColor: row.color }"
                :title="row.color"
              />
              <span v-else>—</span>
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ row.sort_order }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              <UBadge
                :color="row.status === 'active' ? 'success' : 'neutral'"
                variant="subtle"
                size="xs"
              >
                {{ t(`masterData.moduleStatuses.options.recordStatus.${row.status}`) }}
              </UBadge>
            </AppDataTableTd>
            <AppDataTableTd
              v-if="canViewDeletedRecords && !isActiveArchive"
              muted
            >
              {{ formatDateTime(row.deleted_at) }}
            </AppDataTableTd>
            <AppDataTableTd align="right">
              <div class="flex items-center justify-end gap-1">
                <template v-if="isActiveArchive">
                  <AppIconButton
                    icon="i-lucide-eye"
                    :aria-label="t('masterData.moduleStatuses.view')"
                    :to="`/app/module-status/${row.id}`"
                  />
                  <AppIconButton
                    icon="i-lucide-pencil"
                    :aria-label="t('common.edit')"
                    :to="`/app/module-status/${row.id}/edit`"
                  />
                  <AppIconButton
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
          v-if="filteredRows.length"
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

    <MasterDataModuleStatusDeleteModal
      v-if="deleteTarget"
      v-model:open="deleteOpen"
      :module-status-id="deleteTarget.id"
      :module-status-name="moduleStatusDisplayLabel(deleteTarget)"
      @deleted="onDeleted"
    />

    <MasterDataModuleStatusRestoreModal
      v-if="restoreTarget"
      v-model:open="restoreOpen"
      :module-status-id="restoreTarget.id"
      :module-status-name="moduleStatusDisplayLabel(restoreTarget)"
      @restored="onRestored"
    />
  </div>
</template>
