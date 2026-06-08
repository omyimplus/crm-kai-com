<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

await navigateTo('/app/setup/system-users', { replace: true })
</script>
