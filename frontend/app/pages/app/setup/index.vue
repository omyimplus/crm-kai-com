<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

await navigateTo('/app', { replace: true })
</script>

<template>
  <div />
</template>
