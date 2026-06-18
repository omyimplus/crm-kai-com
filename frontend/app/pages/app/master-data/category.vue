<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })
await navigateTo('/app/category', { replace: true })
</script>
