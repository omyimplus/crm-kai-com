<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const partnerId = computed(() => String(route.params.id))

const { ensureProfile } = useProfile()
await ensureProfile()
</script>

<template>
  <MasterDataPartnerViewPage :partner-id="partnerId" />
</template>
