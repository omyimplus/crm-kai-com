<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { ensureProfile } = useProfile()
await ensureProfile()

const leadId = computed(() => String(route.params.id ?? ''))
</script>

<template>
  <LeadsLeadViewPage :lead-id="leadId" />
</template>
