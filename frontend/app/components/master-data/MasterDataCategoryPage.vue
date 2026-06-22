<script setup lang="ts">
import type { Category } from '~/types/crm'
import { appFormErrorClass } from '~/config/appFormUi'
import {
  categoryDisplayLabel,
  categorySaveErrorMessage,
  categoryToFormInput,
  defaultMasterCategoryFormInput,
  parentCategoryOptions,
  validateMasterCategoryForm
} from '~/utils/masterCategory'
import {
  CATEGORY_MODULE_KEY,
  SERVICE_CATEGORY_MODULE_KEY,
  type CategoryModuleKey
} from '~/config/masterCategory'

const props = defineProps<{
  mode: 'new' | 'edit'
  categoryId?: string | null
  parentId?: string | null
}>()

const { t } = useI18n()
const route = useRoute()
const { list, get, create, update, updateImage } = useCategories()
const { uploadCategoryImage, removeCategoryImage } = useCategoryImage()
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
const form = ref(defaultMasterCategoryFormInput())
const categoryRows = ref<Category[]>([])
const allCategories = ref<{ label: string, value: string }[]>([])

const isEdit = computed(() => props.mode === 'edit')

const parentId = computed(() => {
  if (props.parentId) return props.parentId
  const query = route.query.parentId
  return typeof query === 'string' && query.trim() ? query.trim() : null
})

const moduleKey = computed((): CategoryModuleKey => {
  const query = route.query.moduleKey
  if (query === SERVICE_CATEGORY_MODULE_KEY) return SERVICE_CATEGORY_MODULE_KEY
  if (props.parentId || parentId.value) {
    const parent = categoryRows.value.find(row => row.id === (props.parentId ?? parentId.value))
    if (parent?.module_key === SERVICE_CATEGORY_MODULE_KEY) return SERVICE_CATEGORY_MODULE_KEY
  }
  return CATEGORY_MODULE_KEY
})

const parentCategory = computed(() =>
  parentId.value
    ? categoryRows.value.find(row => row.id === parentId.value) ?? null
    : null
)

const pageTitle = computed(() =>
  isEdit.value ? t('masterData.category.editTitle') : t('masterData.category.newTitle')
)
const pageSubtitle = computed(() => {
  if (isEdit.value) return t('masterData.category.editSubtitle')
  if (parentCategory.value) {
    return t('masterData.category.newUnderParentSubtitle', {
      parent: categoryDisplayLabel(parentCategory.value)
    })
  }
  return t('masterData.category.newSubtitle')
})

try {
  const rows = await list(moduleKey.value)
  categoryRows.value = rows
  allCategories.value = parentCategoryOptions(rows, props.categoryId)
  if (!isEdit.value) {
    form.value = {
      ...defaultMasterCategoryFormInput(moduleKey.value),
      parent_id: parentId.value
    }
  }
} catch (e) {
  console.error(e)
}

if (isEdit.value && props.categoryId) {
  try {
    const row = await get(props.categoryId)
    form.value = categoryToFormInput(row)
    resetImageState(row.image_url)
  } catch (e) {
    console.error(e)
    await navigateTo('/app/category')
  }
}

async function applyImageChanges(categoryId: string) {
  if (!imageChanged.value) return

  if (imageRemoved.value && !imageFile.value) {
    await removeCategoryImage(categoryId, imageSavedUrl.value)
    await updateImage(categoryId, form.value, null)
    return
  }

  if (imageFile.value) {
    const url = await uploadCategoryImage(categoryId, imageFile.value)
    await updateImage(categoryId, form.value, url)
  }
}

async function save() {
  const validationKey = validateMasterCategoryForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.category.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    let categoryId = props.categoryId ?? null
    if (isEdit.value && categoryId) {
      await update(categoryId, form.value)
    } else {
      const row = await create(form.value)
      categoryId = row.id
    }

    if (categoryId) {
      await applyImageChanges(categoryId)
      await navigateTo(`/app/category/${categoryId}`)
    }
  } catch (e: unknown) {
    errorMsg.value = categorySaveErrorMessage(e, t)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div>
    <UButton
      to="/app/category"
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

        <MasterDataCategoryForm
          v-model="form"
          :parent-options="allCategories"
        />
      </div>

      <aside class="mt-6 space-y-4 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <AppCategoryImageUpload
            :preview-url="imagePreviewUrl"
            @select="onImageSelect"
            @remove="onImageRemove"
          />
        </UCard>

        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.category.actions') }}
          </p>
          <UButton
            type="button"
            block
            size="lg"
            icon="i-lucide-check"
            :loading="saving"
            @click="save"
          >
            {{ isEdit ? t('common.save') : t('masterData.category.create') }}
          </UButton>
          <UButton
            type="button"
            block
            class="mt-2"
            variant="outline"
            color="neutral"
            to="/app/category"
          >
            {{ t('common.cancel') }}
          </UButton>
        </UCard>
      </aside>
    </form>
  </div>
</template>
