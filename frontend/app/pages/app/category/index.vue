<script setup lang="ts">
import type { Category } from '~/types/crm'
import { appFormFieldClass, appSelectMenuUi, appTableTextClass } from '~/config/appFormUi'
import { CATEGORY_STATUSES } from '~/config/masterCategory'
import { categoryDisplayLabel } from '~/utils/masterCategory'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { formatDateTime } = useFormat()
const { ensureProfile } = useProfile()
const { list, listDeleted } = useCategories()
const { archiveTab, canViewDeletedRecords, isActiveArchive, ensureArchiveAccess } = useArchiveTabs()

await ensureProfile()
await ensureArchiveAccess()

const categories = ref<Category[]>([])
const loading = ref(true)
const search = ref('')
const statusFilter = ref<string | null>(null)
const deleteOpen = ref(false)
const deleteTarget = ref<Category | null>(null)
const restoreOpen = ref(false)
const restoreTarget = ref<Category | null>(null)

async function refresh() {
  loading.value = true
  try {
    categories.value = isActiveArchive.value
      ? await list()
      : await listDeleted()
  } catch (e) {
    console.error(e)
    categories.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

const statusFilterOptions = computed(() => [
  { value: null, label: t('masterData.category.filters.allStatuses') },
  ...CATEGORY_STATUSES.map(value => ({
    value,
    label: t(`masterData.category.options.status.${value}`)
  }))
])

const filteredCategories = computed(() => {
  let rows = categories.value
  if (isActiveArchive.value && statusFilter.value) {
    rows = rows.filter(c => c.status === statusFilter.value)
  }

  const q = search.value.trim().toLowerCase()
  if (!q) return rows
  return rows.filter((c) => {
    const code = c.category_code.toLowerCase()
    const name = c.name.toLowerCase()
    const parent = parentLabel(c).toLowerCase()
    return code.includes(q) || name.includes(q) || parent.includes(q)
  })
})

const categoryById = computed(() => new Map(categories.value.map(c => [c.id, c])))

function parentLabel(category: Category) {
  if (!category.parent_id) {
    return t('masterData.category.fields.noParent')
  }
  const parent = categoryById.value.get(category.parent_id)
  if (!parent) {
    return t('common.empty')
  }
  return categoryDisplayLabel(parent)
}

function isParentDeleted(category: Category) {
  if (!category.parent_id) return false
  const parent = categoryById.value.get(category.parent_id)
  return Boolean(parent?.deleted_at)
}

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
} = usePagination(filteredCategories)

function openDelete(category: Category) {
  deleteTarget.value = category
  deleteOpen.value = true
}

function openRestore(category: Category) {
  restoreTarget.value = category
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
          {{ t('masterData.category.listTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.category.listSubtitle') }}
        </p>
      </div>
      <UButton
        v-if="isActiveArchive"
        icon="i-lucide-plus"
        to="/app/category/new"
      >
        {{ t('masterData.category.create') }}
      </UButton>
    </div>

    <AppArchiveTabs
      v-model:archive-tab="archiveTab"
      :can-view-deleted="canViewDeletedRecords"
      :active-label="t('masterData.category.filters.activeRecords')"
      :deleted-label="t('masterData.category.filters.deletedRecords')"
      :aria-label="t('masterData.category.filters.archiveTabs')"
    />

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!categories.length">
      <p class="text-gray-500">
        {{ isActiveArchive ? t('masterData.category.empty') : t('masterData.category.filters.emptyDeleted') }}
      </p>
      <UButton
        v-if="isActiveArchive"
        class="mt-4"
        size="sm"
        icon="i-lucide-plus"
        to="/app/category/new"
      >
        {{ t('masterData.category.createFirst') }}
      </UButton>
    </UCard>

    <div v-else>
      <UCard class="mb-4">
        <div class="flex flex-wrap items-end gap-3">
          <UFormField
            v-if="isActiveArchive"
            :label="t('masterData.category.filters.byStatus')"
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
            :placeholder="t('masterData.category.filters.search')"
          />

          <UButton
            v-if="hasActiveFilters"
            variant="soft"
            color="neutral"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.category.filters.viewAll') }}
          </UButton>
        </div>
      </UCard>

      <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800">
        <p
          class="border-b border-gray-200 px-3 py-2 text-gray-600 dark:border-gray-800 dark:text-gray-400"
          :class="appTableTextClass"
        >
          {{ t('masterData.category.filters.displayCount', { count: paginationTotal }) }}
        </p>

        <div
          v-if="!filteredCategories.length"
          class="px-4 py-8 text-center"
        >
          <p class="text-gray-500">
            {{ t('masterData.category.filters.noResults') }}
          </p>
          <UButton
            class="mt-4"
            size="sm"
            variant="soft"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.category.filters.viewAll') }}
          </UButton>
        </div>

        <AppDataTable
          v-else
          embedded
        >
          <template #head>
            <tr>
              <AppDataTableTh class="w-14">{{ t('masterData.category.fields.image') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.category.fields.code') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.category.fields.name') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.category.fields.parent') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.category.fields.sortOrder') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.category.fields.status') }}</AppDataTableTh>
              <AppDataTableTh v-if="canViewDeletedRecords && !isActiveArchive">
                {{ t('masterData.category.filters.deletedAt') }}
              </AppDataTableTh>
              <AppDataTableTh />
            </tr>
          </template>

          <AppDataTableRow
            v-for="c in pagedItems"
            :key="c.id"
          >
            <AppDataTableTd>
              <div
                class="flex size-10 items-center justify-center overflow-hidden rounded-lg border border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800/50"
              >
                <img
                  v-if="c.image_url"
                  :src="c.image_url"
                  :alt="c.name"
                  class="h-full w-full object-cover"
                >
                <UIcon
                  v-else
                  name="i-lucide-tags"
                  class="size-4 text-gray-400"
                />
              </div>
            </AppDataTableTd>
            <AppDataTableTd>
              <div class="flex items-center gap-2">
                <span
                  v-if="c.color && isActiveArchive"
                  class="inline-block size-2.5 shrink-0 rounded-full"
                  :style="{ backgroundColor: c.color }"
                />
                <NuxtLink
                  v-if="isActiveArchive"
                  :to="`/app/category/${c.id}`"
                  class="font-medium text-primary hover:underline"
                >
                  {{ c.category_code }}
                </NuxtLink>
                <span
                  v-else
                  class="font-medium"
                >
                  {{ c.category_code }}
                </span>
              </div>
            </AppDataTableTd>
            <AppDataTableTd>
              {{ c.name }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              <div class="flex flex-wrap items-center gap-2">
                <span>{{ parentLabel(c) }}</span>
                <UBadge
                  v-if="!isActiveArchive && isParentDeleted(c)"
                  color="warning"
                  variant="subtle"
                  size="xs"
                >
                  {{ t('masterData.category.filters.parentDeletedBadge') }}
                </UBadge>
              </div>
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ c.sort_order }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              <UBadge
                :color="c.status === 'active' ? 'success' : 'neutral'"
                variant="subtle"
                size="xs"
              >
                {{ t(`masterData.category.options.status.${c.status}`) }}
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
                    :aria-label="t('masterData.category.view')"
                    :to="`/app/category/${c.id}`"
                  />
                  <AppIconButton
                    icon="i-lucide-pencil"
                    :aria-label="t('common.edit')"
                    :to="`/app/category/${c.id}/edit`"
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
          v-if="filteredCategories.length"
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

    <MasterDataCategoryDeleteModal
      v-if="deleteTarget"
      v-model:open="deleteOpen"
      :category-id="deleteTarget.id"
      :category-name="categoryDisplayLabel(deleteTarget)"
      :image-url="deleteTarget.image_url"
      @deleted="onDeleted"
    />

    <MasterDataCategoryRestoreModal
      v-if="restoreTarget"
      v-model:open="restoreOpen"
      :category-id="restoreTarget.id"
      :category-name="categoryDisplayLabel(restoreTarget)"
      :parent-deleted="isParentDeleted(restoreTarget)"
      @restored="onRestored"
    />
  </div>
</template>
