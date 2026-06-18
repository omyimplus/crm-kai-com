<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const { ensureProfile } = useProfile()
await ensureProfile()
</script>

<template>
  <MasterDataUnitPage mode="new" />
</template>
