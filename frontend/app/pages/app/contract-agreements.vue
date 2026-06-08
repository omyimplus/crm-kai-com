<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })
await useProfile().ensureProfile()
</script>

<template>
  <AppMenuComingSoon menu-key="contractAgreements" />
</template>
