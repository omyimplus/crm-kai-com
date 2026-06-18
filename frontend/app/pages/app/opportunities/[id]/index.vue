<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })
</script>

<template>
  <OpportunitiesViewPage :opportunity-id="$route.params.id as string" />
</template>
