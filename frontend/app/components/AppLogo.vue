<script setup lang="ts">
type LogoVariant = 'full' | 'icon'
type LogoSize = 'sm' | 'md' | 'lg'

const props = withDefaults(defineProps<{
  variant?: LogoVariant
  size?: LogoSize
  /** กล่องขาวมุมโค้งแบบ demo (sidebar / auth) */
  framed?: boolean
}>(), {
  variant: 'full',
  size: 'md',
  framed: false
})

const { t } = useI18n()

const src = computed(() =>
  props.variant === 'icon'
    ? '/images/logo/logo-kai-com-crm-icon.webp'
    : '/images/logo/logo-kai-com-crm.webp'
)

const sizeClass = computed(() => {
  if (props.variant === 'icon') {
    return {
      sm: 'h-8 w-8',
      md: 'h-9 w-9',
      lg: 'h-10 w-10'
    }[props.size]
  }
  return {
    sm: 'h-8 w-auto max-w-full',
    md: 'h-10 w-auto max-w-full',
    lg: 'h-11 w-auto max-w-full'
  }[props.size]
})
</script>

<template>
  <div
    v-if="framed && variant === 'full'"
    class="flex h-14 w-40 max-w-full items-center rounded-2xl bg-white p-2 shadow-sm ring-1 ring-gray-200 dark:bg-gray-950 dark:ring-gray-700"
  >
    <img
      :src="src"
      :alt="t('common.appName')"
      class="h-full w-full object-contain object-left"
      decoding="async"
    >
  </div>
  <img
    v-else
    :src="src"
    :alt="t('common.appName')"
    class="object-contain object-left"
    :class="sizeClass"
    decoding="async"
  >
</template>
