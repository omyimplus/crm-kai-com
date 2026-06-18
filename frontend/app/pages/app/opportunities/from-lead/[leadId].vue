<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })
</script>

<template>
  <OpportunitiesOpportunityPage mode="from-lead" :lead-id="$route.params.leadId as string" />
</template>
