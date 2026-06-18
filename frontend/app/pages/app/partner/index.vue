<script setup lang="ts">
import type { Partner } from '~/types/crm'
import { appFormFieldClass, appSelectMenuUi, appTableTextClass } from '~/config/appFormUi'
import { PARTNER_STATUSES } from '~/config/masterPartner'
import { partnerDisplayLabel } from '~/utils/masterPartner'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { formatDateTime } = useFormat()
const { ensureProfile } = useProfile()
const { list, listDeleted } = usePartners()
const { archiveTab, canViewDeletedRecords, isActiveArchive, ensureArchiveAccess } = useArchiveTabs()

await ensureProfile()
await ensureArchiveAccess()

const partners = ref<Partner[]>([])
const loading = ref(true)
const search = ref('')
const statusFilter = ref<string | null>(null)
const deleteOpen = ref(false)
const deleteTarget = ref<Partner | null>(null)
const restoreOpen = ref(false)
const restoreTarget = ref<Partner | null>(null)

async function refresh() {
  loading.value = true
  try {
    partners.value = isActiveArchive.value
      ? await list()
      : await listDeleted()
  } catch (e) {
    console.error(e)
    partners.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

const statusFilterOptions = computed(() => [
  { value: null, label: t('masterData.partner.filters.allStatuses') },
  ...PARTNER_STATUSES.map(value => ({
    value,
    label: t(`masterData.partner.options.status.${value}`)
  }))
])

const filteredPartners = computed(() => {
  let rows = partners.value
  if (isActiveArchive.value && statusFilter.value) {
    rows = rows.filter(u => u.status === statusFilter.value)
  }

  const q = search.value.trim().toLowerCase()
  if (!q) return rows
  return rows.filter((u) => {
    const code = u.partner_code.toLowerCase()
    const name = u.name.toLowerCase()
    const contact = u.contact_person.toLowerCase()
    const email = u.email.toLowerCase()
    return code.includes(q) || name.includes(q) || contact.includes(q) || email.includes(q)
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
} = usePagination(filteredPartners)

function openDelete(partner: Partner) {
  deleteTarget.value = partner
  deleteOpen.value = true
}

function openRestore(partner: Partner) {
  restoreTarget.value = partner
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
          {{ t('masterData.partner.listTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.partner.listSubtitle') }}
        </p>
      </div>
      <UButton
        v-if="isActiveArchive"
        icon="i-lucide-plus"
        to="/app/partner/new"
      >
        {{ t('masterData.partner.create') }}
      </UButton>
    </div>

    <AppArchiveTabs
      v-model:archive-tab="archiveTab"
      :can-view-deleted="canViewDeletedRecords"
      :active-label="t('masterData.partner.filters.activeRecords')"
      :deleted-label="t('masterData.partner.filters.deletedRecords')"
      :aria-label="t('masterData.partner.filters.archiveTabs')"
    />

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!partners.length">
      <p class="text-gray-500">
        {{ isActiveArchive ? t('masterData.partner.empty') : t('masterData.partner.filters.emptyDeleted') }}
      </p>
      <UButton
        v-if="isActiveArchive"
        class="mt-4"
        size="sm"
        icon="i-lucide-plus"
        to="/app/partner/new"
      >
        {{ t('masterData.partner.createFirst') }}
      </UButton>
    </UCard>

    <div v-else>
      <UCard class="mb-4">
        <div class="flex flex-wrap items-end gap-3">
          <UFormField
            v-if="isActiveArchive"
            :label="t('masterData.partner.filters.byStatus')"
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
            :placeholder="t('masterData.partner.filters.search')"
          />

          <UButton
            v-if="hasActiveFilters"
            variant="soft"
            color="neutral"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.partner.filters.viewAll') }}
          </UButton>
        </div>
      </UCard>

      <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800">
        <p
          class="border-b border-gray-200 px-3 py-2 text-gray-600 dark:border-gray-800 dark:text-gray-400"
          :class="appTableTextClass"
        >
          {{ t('masterData.partner.filters.displayCount', { count: paginationTotal }) }}
        </p>

        <div
          v-if="!filteredPartners.length"
          class="px-4 py-8 text-center"
        >
          <p class="text-gray-500">
            {{ t('masterData.partner.filters.noResults') }}
          </p>
          <UButton
            class="mt-4"
            size="sm"
            variant="soft"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.partner.filters.viewAll') }}
          </UButton>
        </div>

        <AppDataTable
          v-else
          embedded
        >
          <template #head>
            <tr>
              <AppDataTableTh>{{ t('masterData.partner.fields.companyName') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.partner.fields.type') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.partner.fields.tier') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.partner.fields.status') }}</AppDataTableTh>
              <AppDataTableTh v-if="canViewDeletedRecords && !isActiveArchive">
                {{ t('masterData.partner.filters.deletedAt') }}
              </AppDataTableTh>
              <AppDataTableTh />
            </tr>
          </template>

          <AppDataTableRow
            v-for="partner in pagedItems"
            :key="partner.id"
          >
            <AppDataTableTd>
              <NuxtLink
                v-if="isActiveArchive"
                :to="`/app/partner/${partner.id}`"
                class="font-medium text-primary hover:underline"
              >
                {{ partner.name }}
              </NuxtLink>
              <span
                v-else
                class="font-medium"
              >
                {{ partner.name }}
              </span>
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ t(`masterData.partner.options.type.${partner.partner_type}`) }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ t(`masterData.partner.options.tier.${partner.tier}`) }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              <UBadge
                :color="partner.status === 'active' ? 'success' : 'neutral'"
                variant="subtle"
                size="xs"
              >
                {{ t(`masterData.partner.options.status.${partner.status}`) }}
              </UBadge>
            </AppDataTableTd>
            <AppDataTableTd
              v-if="canViewDeletedRecords && !isActiveArchive"
              muted
            >
              {{ formatDateTime(partner.deleted_at) }}
            </AppDataTableTd>
            <AppDataTableTd align="right">
              <div class="flex items-center justify-end gap-1">
                <template v-if="isActiveArchive">
                  <AppIconButton
                    icon="i-lucide-eye"
                    :aria-label="t('masterData.partner.view')"
                    :to="`/app/partner/${partner.id}`"
                  />
                  <AppIconButton
                    icon="i-lucide-pencil"
                    :aria-label="t('common.edit')"
                    :to="`/app/partner/${partner.id}/edit`"
                  />
                  <AppIconButton
                    icon="i-lucide-trash-2"
                    color="error"
                    :aria-label="t('common.delete')"
                    @click="openDelete(partner)"
                  />
                </template>
                <AppIconButton
                  v-else-if="canViewDeletedRecords"
                  icon="i-lucide-rotate-ccw"
                  color="primary"
                  :aria-label="t('common.restore')"
                  @click="openRestore(partner)"
                />
              </div>
            </AppDataTableTd>
          </AppDataTableRow>
        </AppDataTable>

        <AppPagination
          v-if="filteredPartners.length"
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

    <MasterDataPartnerDeleteModal
      v-if="deleteTarget"
      v-model:open="deleteOpen"
      :partner-id="deleteTarget.id"
      :partner-name="partnerDisplayLabel(deleteTarget)"
      @deleted="onDeleted"
    />

    <MasterDataPartnerRestoreModal
      v-if="restoreTarget"
      v-model:open="restoreOpen"
      :partner-id="restoreTarget.id"
      :partner-name="partnerDisplayLabel(restoreTarget)"
      @restored="onRestored"
    />
  </div>
</template>
