<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

await navigateTo('/app/customer', { replace: true })
</script>

<template>
  <div />
</template>
