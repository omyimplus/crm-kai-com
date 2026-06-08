<script setup lang="ts">
const props = withDefaults(defineProps<{
  align?: 'left' | 'right' | 'center'
  class?: string
}>(), {
  align: 'left',
  class: ''
})
</script>

<template>
  <th
    class="bg-menu-section p-3 font-semibold font-heading text-white dark:bg-primary"
    :class="[
      {
        'text-left': props.align === 'left',
        'text-right': props.align === 'right',
        'text-center': props.align === 'center'
      },
      props.class
    ]"
  >
    <slot />
  </th>
</template>
