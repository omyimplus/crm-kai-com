<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { ensureProfile } = useProfile()
await ensureProfile()

const targetId = computed(() => String(route.params.id))
</script>

<template>
  <MasterDataSalesTargetViewPage :target-id="targetId" />
</template>
