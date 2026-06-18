<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { ensureProfile } = useProfile()
await ensureProfile()

const categoryId = computed(() => String(route.params.id))
</script>

<template>
  <MasterDataCategoryViewPage :category-id="categoryId" />
</template>
