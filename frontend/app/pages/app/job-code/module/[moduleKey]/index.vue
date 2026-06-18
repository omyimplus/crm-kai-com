<script setup lang="ts">
import { isJobCodeModuleKey } from '~/utils/masterJobCode'

definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const moduleKey = String(route.params.moduleKey ?? '')

await navigateTo(
  isJobCodeModuleKey(moduleKey)
    ? { path: '/app/job-code', query: { module: moduleKey }, replace: true }
    : { path: '/app/job-code', replace: true }
)
</script>
