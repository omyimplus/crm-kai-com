<script setup lang="ts">
import { appShellCardClass } from '~/config/appShellTheme'

defineProps<{
  class?: string
}>()
</script>

<template>
  <section
    :class="[appShellCardClass, $props.class]"
  >
    <slot />
  </section>
</template>
