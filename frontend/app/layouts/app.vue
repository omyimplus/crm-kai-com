<script setup lang="ts">
const route = useRoute()
const { ensureProfile } = useProfile()
const { loadPermissions } = usePermissions()
const { startHeartbeat } = useLoginSession()

const profile = await ensureProfile()
if (profile) {
  await loadPermissions()
}

const isDashboardOpenLayout = computed(() => route.path === '/app' || route.path === '/app/')

let stopHeartbeat: (() => void) | undefined

onMounted(() => {
  stopHeartbeat = startHeartbeat()
})

onBeforeUnmount(() => {
  stopHeartbeat?.()
})
</script>

<template>
  <div class="crm-app flex h-dvh overflow-hidden bg-shell-bg">
    <AppSidebar />

    <div class="flex min-h-0 min-w-0 w-full flex-1 flex-col bg-shell-bg">
      <AppHeader />
      <main class="min-h-0 w-full flex-1 overflow-y-auto bg-shell-bg p-4 sm:p-6 lg:p-7">
        <div
          v-if="isDashboardOpenLayout"
          class="min-h-full"
        >
          <slot />
        </div>
        <div
          v-else
          class="min-h-full rounded-xl border border-shell-border bg-shell-card p-4 sm:p-6"
        >
          <slot />
        </div>
      </main>
    </div>
  </div>
</template>
