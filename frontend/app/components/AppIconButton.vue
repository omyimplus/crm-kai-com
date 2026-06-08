<script setup lang="ts">
import type { RouteLocationRaw } from 'vue-router'

withDefaults(defineProps<{
  icon: string
  ariaLabel: string
  color?: 'neutral' | 'primary' | 'error' | 'success' | 'warning'
  size?: 'xs' | 'sm' | 'md'
  to?: RouteLocationRaw
  variant?: 'soft' | 'outline'
}>(), {
  color: 'neutral',
  size: 'xs',
  variant: 'soft'
})

defineEmits<{
  click: [event: MouseEvent]
}>()
</script>

<template>
  <UButton
    :to="to"
    :size="size"
    :variant="variant"
    :color="color"
    :icon="icon"
    :aria-label="ariaLabel"
    square
    class="rounded-lg"
    @click="$emit('click', $event)"
  />
</template>
