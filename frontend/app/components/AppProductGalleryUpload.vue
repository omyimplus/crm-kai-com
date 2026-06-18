<script setup lang="ts">
import type { ProductGalleryImage } from '~/types/crm'
import { appFormErrorClass } from '~/config/appFormUi'

const props = withDefaults(defineProps<{
  productId?: string | null
  readonly?: boolean
}>(), {
  productId: null,
  readonly: false
})

const { t } = useI18n()
const {
  maxImages,
  validateGalleryFile,
  list,
  add,
  remove,
  reorder,
  galleryErrorMessage
} = useProductGallery()
const { getPreset } = useImageUpload()

const fileInputRef = ref<HTMLInputElement | null>(null)
const images = ref<ProductGalleryImage[]>([])
const loading = ref(false)
const uploading = ref(false)
const uploadingCurrent = ref(0)
const uploadingTotal = ref(0)
const reordering = ref(false)
const errorMsg = ref('')
const draggingId = ref<string | null>(null)
const dragOverId = ref<string | null>(null)
const dropZoneActive = ref(false)

const presetConfig = computed(() => getPreset('productImage'))
const canManage = computed(() => !!props.productId && !props.readonly)
const atLimit = computed(() => images.value.length >= maxImages)
const uploadProgressLabel = computed(() => {
  if (!uploading.value) return ''
  if (uploadingTotal.value > 1) {
    return t('masterData.products.gallery.uploadingProgress', {
      current: uploadingCurrent.value,
      total: uploadingTotal.value
    })
  }
  return t('masterData.products.gallery.uploading')
})

watch(
  () => props.productId,
  async (productId) => {
    if (!productId) {
      images.value = []
      return
    }
    loading.value = true
    errorMsg.value = ''
    try {
      images.value = await list(productId)
    } catch (e) {
      console.error(e)
      images.value = []
    } finally {
      loading.value = false
    }
  },
  { immediate: true }
)

function openPicker() {
  if (!canManage.value || atLimit.value || uploading.value) return
  errorMsg.value = ''
  fileInputRef.value?.click()
}

async function handleFiles(fileList: FileList | File[]) {
  if (!canManage.value || !props.productId) return

  errorMsg.value = ''
  const files = [...fileList]
  if (!files.length) return

  uploading.value = true
  uploadingCurrent.value = 0
  uploadingTotal.value = 0
  try {
    const validFiles: File[] = []
    for (const file of files) {
      if (images.value.length + validFiles.length >= maxImages) break

      const validationError = validateGalleryFile(file)
      if (validationError === 'tooLarge') {
        errorMsg.value = t('common.imageUpload.errors.tooLarge.productImage')
        continue
      }
      if (validationError === 'invalidType') {
        errorMsg.value = t('common.imageUpload.errors.invalidType.productImage')
        continue
      }

      validFiles.push(file)
    }

    uploadingTotal.value = validFiles.length

    for (const file of validFiles) {
      uploadingCurrent.value += 1
      const row = await add(props.productId, file)
      images.value = [...images.value, row]
    }
  } catch (e: unknown) {
    errorMsg.value = galleryErrorMessage(e, t)
  } finally {
    uploading.value = false
    uploadingCurrent.value = 0
    uploadingTotal.value = 0
  }
}

function onFileChange(event: Event) {
  const input = event.target as HTMLInputElement
  const files = input.files
  input.value = ''
  if (files?.length) {
    handleFiles(files)
  }
}

function onDropZoneDragOver(event: DragEvent) {
  if (!canManage.value || atLimit.value || uploading.value) return
  event.preventDefault()
  dropZoneActive.value = true
}

function onDropZoneDragLeave() {
  dropZoneActive.value = false
}

function onDropZoneDrop(event: DragEvent) {
  if (!canManage.value || atLimit.value || uploading.value) return
  event.preventDefault()
  dropZoneActive.value = false

  const files = event.dataTransfer?.files
  if (files?.length) {
    handleFiles(files)
  }
}

function onItemDragStart(imageId: string) {
  if (!canManage.value || reordering.value) return
  draggingId.value = imageId
}

function onItemDragOver(event: DragEvent, imageId: string) {
  if (!canManage.value || !draggingId.value || draggingId.value === imageId) return
  event.preventDefault()
  dragOverId.value = imageId
}

function onItemDragLeave() {
  dragOverId.value = null
}

async function onItemDrop(targetId: string) {
  if (!canManage.value || !props.productId || !draggingId.value || draggingId.value === targetId) {
    draggingId.value = null
    dragOverId.value = null
    return
  }

  const fromIndex = images.value.findIndex(image => image.id === draggingId.value)
  const toIndex = images.value.findIndex(image => image.id === targetId)
  draggingId.value = null
  dragOverId.value = null

  if (fromIndex < 0 || toIndex < 0 || fromIndex === toIndex) return

  const next = [...images.value]
  const [moved] = next.splice(fromIndex, 1)
  next.splice(toIndex, 0, moved)
  images.value = next

  reordering.value = true
  errorMsg.value = ''
  try {
    await reorder(props.productId, next.map(image => image.id))
  } catch (e: unknown) {
    errorMsg.value = galleryErrorMessage(e, t)
    images.value = await list(props.productId)
  } finally {
    reordering.value = false
  }
}

function onItemDragEnd() {
  draggingId.value = null
  dragOverId.value = null
}

async function removeImage(image: ProductGalleryImage) {
  if (!canManage.value || !props.productId || uploading.value) return

  errorMsg.value = ''
  try {
    await remove(props.productId, image.id, image.image_url)
    images.value = images.value.filter(row => row.id !== image.id)
  } catch (e: unknown) {
    errorMsg.value = galleryErrorMessage(e, t)
  }
}
</script>

