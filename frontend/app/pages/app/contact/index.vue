<script setup lang="ts">
import type { Contact } from '~/types/crm'
import { appFormFieldClass, appSelectMenuUi, appTableTextClass } from '~/config/appFormUi'
import { contactDisplayName } from '~/utils/masterContact'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { formatDateTime } = useFormat()
const { ensureProfile } = useProfile()
const { list, listDeleted } = useContacts()
const { list: listCompanies } = useCompanies()
const { archiveTab, canViewDeletedRecords, isActiveArchive, ensureArchiveAccess } = useArchiveTabs()

await ensureProfile()
await ensureArchiveAccess()

const contacts = ref<Contact[]>([])
const companies = ref<{ label: string, value: string }[]>([])
const loading = ref(true)
const search = ref('')
const companyFilter = ref<string | null>(null)
const deleteOpen = ref(false)
const deleteTarget = ref<Contact | null>(null)
const restoreOpen = ref(false)
const restoreTarget = ref<Contact | null>(null)

async function refresh() {
  loading.value = true
  try {
    const companyRows = await listCompanies()
    companies.value = companyRows.map(c => ({ label: c.name, value: c.id }))
    contacts.value = isActiveArchive.value
      ? await list()
      : await listDeleted()
  } catch (e) {
    console.error(e)
    contacts.value = []
    companies.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

const companyFilterOptions = computed(() => [
  { value: null, label: t('masterData.contact.filters.allCustomers') },
  ...companies.value
])

const filteredContacts = computed(() => {
  let rows = contacts.value
  if (isActiveArchive.value && companyFilter.value) {
    rows = rows.filter(c => c.company_id === companyFilter.value)
  }

  const q = search.value.trim().toLowerCase()
  if (!q) return rows
  return rows.filter((c) => {
    const name = contactDisplayName(c).toLowerCase()
    const email = (c.email ?? '').toLowerCase()
    const phone = (c.phone ?? '').toLowerCase()
    const customer = (c.companies?.name ?? '').toLowerCase()
    return name.includes(q) || email.includes(q) || phone.includes(q) || customer.includes(q)
  })
})

const hasActiveFilters = computed(() =>
  search.value.trim().length > 0 || (isActiveArchive.value && companyFilter.value !== null)
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
} = usePagination(filteredContacts)

function openDelete(contact: Contact) {
  deleteTarget.value = contact
  deleteOpen.value = true
}

function openRestore(contact: Contact) {
  restoreTarget.value = contact
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

watch([search, companyFilter], () => {
  resetPagination()
})

watch(archiveTab, async () => {
  search.value = ''
  companyFilter.value = null
  resetPagination()
  await refresh()
})

function clearFilters() {
  search.value = ''
  companyFilter.value = null
  resetPagination()
}

function isCustomerDeleted(contact: Contact) {
  return Boolean(contact.companies?.deleted_at)
}
</script>

<template>
  <div>
    <div class="mb-6 flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold font-heading">
          {{ t('masterData.contact.listTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.contact.listSubtitle') }}
        </p>
      </div>
      <UButton
        v-if="isActiveArchive"
        icon="i-lucide-plus"
        to="/app/contact/new"
      >
        {{ t('masterData.contact.create') }}
      </UButton>
    </div>

    <AppArchiveTabs
      v-model:archive-tab="archiveTab"
      :can-view-deleted="canViewDeletedRecords"
      :active-label="t('masterData.contact.filters.activeRecords')"
      :deleted-label="t('masterData.contact.filters.deletedRecords')"
      :aria-label="t('masterData.contact.filters.archiveTabs')"
    />

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!contacts.length">
      <p class="text-gray-500">
        {{ isActiveArchive ? t('masterData.contact.empty') : t('masterData.contact.filters.emptyDeleted') }}
      </p>
      <UButton
        v-if="isActiveArchive"
        class="mt-4"
        size="sm"
        icon="i-lucide-plus"
        to="/app/contact/new"
      >
        {{ t('masterData.contact.createFirst') }}
      </UButton>
    </UCard>

    <div v-else>
      <UCard class="mb-4">
        <div class="flex flex-wrap items-end gap-3">
          <UFormField
            v-if="isActiveArchive"
            :label="t('masterData.contact.filters.byCustomer')"
            class="min-w-56"
          >
            <USelectMenu
              v-model="companyFilter"
              :items="companyFilterOptions"
              value-key="value"
              searchable
              :placeholder="t('masterData.contact.filters.customerPlaceholder')"
              class="w-full"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
          </UFormField>

          <UInput
            v-model="search"
            class="min-w-0 flex-1"
            icon="i-lucide-search"
            :placeholder="t('masterData.contact.filters.search')"
          />

          <UButton
            v-if="hasActiveFilters"
            variant="soft"
            color="neutral"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.contact.filters.viewAll') }}
          </UButton>
        </div>
      </UCard>

      <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800">
        <p
          class="border-b border-gray-200 px-3 py-2 text-gray-600 dark:border-gray-800 dark:text-gray-400"
          :class="appTableTextClass"
        >
          {{ t('masterData.contact.filters.displayCount', { count: paginationTotal }) }}
        </p>

        <div
          v-if="!filteredContacts.length"
          class="px-4 py-8 text-center"
        >
          <p class="text-gray-500">
            {{ t('masterData.contact.filters.noResults') }}
          </p>
          <UButton
            class="mt-4"
            size="sm"
            variant="soft"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.contact.filters.viewAll') }}
          </UButton>
        </div>

        <AppDataTable
          v-else
          embedded
        >
          <template #head>
            <tr>
              <AppDataTableTh>{{ t('masterData.contact.fields.name') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.contact.fields.customer') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.contact.fields.email') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.contact.fields.phone') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.contact.fields.role') }}</AppDataTableTh>
              <AppDataTableTh v-if="canViewDeletedRecords && !isActiveArchive">
                {{ t('masterData.contact.filters.deletedAt') }}
              </AppDataTableTh>
              <AppDataTableTh />
            </tr>
          </template>

          <AppDataTableRow
            v-for="c in pagedItems"
            :key="c.id"
          >
            <AppDataTableTd>
              <div class="flex items-center gap-2">
                <NuxtLink
                  v-if="isActiveArchive"
                  :to="`/app/contact/${c.id}`"
                  class="font-medium text-primary hover:underline"
                >
                  {{ contactDisplayName(c) }}
                </NuxtLink>
                <span
                  v-else
                  class="font-medium"
                >
                  {{ contactDisplayName(c) }}
                </span>
                <UBadge
                  v-if="c.is_main_contact && isActiveArchive"
                  color="primary"
                  variant="subtle"
                  size="xs"
                >
                  {{ t('masterData.contact.fields.mainContact') }}
                </UBadge>
              </div>
            </AppDataTableTd>
            <AppDataTableTd muted>
              <div class="flex flex-wrap items-center gap-2">
                <span>{{ c.companies?.name || t('common.empty') }}</span>
                <UBadge
                  v-if="!isActiveArchive && isCustomerDeleted(c)"
                  color="warning"
                  variant="subtle"
                  size="xs"
                >
                  {{ t('masterData.contact.filters.customerDeletedBadge') }}
                </UBadge>
              </div>
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ c.email || t('common.empty') }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ c.phone || t('common.empty') }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{
                c.contact_role
                  ? t(`masterData.contact.options.role.${c.contact_role}`)
                  : t('common.empty')
              }}
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
                    :aria-label="t('masterData.contact.view')"
                    :to="`/app/contact/${c.id}`"
                  />
                  <AppIconButton
                    icon="i-lucide-pencil"
                    :aria-label="t('common.edit')"
                    :to="`/app/contact/${c.id}/edit`"
                  />
                  <AppIconButton
                    icon="i-lucide-trash-2"
                    color="error"
                    :aria-label="t('common.delete')"
                    @click="openDelete(c)"
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
          v-if="filteredContacts.length"
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

    <MasterDataContactDeleteModal
      v-if="deleteTarget"
      v-model:open="deleteOpen"
      :contact-id="deleteTarget.id"
      :contact-name="contactDisplayName(deleteTarget)"
      @deleted="onDeleted"
    />

    <MasterDataContactRestoreModal
      v-if="restoreTarget"
      v-model:open="restoreOpen"
      :contact-id="restoreTarget.id"
      :contact-name="contactDisplayName(restoreTarget)"
      :customer-deleted="isCustomerDeleted(restoreTarget)"
      @restored="onRestored"
    />
  </div>
</template>
