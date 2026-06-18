<script setup lang="ts">
import type { Company } from '~/types/crm'
import {
  CUSTOMER_INDUSTRY_SEGMENTS,
  CUSTOMER_SALES_GRADES,
  CUSTOMER_STATUSES,
  CUSTOMER_TYPES,
  customerStatusBadgeColor,
  type CustomerIndustrySegment,
  type CustomerSalesGrade,
  type CustomerStatus,
  type CustomerType
} from '~/config/masterCustomer'
import {
  appTableBadgeClass,
  appTableRoleTabActiveClass,
  appTableRoleTabBaseClass,
  appTableRoleTabInactiveClass,
  appTableTextClass
} from '~/config/appFormUi'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { formatDateTime } = useFormat()
const { ensureProfile } = useProfile()
const { list, listDeleted } = useCompanies()
const { archiveTab, canViewDeletedRecords, isActiveArchive, ensureArchiveAccess } = useArchiveTabs()

await ensureProfile()
await ensureArchiveAccess()

type CustomerSearchField = 'all' | 'name' | 'phone' | 'industry'
type StatusTab = 'all' | CustomerStatus

const companies = ref<Company[]>([])
const loading = ref(true)
const search = ref('')
const searchField = ref<CustomerSearchField>('all')
const statusTab = ref<StatusTab>('all')
const restoreOpen = ref(false)
const restoreTarget = ref<Company | null>(null)

const searchFieldOptions = computed(() => [
  { label: t('masterData.customer.filters.viewAll'), value: 'all' as const },
  { label: t('masterData.customer.filters.byName'), value: 'name' as const },
  { label: t('masterData.customer.filters.byPhone'), value: 'phone' as const },
  { label: t('masterData.customer.filters.byIndustry'), value: 'industry' as const }
])

const statusTabs = computed(() => [
  { label: t('masterData.customer.filters.viewAll'), value: 'all' as const },
  ...CUSTOMER_STATUSES.map(value => ({
    label: t(`masterData.customer.options.status.${value}`),
    value
  }))
])

