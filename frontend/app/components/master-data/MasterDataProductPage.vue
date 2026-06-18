<script setup lang="ts">
import type { Category, Unit } from '~/types/crm'
import { appFormErrorClass } from '~/config/appFormUi'
import { parentCategoryOptions } from '~/utils/masterCategory'
import {
  defaultMasterProductFormInput,
  productCategoryOptions,
  productUnitOptions,
  productSaveErrorMessage,
  productToFormInput,
  validateMasterProductForm
} from '~/utils/masterProduct'

const props = defineProps<{
  mode: 'new' | 'edit'
  productId?: string | null
}>()

const { t } = useI18n()
const { list: listCategories } = useCategories()
const { list: listUnits } = useUnits()
const { get, create, update, updateImage } = useProducts()
const { uploadProductImage, removeProductImage } = useProductImage()
const {
  previewUrl: imagePreviewUrl,
  changed: imageChanged,
  file: imageFile,
  removed: imageRemoved,
  savedUrl: imageSavedUrl,
  select: onImageSelect,
  remove: onImageRemove,
  reset: resetImageState
} = useImageUploadState()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterProductFormInput())
const categories = ref<Category[]>([])
const units = ref<Unit[]>([])
const categoryOptions = ref<{ label: string, value: string }[]>([])
const unitOptions = ref<{ label: string, value: string }[]>([])
const categoryFormOpen = ref(false)
const unitFormOpen = ref(false)

const isEdit = computed(() => props.mode === 'edit')

const pageTitle = computed(() =>
  isEdit.value ? t('masterData.products.editTitle') : t('masterData.products.newTitle')
)
const pageSubtitle = computed(() =>
  isEdit.value ? t('masterData.products.editSubtitle') : t('masterData.products.newSubtitle')
)

const categoryParentOptions = computed(() => parentCategoryOptions(categories.value))

async function refreshCategoryOptions() {
  categories.value = await listCategories()
  categoryOptions.value = productCategoryOptions(categories.value)
}

async function refreshUnitOptions() {
  units.value = await listUnits()
  unitOptions.value = productUnitOptions(units.value)
}

try {
  await Promise.all([refreshCategoryOptions(), refreshUnitOptions()])
} catch (e) {
  console.error(e)
}

if (isEdit.value && props.productId) {
  try {
    const row = await get(props.productId)
    form.value = productToFormInput(row)
    resetImageState(row.image_url)
  } catch (e) {
    console.error(e)
    await navigateTo('/app/product')
  }
}

function onCategoryCreated(category: Category) {
  form.value = { ...form.value, category_id: category.id }
  refreshCategoryOptions().catch(console.error)
}

function onUnitCreated(unit: Unit) {
  form.value = { ...form.value, unit_id: unit.id }
  refreshUnitOptions().catch(console.error)
}

async function applyImageChanges(productId: string) {
  if (!imageChanged.value) return

  if (imageRemoved.value && !imageFile.value) {
    await removeProductImage(productId, imageSavedUrl.value)
    await updateImage(productId, form.value, null)
    return
  }

  if (imageFile.value) {
    const url = await uploadProductImage(productId, imageFile.value)
    await updateImage(productId, form.value, url)
  }
}

async function save() {
  const validationKey = validateMasterProductForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.products.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    let productId = props.productId ?? null
    if (isEdit.value && productId) {
      await update(productId, form.value)
    } else {
      const row = await create(form.value)
      productId = row.id
    }

    if (productId) {
      await applyImageChanges(productId)
      await navigateTo(`/app/product/${productId}`)
    }
  } catch (e: unknown) {
    errorMsg.value = productSaveErrorMessage(e, t)
  } finally {
    saving.value = false
  }
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

    <form
      class="lg:grid lg:grid-cols-[minmax(0,1fr)_17rem] lg:items-start lg:gap-6"
      @submit.prevent="save"
    >
      <div class="min-w-0 space-y-6">
        <div>
          <h1 class="text-2xl font-bold font-heading">
            {{ pageTitle }}
          </h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ pageSubtitle }}
          </p>
        </div>

        <p
          v-if="errorMsg"
          :class="appFormErrorClass"
        >
          {{ errorMsg }}
        </p>

        <MasterDataProductForm
          v-model="form"
          :category-options="categoryOptions"
          :unit-options="unitOptions"
          @create-category="categoryFormOpen = true"
          @create-unit="unitFormOpen = true"
        >
          <template #gallery>
            <AppProductGalleryUpload :product-id="isEdit ? productId ?? null : null" />
          </template>
        </MasterDataProductForm>
      </div>

      <aside class="mt-6 space-y-4 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.products.actions') }}
          </p>
          <UButton
            type="button"
            block
            size="lg"
            icon="i-lucide-check"
            :loading="saving"
            @click="save"
          >
            {{ isEdit ? t('common.save') : t('masterData.products.create') }}
          </UButton>
          <UButton
            type="button"
            block
            class="mt-2"
            variant="outline"
            color="neutral"
            to="/app/product"
          >
            {{ t('common.cancel') }}
          </UButton>
        </UCard>

        <UCard class="rounded-2xl">
          <AppProductImageUpload
            :preview-url="imagePreviewUrl"
            @select="onImageSelect"
            @remove="onImageRemove"
          />
        </UCard>
      </aside>
    </form>

    <MasterDataCategoryFormModal
      v-model:open="categoryFormOpen"
      :parent-options="categoryParentOptions"
      @saved="onCategoryCreated"
    />

    <MasterDataUnitFormModal
      v-model:open="unitFormOpen"
      @saved="onUnitCreated"
    />
  </div>
</template>
