<script setup lang="ts">
import type { ImageUploadPresetId } from '~/config/imageUpload'

const props = withDefaults(defineProps<{
  preset: ImageUploadPresetId
  previewUrl?: string | null
  label: string
  hint?: string
  disabled?: boolean
}>(), {
  previewUrl: null,
  hint: '',
  disabled: false
})

const emit = defineEmits<{
  select: [file: File]
  remove: []
}>()

const { t } = useI18n()
const { validate, hasCustomImage, getPreset } = useImageUpload()

const fileInputRef = ref<HTMLInputElement | null>(null)
const localError = ref('')

const presetConfig = computed(() => getPreset(props.preset))
const hasUpload = computed(() => hasCustomImage(props.previewUrl))

function openPicker() {
  if (props.disabled) return
  localError.value = ''
  fileInputRef.value?.click()
}

function onFileChange(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  input.value = ''
  if (!file) return

  const err = validate(file, props.preset)
  if (err === 'tooLarge') {
    localError.value = t(`common.imageUpload.errors.tooLarge.${props.preset}`)
    return
  }
  if (err === 'invalidType') {
    localError.value = t(`common.imageUpload.errors.invalidType.${props.preset}`)
    return
  }

  localError.value = ''
  emit('select', file)
}

function removeImage() {
  if (props.disabled) return
  localError.value = ''
  emit('remove')
}
</script>

<template>
  <div class="flex flex-col items-center gap-3 sm:flex-row sm:items-start">
    <slot
      name="preview"
      :preview-url="previewUrl"
      :has-upload="hasUpload"
    />

    <div class="flex min-w-0 flex-1 flex-col gap-2">
      <p class="text-sm font-medium text-gray-900 dark:text-gray-100">
        {{ label }}
      </p>

      <div class="flex flex-wrap gap-2">
        <UButton
          type="button"
          size="sm"
          variant="soft"
          color="primary"
          class="rounded-lg"
          icon="i-lucide-upload"
          :disabled="disabled"
          @click="openPicker"
        >
          {{ hasUpload ? t('common.imageUpload.change') : t('common.imageUpload.upload') }}
        </UButton>
        <UButton
          v-if="hasUpload"
          type="button"
          size="sm"
          variant="outline"
          color="neutral"
          class="rounded-lg"
          :disabled="disabled"
          @click="removeImage"
        >
          {{ t('common.imageUpload.remove') }}
        </UButton>
      </div>

      <p
        v-if="hint"
        class="text-xs text-gray-500 dark:text-gray-400"
      >
        {{ hint }}
      </p>

      <p
        v-if="localError"
        class="text-xs text-red-600 dark:text-red-400"
      >
        {{ localError }}
      </p>

      <input
        ref="fileInputRef"
        type="file"
        class="hidden"
        :accept="presetConfig.accept"
        :disabled="disabled"
        @change="onFileChange"
      >
    </div>
  </div>
</template>
