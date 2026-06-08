<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
await navigateTo(`/app/master-data/roles/${route.params.id}`)
</script>
