<script setup lang="ts">
const { ensureProfile } = useProfile()
const { loadPermissions } = usePermissions()
const { startHeartbeat } = useLoginSession()

const profile = await ensureProfile()
if (profile) {
  await loadPermissions()
}

let stopHeartbeat: (() => void) | undefined

onMounted(() => {
  stopHeartbeat = startHeartbeat()
})

onBeforeUnmount(() => {
  stopHeartbeat?.()
})
</script>

<template>
  <div class="crm-app flex h-dvh overflow-hidden bg-gray-50 dark:bg-gray-950">
    <AppSidebar />

    <div class="flex min-h-0 min-w-0 flex-1 flex-col bg-gray-50 dark:bg-gray-950">
      <AppHeader />
      <main class="min-h-0 w-full flex-1 overflow-y-auto bg-gray-50 p-4 sm:p-6 dark:bg-gray-950">
        <div
          class="min-h-full rounded-xl border border-gray-200 bg-white p-4 sm:p-6 dark:border-gray-800 dark:bg-gray-900"
        >
          <slot />
        </div>
      </main>
    </div>
  </div>
</template>
