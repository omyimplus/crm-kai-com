<script setup lang="ts">
import type { ModuleStatusModuleKey } from '~/config/masterModuleStatus'
import { isModuleStatusModuleKey } from '~/utils/masterModuleStatus'

definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { ensureProfile } = useProfile()

const moduleKey = computed(() => String(route.params.moduleKey ?? ''))

if (!isModuleStatusModuleKey(moduleKey.value)) {
  await navigateTo('/app/module-status', { replace: true })
}

await ensureProfile()

const lockedModuleKey = moduleKey as ComputedRef<ModuleStatusModuleKey>
</script>

<template>
  <MasterDataModuleStatusPage
    mode="new"
    :initial-module-key="lockedModuleKey"
  />
</template>
