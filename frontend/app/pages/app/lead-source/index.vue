<script setup lang="ts">
import type { LeadSource } from '~/types/crm'
import { appFormFieldClass, appSelectMenuUi, appTableTextClass } from '~/config/appFormUi'
import { LEAD_SOURCE_STATUSES } from '~/config/masterLeadSource'
import { leadSourceDisplayLabel } from '~/utils/masterLeadSource'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { formatDateTime } = useFormat()
const { ensureProfile } = useProfile()
const { list, listDeleted } = useLeadSources()
const { archiveTab, canViewDeletedRecords, isActiveArchive, ensureArchiveAccess } = useArchiveTabs()

await ensureProfile()
await ensureArchiveAccess()

const leadSources = ref<LeadSource[]>([])
const loading = ref(true)
const search = ref('')
const statusFilter = ref<string | null>(null)
const deleteOpen = ref(false)
const deleteTarget = ref<LeadSource | null>(null)
const restoreOpen = ref(false)
const restoreTarget = ref<LeadSource | null>(null)

async function refresh() {
  loading.value = true
  try {
    leadSources.value = isActiveArchive.value
      ? await list()
      : await listDeleted()
  } catch (e) {
    console.error(e)
    leadSources.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

const statusFilterOptions = computed(() => [
  { value: null, label: t('masterData.leadSource.filters.allStatuses') },
  ...LEAD_SOURCE_STATUSES.map(value => ({
    value,
    label: t(`masterData.leadSource.options.status.${value}`)
  }))
])

const filteredLeadSources = computed(() => {
  let rows = leadSources.value
  if (isActiveArchive.value && statusFilter.value) {
    rows = rows.filter(u => u.status === statusFilter.value)
  }

  const q = search.value.trim().toLowerCase()
  if (!q) return rows
  return rows.filter((u) => {
    const code = u.source_code.toLowerCase()
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
} = usePagination(filteredLeadSources)

function openDelete(leadSource: LeadSource) {
  deleteTarget.value = leadSource
  deleteOpen.value = true
}

function openRestore(leadSource: LeadSource) {
  restoreTarget.value = leadSource
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
          {{ t('masterData.leadSource.listTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.leadSource.listSubtitle') }}
        </p>
      </div>
      <UButton
        v-if="isActiveArchive"
        icon="i-lucide-plus"
        to="/app/lead-source/new"
      >
        {{ t('masterData.leadSource.create') }}
      </UButton>
    </div>

    <AppArchiveTabs
      v-model:archive-tab="archiveTab"
      :can-view-deleted="canViewDeletedRecords"
      :active-label="t('masterData.leadSource.filters.activeRecords')"
      :deleted-label="t('masterData.leadSource.filters.deletedRecords')"
      :aria-label="t('masterData.leadSource.filters.archiveTabs')"
    />

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!leadSources.length">
      <p class="text-gray-500">
        {{ isActiveArchive ? t('masterData.leadSource.empty') : t('masterData.leadSource.filters.emptyDeleted') }}
      </p>
      <UButton
        v-if="isActiveArchive"
        class="mt-4"
        size="sm"
        icon="i-lucide-plus"
        to="/app/lead-source/new"
      >
        {{ t('masterData.leadSource.createFirst') }}
      </UButton>
    </UCard>

    <div v-else>
      <UCard class="mb-4">
        <div class="flex flex-wrap items-end gap-3">
          <UFormField
            v-if="isActiveArchive"
            :label="t('masterData.leadSource.filters.byStatus')"
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
            :placeholder="t('masterData.leadSource.filters.search')"
          />

          <UButton
            v-if="hasActiveFilters"
            variant="soft"
            color="neutral"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.leadSource.filters.viewAll') }}
          </UButton>
        </div>
      </UCard>

      <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800">
        <p
          class="border-b border-gray-200 px-3 py-2 text-gray-600 dark:border-gray-800 dark:text-gray-400"
          :class="appTableTextClass"
        >
          {{ t('masterData.leadSource.filters.displayCount', { count: paginationTotal }) }}
        </p>

        <div
          v-if="!filteredLeadSources.length"
          class="px-4 py-8 text-center"
        >
          <p class="text-gray-500">
            {{ t('masterData.leadSource.filters.noResults') }}
          </p>
          <UButton
            class="mt-4"
            size="sm"
            variant="soft"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.leadSource.filters.viewAll') }}
          </UButton>
        </div>

        <AppDataTable
          v-else
          embedded
        >
          <template #head>
            <tr>
              <AppDataTableTh>{{ t('masterData.leadSource.fields.name') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.leadSource.fields.sortOrder') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.leadSource.fields.status') }}</AppDataTableTh>
              <AppDataTableTh v-if="canViewDeletedRecords && !isActiveArchive">
                {{ t('masterData.leadSource.filters.deletedAt') }}
              </AppDataTableTh>
              <AppDataTableTh />
            </tr>
          </template>

          <AppDataTableRow
            v-for="leadSource in pagedItems"
            :key="leadSource.id"
          >
            <AppDataTableTd>
              <NuxtLink
                v-if="isActiveArchive"
                :to="`/app/lead-source/${leadSource.id}`"
                class="font-medium text-primary hover:underline"
              >
                {{ leadSource.name }}
              </NuxtLink>
              <span
                v-else
                class="font-medium"
              >
                {{ leadSource.name }}
              </span>
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ leadSource.sort_order }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              <UBadge
                :color="leadSource.status === 'active' ? 'success' : 'neutral'"
                variant="subtle"
                size="xs"
              >
                {{ t(`masterData.leadSource.options.status.${leadSource.status}`) }}
              </UBadge>
            </AppDataTableTd>
            <AppDataTableTd
              v-if="canViewDeletedRecords && !isActiveArchive"
              muted
            >
              {{ formatDateTime(leadSource.deleted_at) }}
            </AppDataTableTd>
            <AppDataTableTd align="right">
              <div class="flex items-center justify-end gap-1">
                <template v-if="isActiveArchive">
                  <AppIconButton
                    icon="i-lucide-eye"
                    :aria-label="t('masterData.leadSource.view')"
                    :to="`/app/lead-source/${leadSource.id}`"
                  />
                  <AppIconButton
                    icon="i-lucide-pencil"
                    :aria-label="t('common.edit')"
                    :to="`/app/lead-source/${leadSource.id}/edit`"
                  />
                  <AppIconButton
                    icon="i-lucide-trash-2"
                    color="error"
                    :aria-label="t('common.delete')"
                    @click="openDelete(leadSource)"
                  />
                </template>
                <AppIconButton
                  v-else-if="canViewDeletedRecords"
                  icon="i-lucide-rotate-ccw"
                  color="primary"
                  :aria-label="t('common.restore')"
                  @click="openRestore(leadSource)"
                />
              </div>
            </AppDataTableTd>
          </AppDataTableRow>
        </AppDataTable>

        <AppPagination
          v-if="filteredLeadSources.length"
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

    <MasterDataLeadSourceDeleteModal
      v-if="deleteTarget"
      v-model:open="deleteOpen"
      :leadSource-id="deleteTarget.id"
      :leadSource-name="leadSourceDisplayLabel(deleteTarget)"
      @deleted="onDeleted"
    />

    <MasterDataLeadSourceRestoreModal
      v-if="restoreTarget"
      v-model:open="restoreOpen"
      :leadSource-id="restoreTarget.id"
      :leadSource-name="leadSourceDisplayLabel(restoreTarget)"
      @restored="onRestored"
    />
  </div>
</template>
