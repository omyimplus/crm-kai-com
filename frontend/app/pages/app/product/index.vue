<script setup lang="ts">
import type { Category, Product, Unit } from '~/types/crm'
import { appFormFieldClass, appSelectMenuUi, appTableTextClass } from '~/config/appFormUi'
import { PRODUCT_STATUSES } from '~/config/masterProduct'
import { productCategoryLabel, productDisplayLabel, productUnitLabel } from '~/utils/masterProduct'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { formatCurrency, formatDateTime } = useFormat()
const { ensureProfile } = useProfile()
const { list, listDeleted } = useProducts()
const { list: listCategories } = useCategories()
const { list: listUnits } = useUnits()
const { archiveTab, canViewDeletedRecords, isActiveArchive, ensureArchiveAccess } = useArchiveTabs()

await ensureProfile()
await ensureArchiveAccess()

const products = ref<Product[]>([])
const categories = ref<Category[]>([])
const units = ref<Unit[]>([])
const loading = ref(true)
const search = ref('')
const statusFilter = ref<string | null>(null)
const deleteOpen = ref(false)
const deleteTarget = ref<Product | null>(null)
const restoreOpen = ref(false)
const restoreTarget = ref<Product | null>(null)

async function refresh() {
  loading.value = true
  try {
    const [productRows, categoryRows, unitRows] = await Promise.all([
      isActiveArchive.value ? list() : listDeleted(),
      listCategories(),
      listUnits()
    ])
    products.value = productRows
    categories.value = categoryRows
    units.value = unitRows
  } catch (e) {
    console.error(e)
    products.value = []
    categories.value = []
    units.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

const statusFilterOptions = computed(() => [
  { value: null, label: t('masterData.products.filters.allStatuses') },
  ...PRODUCT_STATUSES.map(value => ({
    value,
    label: t(`masterData.products.options.status.${value}`)
  }))
])

const filteredProducts = computed(() => {
  let rows = products.value
  if (isActiveArchive.value && statusFilter.value) {
    rows = rows.filter(p => product.status === statusFilter.value)
  }

  const q = search.value.trim().toLowerCase()
  if (!q) return rows
  return rows.filter((p) => {
    const code = product.product_code.toLowerCase()
    const name = product.name.toLowerCase()
    const category = (productCategoryLabel(product.category_id, categories.value) ?? '').toLowerCase()
    const unit = (productUnitLabel(product.unit_id, units.value) ?? '').toLowerCase()
    const barcode = (product.barcode ?? '').toLowerCase()
    return code.includes(q) || name.includes(q) || category.includes(q) || unit.includes(q) || barcode.includes(q)
  })
})

const categoryById = computed(() => new Map(categories.value.map(c => [c.id, c])))
const unitById = computed(() => new Map(units.value.map(u => [u.id, u])))

function categoryCell(product: Product) {
  return productCategoryLabel(product.category_id, categories.value)
}

function unitCell(product: Product) {
  return productUnitLabel(product.unit_id, units.value)
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
} = usePagination(filteredProducts)

function openDelete(product: Product) {
  deleteTarget.value = product
  deleteOpen.value = true
}

function openRestore(product: Product) {
  restoreTarget.value = product
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
          {{ t('masterData.products.listTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.products.listSubtitle') }}
        </p>
      </div>
      <UButton
        v-if="isActiveArchive"
        icon="i-lucide-plus"
        to="/app/product/new"
      >
        {{ t('masterData.products.create') }}
      </UButton>
    </div>

    <AppArchiveTabs
      v-model:archive-tab="archiveTab"
      :can-view-deleted="canViewDeletedRecords"
      :active-label="t('masterData.products.filters.activeRecords')"
      :deleted-label="t('masterData.products.filters.deletedRecords')"
      :aria-label="t('masterData.products.filters.archiveTabs')"
    />

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!products.length">
      <p class="text-gray-500">
        {{ isActiveArchive ? t('masterData.products.empty') : t('masterData.products.filters.emptyDeleted') }}
      </p>
      <UButton
        v-if="isActiveArchive"
        class="mt-4"
        size="sm"
        icon="i-lucide-plus"
        to="/app/product/new"
      >
        {{ t('masterData.products.createFirst') }}
      </UButton>
    </UCard>

    <div v-else>
      <UCard class="mb-4">
        <div class="flex flex-wrap items-end gap-3">
          <UFormField
            v-if="isActiveArchive"
            :label="t('masterData.products.filters.byStatus')"
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
            :placeholder="t('masterData.products.filters.search')"
          />

          <UButton
            v-if="hasActiveFilters"
            variant="soft"
            color="neutral"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.products.filters.viewAll') }}
          </UButton>
        </div>
      </UCard>

      <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800">
        <p
          class="border-b border-gray-200 px-3 py-2 text-gray-600 dark:border-gray-800 dark:text-gray-400"
          :class="appTableTextClass"
        >
          {{ t('masterData.products.filters.displayCount', { count: paginationTotal }) }}
        </p>

        <div
          v-if="!filteredProducts.length"
          class="px-4 py-8 text-center"
        >
          <p class="text-gray-500">
            {{ t('masterData.products.filters.noResults') }}
          </p>
          <UButton
            class="mt-4"
            size="sm"
            variant="soft"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('masterData.products.filters.viewAll') }}
          </UButton>
        </div>

        <AppDataTable
          v-else
          embedded
        >
          <template #head>
            <tr>
              <AppDataTableTh class="w-20" aria-hidden="true" />
              <AppDataTableTh>{{ t('masterData.products.fields.code') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.products.fields.name') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.products.fields.category') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.products.fields.unit') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.products.fields.listPrice') }}</AppDataTableTh>
              <AppDataTableTh>{{ t('masterData.products.fields.status') }}</AppDataTableTh>
              <AppDataTableTh v-if="canViewDeletedRecords && !isActiveArchive">
                {{ t('masterData.products.filters.deletedAt') }}
              </AppDataTableTh>
              <AppDataTableTh />
            </tr>
          </template>

          <AppDataTableRow
            v-for="product in pagedItems"
            :key="product.id"
          >
            <AppDataTableTd class="w-20">
              <div
                class="flex size-16 items-center justify-center overflow-hidden rounded-lg border border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800/50"
              >
                <img
                  v-if="product.image_url"
                  :src="product.image_url"
                  :alt="product.name"
                  class="h-full w-full object-cover"
                >
                <UIcon
                  v-else
                  name="i-lucide-package"
                  class="size-6 text-gray-400"
                />
              </div>
            </AppDataTableTd>
            <AppDataTableTd>
              <NuxtLink
                v-if="isActiveArchive"
                :to="`/app/product/${product.id}`"
                class="font-medium text-primary hover:underline"
              >
                {{ product.product_code }}
              </NuxtLink>
              <span
                v-else
                class="font-medium"
              >
                {{ product.product_code }}
              </span>
            </AppDataTableTd>
            <AppDataTableTd>
              {{ product.name }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              <div
                v-if="product.category_id && categoryById.get(product.category_id)"
                class="flex items-center gap-2"
              >
                <div
                  class="flex size-8 shrink-0 items-center justify-center overflow-hidden rounded-md border border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800/50"
                >
                  <img
                    v-if="categoryById.get(product.category_id)?.image_url"
                    :src="categoryById.get(product.category_id)!.image_url!"
                    :alt="categoryById.get(product.category_id)!.name"
                    class="h-full w-full object-cover"
                  >
                  <UIcon
                    v-else
                    name="i-lucide-tags"
                    class="size-3.5 text-gray-400"
                  />
                </div>
                <NuxtLink
                  v-if="isActiveArchive"
                  :to="`/app/category/${product.category_id}`"
                  class="text-primary hover:underline"
                >
                  {{ categoryCell(product) }}
                </NuxtLink>
                <span v-else>{{ categoryCell(product) }}</span>
              </div>
              <span v-else>{{ t('common.empty') }}</span>
            </AppDataTableTd>
            <AppDataTableTd muted>
              <NuxtLink
                v-if="product.unit_id && unitById.get(product.unit_id) && isActiveArchive"
                :to="`/app/unit/${product.unit_id}`"
                class="text-primary hover:underline"
              >
                {{ unitCell(product) }}
              </NuxtLink>
              <span v-else-if="product.unit_id && unitById.get(product.unit_id)">
                {{ unitCell(product) }}
              </span>
              <span v-else>{{ t('common.empty') }}</span>
            </AppDataTableTd>
            <AppDataTableTd muted>
              {{ formatCurrency(Number(product.list_price), product.currency) }}
            </AppDataTableTd>
            <AppDataTableTd muted>
              <UBadge
                :color="product.status === 'active' ? 'success' : 'neutral'"
                variant="subtle"
                size="xs"
              >
                {{ t(`masterData.products.options.status.${product.status}`) }}
              </UBadge>
            </AppDataTableTd>
            <AppDataTableTd
              v-if="canViewDeletedRecords && !isActiveArchive"
              muted
            >
              {{ formatDateTime(product.deleted_at) }}
            </AppDataTableTd>
            <AppDataTableTd align="right">
              <div class="flex items-center justify-end gap-1">
                <template v-if="isActiveArchive">
                  <AppIconButton
                    icon="i-lucide-eye"
                    :aria-label="t('masterData.products.view')"
                    :to="`/app/product/${product.id}`"
                  />
                  <AppIconButton
                    icon="i-lucide-pencil"
                    :aria-label="t('common.edit')"
                    :to="`/app/product/${product.id}/edit`"
                  />
                  <AppIconButton
                    icon="i-lucide-trash-2"
                    color="error"
                    :aria-label="t('common.delete')"
                    @click="openDelete(product)"
                  />
                </template>
                <AppIconButton
                  v-else-if="canViewDeletedRecords"
                  icon="i-lucide-rotate-ccw"
                  color="primary"
                  :aria-label="t('common.restore')"
                  @click="openRestore(product)"
                />
              </div>
            </AppDataTableTd>
          </AppDataTableRow>
        </AppDataTable>

        <AppPagination
          v-if="filteredProducts.length"
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

    <MasterDataProductDeleteModal
      v-if="deleteTarget"
      v-model:open="deleteOpen"
      :product-id="deleteTarget.id"
      :product-name="productDisplayLabel(deleteTarget)"
      :image-url="deleteTarget.image_url"
      @deleted="onDeleted"
    />

    <MasterDataProductRestoreModal
      v-if="restoreTarget"
      v-model:open="restoreOpen"
      :product-id="restoreTarget.id"
      :product-name="productDisplayLabel(restoreTarget)"
      @restored="onRestored"
    />
  </div>
</template>
