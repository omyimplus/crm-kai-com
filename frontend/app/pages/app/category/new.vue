<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const { ensureProfile } = useProfile()
await ensureProfile()
</script>

<template>
  <MasterDataCategoryPage mode="new" />
</template>
