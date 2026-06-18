<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })
await navigateTo('/app/sales-team', { replace: true })
</script>
