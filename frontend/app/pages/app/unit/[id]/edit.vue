<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const unitId = computed(() => String(route.params.id))

const { ensureProfile } = useProfile()
await ensureProfile()
</script>

<template>
  <MasterDataUnitPage
    mode="edit"
    :unit-id="unitId"
  />
</template>