async function refresh() {
  loading.value = true
  try {
    companies.value = isActiveArchive.value
      ? await list()
      : await listDeleted()
  } catch (e) {
    console.error(e)
    companies.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

function openRestore(company: Company) {
  restoreTarget.value = company
  restoreOpen.value = true
}

async function onRestored() {
  restoreTarget.value = null
  await refresh()
  resetPagination()
}

watch(archiveTab, async () => {
  statusTab.value = 'all'
  search.value = ''
  searchField.value = 'all'
  resetPagination()
  await refresh()
})

function industryLabel(slug: string | null | undefined) {
  if (!slug) return ''
  return t(`masterData.customer.options.industry.${slug}` as const)
}

function customerTypeLabel(slug: string | null | undefined) {
  if (slug && (CUSTOMER_TYPES as readonly string[]).includes(slug)) {
    return t(`masterData.customer.options.customerType.${slug as CustomerType}`)
  }
  return slug ?? t('common.empty')
}

function industrySegmentLabel(slug: string | null | undefined) {
  if (slug && (CUSTOMER_INDUSTRY_SEGMENTS as readonly string[]).includes(slug)) {
    return t(`masterData.customer.options.industrySegment.${slug as CustomerIndustrySegment}`)
  }
  return slug ?? t('common.empty')
}

function salesGradeLabel(slug: string | null | undefined) {
  if (slug && (CUSTOMER_SALES_GRADES as readonly string[]).includes(slug)) {
    return t(`masterData.customer.options.salesGrade.${slug as CustomerSalesGrade}`)
  }
  return slug ?? t('common.empty')
}

function statusLabel(status: string | null | undefined) {
  if (status && (CUSTOMER_STATUSES as readonly string[]).includes(status)) {
    return t(`masterData.customer.options.status.${status as CustomerStatus}`)
  }
  return status ?? t('common.empty')
}

function statusBadgeColor(status: string | null | undefined) {
  if (status && status in customerStatusBadgeColor) {
    return customerStatusBadgeColor[status as CustomerStatus]
  }
  return 'neutral' as const
}

const filteredCompanies = computed(() => {
  let rows = companies.value
  if (isActiveArchive.value && statusTab.value !== 'all') {
    rows = rows.filter(c => c.status === statusTab.value)
  }

  const q = search.value.trim().toLowerCase()
  if (!q) return rows

  return rows.filter((c) => {
    const name = c.name.toLowerCase()
    const phone = (c.phone ?? '').toLowerCase()
    const industry = `${c.industry ?? ''} ${industryLabel(c.industry)}`.toLowerCase()

    if (searchField.value === 'name') return name.includes(q)
    if (searchField.value === 'phone') return phone.includes(q)
    if (searchField.value === 'industry') return industry.includes(q)
    return name.includes(q) || phone.includes(q) || industry.includes(q)
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
} = usePagination(filteredCompanies)

const hasActiveFilters = computed(() =>
  search.value.trim().length > 0
  || searchField.value !== 'all'
  || (isActiveArchive.value && statusTab.value !== 'all')
)

function clearFilters() {
  search.value = ''
  searchField.value = 'all'
  statusTab.value = 'all'
  resetPagination()
}
</script>

<template>
  <div>
    <div class="mb-6 flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold font-heading">
          {{ t('masterData.customer.listTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.customer.listSubtitle') }}
        </p>
      </div>
      <UButton
        v-if="isActiveArchive"
        icon="i-lucide-plus"
        to="/app/customer/new"
      >
        {{ t('masterData.customer.create') }}
      </UButton>
    </div>

    <AppArchiveTabs
      v-model:archive-tab="archiveTab"
      :can-view-deleted="canViewDeletedRecords"
      :active-label="t('masterData.customer.filters.activeRecords')"
      :deleted-label="t('masterData.customer.filters.deletedRecords')"
      :aria-label="t('masterData.customer.filters.archiveTabs')"
    />

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!companies.length">
      <p class="text-gray-500">
        {{ isActiveArchive ? t('masterData.customer.empty') : t('masterData.customer.filters.emptyDeleted') }}
      </p>
      <UButton
        v-if="isActiveArchive"
        class="mt-4"
        size="sm"
        icon="i-lucide-plus"
        to="/app/customer/new"
      >
        {{ t('masterData.customer.createFirst') }}
      </UButton>
    </UCard>

    <div v-else>
      <UCard class="mb-4">
        <div class="flex flex-wrap items-end gap-3">
          <UFormField
            :label="t('masterData.customer.filters.searchBy')"
            class="min-w-44"
          >
            <USelectMenu
              v-model="searchField"
              :items="searchFieldOptions"
              value-key="value"
              class="w-full"
            />
          </UFormField>

          <UInput
            v-model="search"
            class="min-w-0 flex-1"
            icon="i-lucide-search"
            :placeholder="t('masterData.customer.filters.search')"
          />

          <UButton
            v-if="hasActiveFilters"
            variant="soft"
            color="neutral"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.customer.filters.viewAll') }}
          </UButton>
        </div>
      </UCard>

      <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800">
        <div
          v-if="isActiveArchive"
          class="flex flex-wrap gap-2 border-b border-gray-200 bg-gray-50/90 px-3 py-2.5 dark:border-gray-800 dark:bg-gray-900/60"
          role="tablist"
          :aria-label="t('masterData.customer.filters.statusTabs')"
        >
          <button
            v-for="tab in statusTabs"
            :key="tab.value"
            type="button"
            role="tab"
            :aria-selected="statusTab === tab.value"
            :class="[
              appTableRoleTabBaseClass,
              appTableTextClass,
              statusTab === tab.value ? appTableRoleTabActiveClass : appTableRoleTabInactiveClass
            ]"
            @click="statusTab = tab.value"
          >
            {{ tab.label }}
          </button>
        </div>

        <p
          class="border-b border-gray-200 px-3 py-2 text-gray-600 dark:border-gray-800 dark:text-gray-400"
          :class="appTableTextClass"
        >
          {{ t('masterData.customer.filters.displayCount', { count: paginationTotal }) }}
        </p>

        <div
          v-if="!filteredCompanies.length"
          class="px-4 py-8 text-center"
        >
          <p class="text-gray-500">
            {{ t('masterData.customer.filters.noResults') }}
          </p>
          <UButton
            class="mt-4"
            size="sm"
            variant="soft"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.customer.filters.viewAll') }}
          </UButton>
        </div>

        <AppDataTable
          v-else
          embedded
          table-class="min-w-[72rem]"
        >
          <template #head>
            <tr>
              <AppDataTableTh>{{ t('masterData.customer.fields.companyName') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.customer.fields.customerType') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.customer.fields.phone') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.customer.fields.email') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.customer.fields.salesGrade') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.customer.fields.industrySegment') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.customer.fields.status') }}</AppDataTableTh>
              <AppDataTableTh v-if="canViewDeletedRecords && !isActiveArchive">
                {{ t('masterData.customer.filters.deletedAt') }}
              </AppDataTableTh>
              <AppDataTableTh />
            </tr>
          </template>

          <AppDataTableRow
            v-for="c in pagedItems"
            :key="c.id"
          >
            <AppDataTableTd>
              <span
                v-if="isActiveArchive"
                class="font-medium text-primary"
              >
                <NuxtLink
                  :to="`/app/customer/${c.id}`"
                  class="hover:underline"
                >
                  {{ c.name }}
                </NuxtLink>
              </span>
              <span
                v-else
                class="font-medium"
              >
                {{ c.name }}
              </span>
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ customerTypeLabel(c.customer_type) }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ c.phone || t('common.empty') }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ c.email || t('common.empty') }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ salesGradeLabel(c.sales_grade) }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ industrySegmentLabel(c.industry_segment) }}
            </AppDataTableTd>
            <AppDataTableTd>
              <UBadge
                :color="statusBadgeColor(c.status)"
                variant="subtle"
                :class="appTableBadgeClass"
              >
                {{ statusLabel(c.status) }}
              </UBadge>
            </AppDataTableTd>
            <AppDataTableTd
              v-if="canViewDeletedRecords && !isActiveArchive"
              muted
            >
              {{ formatDateTime(c.deleted_at) }}
            </AppDataTableTd>
            <AppDataTableTd align="right">
              <div class="flex items-center justify-end gap-1">
                <template v-if="isActiveArchive">
                  <AppIconButton
                    icon="i-lucide-eye"
                    :aria-label="t('masterData.customer.view')"
                    :to="`/app/customer/${c.id}`"
                  />
                  <AppIconButton
                    icon="i-lucide-pencil"
                    :aria-label="t('common.edit')"
                    :to="`/app/customer/${c.id}/edit`"
                  />
                </template>
                <AppIconButton
                  v-else-if="canViewDeletedRecords"
                  icon="i-lucide-rotate-ccw"
                  color="primary"
                  :aria-label="t('common.restore')"
                  @click="openRestore(c)"
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
    </div>

    <MasterDataCustomerRestoreModal
      v-if="restoreTarget"
      v-model:open="restoreOpen"
      :customer-id="restoreTarget.id"
      :customer-name="restoreTarget.name"
      @restored="onRestored"
    />
  </div>
</template>
