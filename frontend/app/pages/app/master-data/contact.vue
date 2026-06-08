<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })
const { ensureProfile } = useProfile()
await ensureProfile()
</script>

<template>
  <MasterDataComingSoon menu-key="contact" />
</template>
