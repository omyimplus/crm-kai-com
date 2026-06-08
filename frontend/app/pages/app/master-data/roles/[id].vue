<script setup lang="ts">
const route = useRoute()
await navigateTo(`/app/setup/roles/${route.params.id}`, { redirectCode: 301 })
</script>
