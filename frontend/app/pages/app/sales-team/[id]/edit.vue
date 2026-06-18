<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { ensureProfile } = useProfile()
await ensureProfile()

const teamId = computed(() => String(route.params.id))
</script>

<template>
  <MasterDataSalesTeamPage
    mode="edit"
    :team-id="teamId"
  />
</template>
