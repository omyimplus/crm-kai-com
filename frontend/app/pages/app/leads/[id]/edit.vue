<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { ensureProfile } = useProfile()
await ensureProfile()

const leadId = computed(() => String(route.params.id ?? ''))
</script>

<template>
  <LeadsLeadPage
    mode="edit"
    :lead-id="leadId"
  />
</template>
