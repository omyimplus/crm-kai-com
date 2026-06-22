<script setup lang="ts">
defineProps<{
  class?: string
}>()
</script>

<template>
  <section
    :class="[
      'rounded-3xl border border-border bg-white shadow-sm shadow-slate-200/70',
      $props.class,
    ]"
  >
    <slot />
  </section>
</template>
