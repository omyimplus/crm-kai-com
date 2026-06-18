<script setup lang="ts">
import {
  categoryDisplayLabel,
  categoryToFormInput,
  parentCategoryOptions
} from '~/utils/masterCategory'

const props = defineProps<{
  categoryId: string
}>()

const { t } = useI18n()
const { list, get } = useCategories()
const { hasCustomImage } = useImageUpload()

const loading = ref(true)
const imageUrl = ref<string | null>(null)
const form = ref(categoryToFormInput({
  id: '',
  org_id: '',
  module_key: 'product',
  category_code: '',
  name: '',
  description: null,
  parent_id: null,
  sort_order: 0,
  color: null,
  status: 'active',
  notes: null,
  image_url: null,
  created_at: ''
}))
const parentOptions = ref<{ label: string, value: string }[]>([])
const deleteOpen = ref(false)

const hasImage = computed(() => hasCustomImage(imageUrl.value))

try {
  const [row, rows] = await Promise.all([
    get(props.categoryId),
    list()
  ])
  form.value = categoryToFormInput(row)
  imageUrl.value = row.image_url
  parentOptions.value = parentCategoryOptions(rows, props.categoryId)
} catch (e) {
  console.error(e)
  await navigateTo('/app/category')
} finally {
  loading.value = false
}

function onDeleted() {
  navigateTo('/app/category')
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
          <h1 class="text-2xl font-bold font-heading">
            {{ categoryDisplayLabel(form) }}
          </h1>
          <span
            v-if="form.color"
            class="inline-block size-4 rounded-full border border-gray-200 dark:border-gray-700"
            :style="{ backgroundColor: form.color }"
          />
        </div>
        <p class="text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.category.viewSubtitle') }}
        </p>

        <MasterDataCategoryForm
          v-model="form"
          :parent-options="parentOptions"
          readonly
        />
      </div>

      <aside class="mt-6 space-y-4 lg:sticky lg:top-6 lg:mt-0">
        <UCard
          v-if="hasImage"
          class="rounded-2xl"
        >
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.category.fields.image') }}
          </p>
          <div class="overflow-hidden rounded-xl border border-gray-200 dark:border-gray-700">
            <img
              :src="imageUrl!"
              :alt="form.name"
              class="aspect-square w-full object-cover"
            >
          </div>
        </UCard>

        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.category.actions') }}
          </p>
          <UButton
            block
            size="lg"
            icon="i-lucide-pencil"
            :to="`/app/category/${categoryId}/edit`"
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
      </aside>
    </div>

    <MasterDataCategoryDeleteModal
      v-model:open="deleteOpen"
      :category-id="categoryId"
      :category-name="categoryDisplayLabel(form)"
      :image-url="imageUrl"
      @deleted="onDeleted"
    />
  </div>
</template>
