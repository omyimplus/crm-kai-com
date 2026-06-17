<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })
await navigateTo('/app/contact', { replace: true })
</script>

<template>
  <div />
</template>
