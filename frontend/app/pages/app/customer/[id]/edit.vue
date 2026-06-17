<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { ensureProfile } = useProfile()
await ensureProfile()

const customerId = computed(() => String(route.params.id))
</script>

<template>
  <MasterDataCustomerPage
    mode="edit"
    :customer-id="customerId"
  />
</template>
