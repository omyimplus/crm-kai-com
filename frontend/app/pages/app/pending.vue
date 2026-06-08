<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: false })

const { t } = useI18n()
const supabase = useSupabaseClient()
const { fetchProfile, profile } = useProfile()

await fetchProfile()

if (profile.value?.is_active) {
  await navigateTo('/app', { replace: true })
}

async function logout() {
  await supabase.auth.signOut()
  await navigateTo('/login', { replace: true })
}
</script>

<template>
  <AuthShell
    :title="t('auth.pendingTitle')"
    :subtitle="t('auth.pendingSubtitle')"
  >
    <div class="space-y-5">
      <div class="rounded-xl border border-amber-200 bg-amber-50 px-4 py-4 dark:border-amber-900/50 dark:bg-amber-950/40">
        <div class="flex gap-3">
          <UIcon
            name="i-lucide-clock"
            class="mt-0.5 size-5 shrink-0 text-amber-700 dark:text-amber-300"
          />
          <p class="text-sm leading-relaxed text-amber-900 dark:text-amber-100">
            {{ t('auth.pendingMessage') }}
          </p>
        </div>
      </div>

      <ul class="space-y-2 text-sm text-gray-600 dark:text-gray-400">
        <li class="flex items-start gap-2">
          <span class="mt-0.5 flex size-5 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">1</span>
          <span>{{ t('auth.pendingSteps.wait') }}</span>
        </li>
        <li class="flex items-start gap-2">
          <span class="mt-0.5 flex size-5 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">2</span>
          <span>{{ t('auth.pendingSteps.approve') }}</span>
        </li>
        <li class="flex items-start gap-2">
          <span class="mt-0.5 flex size-5 shrink-0 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">3</span>
          <span>{{ t('auth.pendingSteps.login') }}</span>
        </li>
      </ul>

      <UButton
        block
        variant="outline"
        color="neutral"
        size="lg"
        icon="i-lucide-log-out"
        @click="logout"
      >
        {{ t('auth.logout') }}
      </UButton>
    </div>
  </AuthShell>
</template>
