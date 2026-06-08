<script setup lang="ts">
import { DEFAULT_USER_AVATAR } from '~/config/userAvatar'

type AvatarSize = 'sm' | 'md' | 'lg' | 'xl'

const props = withDefaults(defineProps<{
  src?: string | null
  alt?: string
  size?: AvatarSize
}>(), {
  src: null,
  alt: '',
  size: 'md'
})

const { t } = useI18n()

const imageSrc = computed(() => props.src?.trim() || DEFAULT_USER_AVATAR)
const isDefault = computed(() => !props.src?.trim())
const altText = computed(() => props.alt || t('common.user'))

const sizeClass: Record<AvatarSize, string> = {
  sm: 'h-8 w-8',
  md: 'h-10 w-10',
  lg: 'h-16 w-16',
  xl: 'h-24 w-24'
}
</script>

<template>
  <div
    class="inline-flex shrink-0 overflow-hidden rounded-full ring-2 ring-green-500/20"
    :class="[
      sizeClass[size],
      isDefault ? 'bg-green-50 dark:bg-green-950/40' : 'bg-gray-100 dark:bg-gray-800'
    ]"
  >
    <img
      :src="imageSrc"
      :alt="altText"
      class="h-full w-full"
      :class="isDefault ? 'object-contain p-1.5' : 'object-cover'"
      decoding="async"
    >
  </div>
</template>
