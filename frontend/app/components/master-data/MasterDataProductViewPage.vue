<script setup lang="ts">
import type { Category, Unit } from '~/types/crm'
import {
  productCategoryLabel,
  productCategoryOptions,
  productDisplayLabel,
  productToFormInput,
  productUnitLabel,
  productUnitOptions
} from '~/utils/masterProduct'

const props = defineProps<{
  productId: string
}>()

const { t } = useI18n()
const { list: listCategories } = useCategories()
const { list: listUnits } = useUnits()
const { get } = useProducts()
const { hasCustomImage } = useImageUpload()

const loading = ref(true)
const imageUrl = ref<string | null>(null)
const categories = ref<Category[]>([])
const units = ref<Unit[]>([])
const form = ref(productToFormInput({
  id: '',
  org_id: '',
  product_code: '',
  name: '',
  description: null,
  category_id: null,
  unit_id: null,
  list_price: 0,
  cost_price: null,
  currency: 'THB',
  barcode: null,
  status: 'active',
  is_sellable: true,
  notes: null,
  image_url: null,
  created_at: ''
}))
const categoryOptions = ref<{ label: string, value: string }[]>([])
const unitOptions = ref<{ label: string, value: string }[]>([])
const deleteOpen = ref(false)

const selectedCategory = computed(() =>
  categories.value.find(c => c.id === form.value.category_id) ?? null
)

const selectedUnit = computed(() =>
  units.value.find(u => u.id === form.value.unit_id) ?? null
)

const categoryLabel = computed(() =>
  productCategoryLabel(form.value.category_id, categories.value)
)

const unitLabel = computed(() =>
  productUnitLabel(form.value.unit_id, units.value)
)

const hasImage = computed(() => hasCustomImage(imageUrl.value))

try {
  const [row, categoryRows, unitRows] = await Promise.all([
    get(props.productId),
    listCategories(),
    listUnits()
  ])
  categories.value = categoryRows
  units.value = unitRows
  categoryOptions.value = productCategoryOptions(categoryRows)
  unitOptions.value = productUnitOptions(unitRows)
  form.value = productToFormInput(row)
  imageUrl.value = row.image_url
} catch (e) {
  console.error(e)
  await navigateTo('/app/product')
} finally {
  loading.value = false
}

function onDeleted() {
  navigateTo('/app/product')
}
</script>

<template>
  <div>
    <UButton
      to="/app/product"
      variant="ghost"
      color="neutral"
      icon="i-lucide-arrow-left"
      size="sm"
      class="mb-4"
    >
      {{ t('common.back') }}
    </UButton>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <div
      v-else
      class="lg:grid lg:grid-cols-[minmax(0,1fr)_17rem] lg:items-start lg:gap-6"
    >
      <div class="min-w-0 space-y-6">
        <div class="flex flex-wrap items-center gap-3">
          <div
            v-if="hasImage"
            class="size-14 shrink-0 overflow-hidden rounded-xl border border-gray-200 dark:border-gray-700"
          >
            <img
              :src="imageUrl!"
              :alt="form.name"
              class="h-full w-full object-cover"
            >
          </div>
          <div>
            <h1 class="text-2xl font-bold font-heading">
              {{ productDisplayLabel(form) }}
            </h1>
            <p
              v-if="categoryLabel"
              class="mt-1 text-sm text-gray-500 dark:text-gray-400"
            >
              {{ t('masterData.products.fields.category') }}: {{ categoryLabel }}
            </p>
            <p
              v-if="unitLabel"
              class="mt-1 text-sm text-gray-500 dark:text-gray-400"
            >
              {{ t('masterData.products.fields.unit') }}: {{ unitLabel }}
            </p>
          </div>
        </div>
        <p class="text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.products.viewSubtitle') }}
        </p>

        <MasterDataProductForm
          v-model="form"
          :category-options="categoryOptions"
          :unit-options="unitOptions"
          readonly
        >
          <template #gallery>
            <AppProductGalleryUpload
              :product-id="productId"
              readonly
            />
          </template>
        </MasterDataProductForm>
      </div>

      <aside class="mt-6 space-y-4 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.products.actions') }}
          </p>
          <UButton
            block
            size="lg"
            icon="i-lucide-pencil"
            :to="`/app/product/${productId}/edit`"
          >
            {{ t('common.edit') }}
          </UButton>
          <UButton
            block
            class="mt-2"
            color="error"
            variant="soft"
            icon="i-lucide-trash-2"
            @click="deleteOpen = true"
          >
            {{ t('common.delete') }}
          </UButton>
        </UCard>

        <UCard
          v-if="hasImage"
          class="rounded-2xl"
        >
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.products.fields.image') }}
          </p>
          <div class="overflow-hidden rounded-xl border border-gray-200 dark:border-gray-700">
            <img
              :src="imageUrl!"
              :alt="form.name"
              class="aspect-square w-full object-cover"
            >
          </div>
        </UCard>

        <UCard
          v-if="selectedCategory"
          class="rounded-2xl"
        >
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.products.fields.category') }}
          </p>
          <div
            v-if="selectedCategory.image_url"
            class="mb-3 overflow-hidden rounded-xl border border-gray-200 dark:border-gray-700"
          >
            <img
              :src="selectedCategory.image_url"
              :alt="selectedCategory.name"
              class="aspect-square w-full object-cover"
            >
          </div>
          <NuxtLink
            :to="`/app/category/${selectedCategory.id}`"
            class="text-sm font-medium text-primary hover:underline"
          >
            {{ categoryLabel }}
          </NuxtLink>
        </UCard>

        <UCard
          v-if="selectedUnit"
          class="rounded-2xl"
        >
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.products.fields.unit') }}
          </p>
          <NuxtLink
            :to="`/app/unit/${selectedUnit.id}`"
            class="text-sm font-medium text-primary hover:underline"
          >
            {{ unitLabel }}
          </NuxtLink>
        </UCard>
      </aside>
    </div>

    <MasterDataProductDeleteModal
      v-model:open="deleteOpen"
      :product-id="productId"
      :product-name="productDisplayLabel(form)"
      :image-url="imageUrl"
      @deleted="onDeleted"
    />
  </div>
</template>
