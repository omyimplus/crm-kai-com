<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })
await navigateTo('/app/unit', { replace: true })
</script>
