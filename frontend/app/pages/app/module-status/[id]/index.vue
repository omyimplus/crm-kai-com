<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { ensureProfile } = useProfile()
await ensureProfile()

const moduleStatusId = computed(() => String(route.params.id))
</script>

<template>
  <MasterDataModuleStatusViewPage :module-status-id="moduleStatusId" />
</template>
