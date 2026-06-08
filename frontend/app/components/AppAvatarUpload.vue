<script setup lang="ts">
const props = withDefaults(defineProps<{
  previewUrl?: string | null
  displayName?: string
  disabled?: boolean
}>(), {
  previewUrl: null,
  displayName: '',
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
    preset="avatar"
    :preview-url="previewUrl"
    :label="t('setup.systemUsers.avatar')"
    :hint="t('setup.systemUsers.avatarHint')"
    :disabled="disabled"
    @select="emit('select', $event)"
    @remove="emit('remove')"
  >
    <template #preview>
      <AppUserAvatar
        :src="previewUrl"
        :alt="displayName"
        size="xl"
      />
    </template>
  </AppImageUpload>
</template>
