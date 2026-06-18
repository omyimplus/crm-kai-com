<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { ensureProfile } = useProfile()
await ensureProfile()

const productId = computed(() => String(route.params.id))
</script>

<template>
  <MasterDataProductPage
    mode="edit"
    :product-id="productId"
  />
</template>
