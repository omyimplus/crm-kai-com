<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const leadSourceId = computed(() => String(route.params.id))

const { ensureProfile } = useProfile()
await ensureProfile()
</script>

<template>
  <MasterDataLeadSourcePage
    mode="edit"
    :leadSource-id="leadSourceId"
  />
</template>
