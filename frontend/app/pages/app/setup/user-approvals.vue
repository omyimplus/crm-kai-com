<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const { ensureProfile } = useProfile()
await ensureProfile()
</script>

<template>
  <SetupComingSoon menu-key="userApprovals" />
</template>
