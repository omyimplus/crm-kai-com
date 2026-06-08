<script setup lang="ts">
const props = withDefaults(defineProps<{
  align?: 'left' | 'right' | 'center'
  muted?: boolean
  class?: string
}>(), {
  align: 'left',
  muted: false,
  class: ''
})
</script>

<template>
  <td
    class="p-3"
    :class="[
      props.align === 'right' ? 'text-right' : props.align === 'center' ? 'text-center' : 'text-left',
      props.muted && 'text-gray-600 dark:text-gray-400',
      props.class
    ]"
  >
    <slot />
  </td>
</template>
