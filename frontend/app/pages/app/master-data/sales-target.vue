<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })
await navigateTo('/app/sales-target', { replace: true })
</script>

<template>
  <div />
</template>
