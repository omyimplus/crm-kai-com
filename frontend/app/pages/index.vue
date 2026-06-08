<script setup lang="ts">
const user = await useAuthSession()
await navigateTo(user ? '/app' : '/login', { replace: true })
</script>

<template>
  <div />
</template>
