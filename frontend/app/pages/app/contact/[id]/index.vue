<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { ensureProfile } = useProfile()
await ensureProfile()

const contactId = computed(() => String(route.params.id))
</script>

<template>
  <MasterDataContactViewPage :contact-id="contactId" />
</template>
