<script setup lang="ts">
const props = withDefaults(defineProps<{
  previewUrl?: string | null
  disabled?: boolean
}>(), {
  previewUrl: null,
  disabled: false
})

const emit = defineEmits<{
  select: [file: File]
  remove: []
}>()

const { t } = useI18n()
</script>

<template>
  <AppImageUpload
    preset="categoryImage"
    :preview-url="previewUrl"
    :label="t('masterData.category.fields.image')"
    :hint="t('masterData.category.fields.imageHint')"
    :disabled="disabled"
    @select="emit('select', $event)"
    @remove="emit('remove')"
  >
    <template #preview="{ previewUrl: imagePreview, hasUpload }">
      <div
        class="flex size-24 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-dashed border-gray-300 bg-gray-50 dark:border-gray-600 dark:bg-gray-800/50"
      >
        <img
          v-if="hasUpload && imagePreview"
          :src="imagePreview"
          alt=""
          class="h-full w-full object-cover"
        >
        <UIcon
          v-else
          name="i-lucide-tags"
          class="size-9 text-gray-400"
        />
      </div>
    </template>
  </AppImageUpload>
</template>
