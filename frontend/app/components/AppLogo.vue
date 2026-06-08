<script setup lang="ts">
type LogoVariant = 'full' | 'icon'
type LogoSize = 'sm' | 'md' | 'lg'

const props = withDefaults(defineProps<{
  variant?: LogoVariant
  size?: LogoSize
}>(), {
  variant: 'full',
  size: 'md'
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
  <img
    :src="src"
    :alt="t('common.appName')"
    class="object-contain object-left"
    :class="sizeClass"
    decoding="async"
  >
</template>
