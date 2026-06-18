<script setup lang="ts">
import type { SalesTeam } from '~/types/crm'
import { appFormFieldClass, appSelectMenuUi, appTableTextClass } from '~/config/appFormUi'
import { SALES_TEAM_STATUSES } from '~/config/masterSalesTeam'
import {
  profileSummaryDisplayName,
  salesTeamDisplayLabel,
  salesTeamMemberCount
} from '~/utils/masterSalesTeam'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { formatDateTime } = useFormat()
const { ensureProfile } = useProfile()
const { list, listDeleted } = useSalesTeams()
const { archiveTab, canViewDeletedRecords, isActiveArchive, ensureArchiveAccess } = useArchiveTabs()

await ensureProfile()
await ensureArchiveAccess()

const teams = ref<SalesTeam[]>([])
const loading = ref(true)
const search = ref('')
const statusFilter = ref<string | null>(null)
const deleteOpen = ref(false)
const deleteTarget = ref<SalesTeam | null>(null)
const restoreOpen = ref(false)
const restoreTarget = ref<SalesTeam | null>(null)

async function refresh() {
  loading.value = true
  try {
    teams.value = isActiveArchive.value
      ? await list()
      : await listDeleted()
  } catch (e) {
    console.error(e)
    teams.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

const statusFilterOptions = computed(() => [
  { value: null, label: t('masterData.salesTeam.filters.allStatuses') },
  ...SALES_TEAM_STATUSES.map(value => ({
    value,
    label: t(`masterData.salesTeam.options.status.${value}`)
  }))
])

const filteredTeams = computed(() => {
  let rows = teams.value
  if (isActiveArchive.value && statusFilter.value) {
    rows = rows.filter(u => u.status === statusFilter.value)
  }

  const q = search.value.trim().toLowerCase()
  if (!q) return rows
  return rows.filter((u) => {
    const code = u.team_code.toLowerCase()
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
} = usePagination(filteredTeams)

function openDelete(team: SalesTeam) {
  deleteTarget.value = team
  deleteOpen.value = true
}

function openRestore(team: SalesTeam) {
  restoreTarget.value = team
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

function teamLeadLabel(team: SalesTeam) {
  if (!team.team_lead) return '—'
  return profileSummaryDisplayName(team.team_lead)
}
</script>

<template>
  <div>
    <div class="mb-6 flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold font-heading">
          {{ t('masterData.salesTeam.listTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.salesTeam.listSubtitle') }}
        </p>
      </div>
      <UButton
        v-if="isActiveArchive"
        icon="i-lucide-plus"
        to="/app/sales-team/new"
      >
        {{ t('masterData.salesTeam.create') }}
      </UButton>
    </div>

    <AppArchiveTabs
      v-model:archive-tab="archiveTab"
      :can-view-deleted="canViewDeletedRecords"
      :active-label="t('masterData.salesTeam.filters.activeRecords')"
      :deleted-label="t('masterData.salesTeam.filters.deletedRecords')"
      :aria-label="t('masterData.salesTeam.filters.archiveTabs')"
    />

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!teams.length">
      <p class="text-gray-500">
        {{ isActiveArchive ? t('masterData.salesTeam.empty') : t('masterData.salesTeam.filters.emptyDeleted') }}
      </p>
      <UButton
        v-if="isActiveArchive"
        class="mt-4"
        size="sm"
        icon="i-lucide-plus"
        to="/app/sales-team/new"
      >
        {{ t('masterData.salesTeam.createFirst') }}
      </UButton>
    </UCard>

    <div v-else>
      <UCard class="mb-4">
        <div class="flex flex-wrap items-end gap-3">
          <UFormField
            v-if="isActiveArchive"
            :label="t('masterData.salesTeam.filters.byStatus')"
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
            :placeholder="t('masterData.salesTeam.filters.search')"
          />

          <UButton
            v-if="hasActiveFilters"
            variant="soft"
            color="neutral"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.salesTeam.filters.viewAll') }}
          </UButton>
        </div>
      </UCard>

      <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800">
        <p
          class="border-b border-gray-200 px-3 py-2 text-gray-600 dark:border-gray-800 dark:text-gray-400"
          :class="appTableTextClass"
        >
          {{ t('masterData.salesTeam.filters.displayCount', { count: paginationTotal }) }}
        </p>

        <div
          v-if="!filteredTeams.length"
          class="px-4 py-8 text-center"
        >
          <p class="text-gray-500">
            {{ t('masterData.salesTeam.filters.noResults') }}
          </p>
          <UButton
            class="mt-4"
            size="sm"
            variant="soft"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.salesTeam.filters.viewAll') }}
          </UButton>
        </div>

        <AppDataTable
          v-else
          embedded
        >
          <template #head>
            <tr>
              <AppDataTableTh>{{ t('masterData.salesTeam.fields.name') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.salesTeam.fields.teamLead') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.salesTeam.fields.memberCount') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.salesTeam.fields.status') }}</AppDataTableTh>
              <AppDataTableTh v-if="canViewDeletedRecords && !isActiveArchive">
                {{ t('masterData.salesTeam.filters.deletedAt') }}
              </AppDataTableTh>
              <AppDataTableTh />
            </tr>
          </template>

          <AppDataTableRow
            v-for="team in pagedItems"
            :key="team.id"
          >
            <AppDataTableTd>
              <NuxtLink
                v-if="isActiveArchive"
                :to="`/app/sales-team/${team.id}`"
                class="font-medium text-primary hover:underline"
              >
                {{ team.name }}
              </NuxtLink>
              <span
                v-else
                class="font-medium"
              >
                {{ team.name }}
              </span>
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ teamLeadLabel(team) }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ salesTeamMemberCount(team) }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              <UBadge
                :color="team.status === 'active' ? 'success' : 'neutral'"
                variant="subtle"
                size="xs"
              >
                {{ t(`masterData.salesTeam.options.status.${team.status}`) }}
              </UBadge>
            </AppDataTableTd>
            <AppDataTableTd
              v-if="canViewDeletedRecords && !isActiveArchive"
              muted
            >
              {{ formatDateTime(team.deleted_at) }}
            </AppDataTableTd>
            <AppDataTableTd align="right">
              <div class="flex items-center justify-end gap-1">
                <template v-if="isActiveArchive">
                  <AppIconButton
                    icon="i-lucide-eye"
                    :aria-label="t('masterData.salesTeam.view')"
                    :to="`/app/sales-team/${team.id}`"
                  />
                  <AppIconButton
                    icon="i-lucide-pencil"
                    :aria-label="t('common.edit')"
                    :to="`/app/sales-team/${team.id}/edit`"
                  />
                  <AppIconButton
                    icon="i-lucide-trash-2"
                    color="error"
                    :aria-label="t('common.delete')"
                    @click="openDelete(team)"
                  />
                </template>
                <AppIconButton
                  v-else-if="canViewDeletedRecords"
                  icon="i-lucide-rotate-ccw"
                  color="primary"
                  :aria-label="t('common.restore')"
                  @click="openRestore(team)"
                />
              </div>
            </AppDataTableTd>
          </AppDataTableRow>
        </AppDataTable>

        <AppPagination
          v-if="filteredTeams.length"
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

    <MasterDataSalesTeamDeleteModal
      v-if="deleteTarget"
      v-model:open="deleteOpen"
      :team-id="deleteTarget.id"
      :team-name="salesTeamDisplayLabel(deleteTarget)"
      @deleted="onDeleted"
    />

    <MasterDataSalesTeamRestoreModal
      v-if="restoreTarget"
      v-model:open="restoreOpen"
      :team-id="restoreTarget.id"
      :team-name="salesTeamDisplayLabel(restoreTarget)"
      @restored="onRestored"
    />
  </div>
</template>
