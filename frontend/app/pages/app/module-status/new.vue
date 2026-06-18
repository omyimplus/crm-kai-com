<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })
await navigateTo('/app/module-status', { replace: true })
</script>
