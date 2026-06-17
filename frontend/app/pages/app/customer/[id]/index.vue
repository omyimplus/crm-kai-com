<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { ensureProfile } = useProfile()
await ensureProfile()

const customerId = computed(() => String(route.params.id))
</script>

<template>
  <MasterDataCustomerViewPage :customer-id="customerId" />
</template>
