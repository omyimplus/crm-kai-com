<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })
</script>

<template>
  <OpportunitiesOpportunityPage
    mode="edit"
    :opportunity-id="$route.params.id as string"
  />
</template>
