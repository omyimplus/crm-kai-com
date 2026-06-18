<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { ensureProfile } = useProfile()
await ensureProfile()

const categoryId = computed(() => String(route.params.id))
</script>

<template>
  <MasterDataCategoryPage
    mode="edit"
    :category-id="categoryId"
  />
</template>