<template>
  <div
    class="relative w-full rounded-2xl border border-gray-200 bg-white p-4 dark:border-gray-800 dark:bg-gray-900/40 sm:p-5"
  >
    <div
      v-if="uploading"
      class="absolute inset-0 z-10 flex flex-col items-center justify-center gap-2 rounded-2xl bg-white/80 px-4 backdrop-blur-[1px] dark:bg-gray-950/75"
      role="status"
      aria-live="polite"
    >
      <UIcon
        name="i-lucide-loader-circle"
        class="size-8 animate-spin text-primary"
      />
      <p class="text-sm font-medium text-gray-700 dark:text-gray-200">
        {{ uploadProgressLabel }}
      </p>
    </div>

    <div
      class="mb-4 flex flex-wrap items-start justify-between gap-3"
      :class="{ 'pointer-events-none opacity-60': uploading }"
    >
      <div>
        <p class="text-sm font-medium text-gray-900 dark:text-gray-100">
          {{ t('masterData.products.fields.gallery') }}
        </p>
        <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
          {{ t('masterData.products.fields.galleryHint') }}
        </p>
      </div>
      <p
        v-if="productId"
        class="text-xs text-gray-500 dark:text-gray-400"
      >
        {{ t('masterData.products.gallery.count', { count: images.length, max: maxImages }) }}
      </p>
    </div>

    <div :class="{ 'pointer-events-none opacity-60': uploading }">
      <p
        v-if="!productId && !readonly"
        class="rounded-xl border border-dashed border-gray-300 px-4 py-6 text-center text-sm text-gray-500 dark:border-gray-600 dark:text-gray-400"
      >
        {{ t('masterData.products.gallery.saveProductFirst') }}
      </p>

      <div
        v-else-if="canManage"
        class="rounded-xl border border-dashed px-4 py-6 transition-colors sm:px-6"
        :class="dropZoneActive
          ? 'border-primary bg-primary/5 dark:bg-primary/10'
          : 'border-gray-300 bg-gray-50/80 dark:border-gray-600 dark:bg-gray-800/40'"
        @dragover="onDropZoneDragOver"
        @dragleave="onDropZoneDragLeave"
        @drop="onDropZoneDrop"
      >
        <div class="flex flex-col items-center gap-4 sm:flex-row sm:justify-between">
          <div class="flex min-w-0 items-center gap-3 text-center sm:text-left">
            <div
              class="flex size-12 shrink-0 items-center justify-center rounded-xl border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900"
            >
              <UIcon
                name="i-lucide-images"
                class="size-6 text-gray-400"
              />
            </div>
            <div class="min-w-0">
              <p class="text-sm font-medium text-gray-700 dark:text-gray-200">
                {{ t('masterData.products.gallery.dropHint') }}
              </p>
              <p class="mt-0.5 text-xs text-gray-500 dark:text-gray-400">
                {{ t('masterData.products.fields.imageHint') }}
              </p>
            </div>
          </div>

          <UButton
            type="button"
            size="sm"
            variant="soft"
            color="primary"
            icon="i-lucide-upload"
            class="shrink-0"
            :disabled="atLimit || uploading"
            :loading="uploading"
            @click="openPicker"
          >
            {{ t('masterData.products.gallery.upload') }}
          </UButton>
        </div>

        <input
          ref="fileInputRef"
          type="file"
          class="hidden"
          multiple
          :accept="presetConfig.accept"
          @change="onFileChange"
        >
      </div>

      <p
        v-if="loading"
        class="mt-4 text-sm text-gray-500"
      >
        {{ t('common.loading') }}
      </p>

      <div
        v-else-if="images.length"
        class="mt-4 flex gap-3 overflow-x-auto pb-1"
      >
        <div
          v-for="image in images"
          :key="image.id"
          class="group relative size-24 shrink-0 overflow-hidden rounded-xl border bg-gray-50 dark:bg-gray-800/50 sm:size-28"
          :class="[
            dragOverId === image.id ? 'border-primary ring-2 ring-primary/30' : 'border-gray-200 dark:border-gray-700',
            draggingId === image.id ? 'opacity-60' : ''
          ]"
          :draggable="canManage && !reordering && !uploading"
          @dragstart="onItemDragStart(image.id)"
          @dragover="onItemDragOver($event, image.id)"
          @dragleave="onItemDragLeave"
          @drop.prevent="onItemDrop(image.id)"
          @dragend="onItemDragEnd"
        >
          <img
            :src="image.image_url"
            :alt="t('masterData.products.gallery.imageAlt')"
            class="h-full w-full object-cover"
          >

          <div
            v-if="canManage"
            class="absolute inset-x-0 top-0 flex items-start justify-between gap-1 bg-gradient-to-b from-black/45 to-transparent p-1.5 opacity-0 transition-opacity group-hover:opacity-100"
          >
            <span
              class="inline-flex items-center rounded-md bg-black/35 px-1 py-0.5 text-[10px] font-medium text-white"
            >
              <UIcon
                name="i-lucide-grip-vertical"
                class="size-3"
              />
            </span>
            <UButton
              type="button"
              size="xs"
              color="error"
              variant="solid"
              icon="i-lucide-trash-2"
              :aria-label="t('common.delete')"
              @click.stop="removeImage(image)"
            />
          </div>
        </div>
      </div>

      <p
        v-else-if="!images.length && !loading && !canManage"
        class="mt-4 text-sm text-gray-500"
      >
        {{ t('common.empty') }}
      </p>
    </div>

    <p
      v-if="errorMsg"
      class="mt-4"
      :class="appFormErrorClass"
    >
      {{ errorMsg }}
    </p>
  </div>
</template>
