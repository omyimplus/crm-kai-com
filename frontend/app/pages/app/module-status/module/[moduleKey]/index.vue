<script setup lang="ts">
import { isModuleStatusModuleKey } from '~/utils/masterModuleStatus'

definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const moduleKey = String(route.params.moduleKey ?? '')

await navigateTo(
  isModuleStatusModuleKey(moduleKey)
    ? { path: '/app/module-status', query: { module: moduleKey }, replace: true }
    : { path: '/app/module-status', replace: true }
)
</script>
