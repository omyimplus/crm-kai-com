<script setup lang="ts">
definePageMeta({ middleware: 'guest', layout: false })

const { t } = useI18n()
const supabase = useSupabaseClient()
const { recordLogin } = useLoginSession()
const identifier = ref('')
const password = ref('')
const loading = ref(false)
const errorMsg = ref('')

async function resolveLoginEmail(value: string): Promise<string | null> {
  const trimmed = value.trim()
  if (!trimmed) {
    return null
  }

  if (trimmed.includes('@')) {
    return trimmed
  }

  const { data, error } = await supabase.rpc('resolve_login_email', {
    p_identifier: trimmed
  })

  if (error || !data) {
    return null
  }

  return data as string
}

async function login() {
  loading.value = true
  errorMsg.value = ''

  const loginEmail = await resolveLoginEmail(identifier.value)
  if (!loginEmail) {
    loading.value = false
    errorMsg.value = t('auth.invalidCredentials')
    return
  }

  const { error } = await supabase.auth.signInWithPassword({
    email: loginEmail,
    password: password.value
  })
  loading.value = false
  if (error) {
    errorMsg.value = error.message === 'Invalid login credentials'
      ? t('auth.invalidCredentials')
      : error.message
    return
  }
  await supabase.auth.getSession()
  await recordLogin()
  await navigateTo('/app', { replace: true })
}
</script>

<template>
  <AuthShell
    :title="t('auth.loginTitle')"
    :subtitle="t('auth.loginSubtitle')"
  >
    <form
      class="space-y-5"
      @submit.prevent="login"
    >
      <UFormField :label="t('auth.loginIdentifier')">
        <UInput
          v-model="identifier"
          type="text"
          required
          autocomplete="username"
          size="lg"
          icon="i-lucide-user"
          :placeholder="t('auth.loginIdentifierPlaceholder')"
        />
      </UFormField>
      <UFormField :label="t('auth.password')">
        <UInput
          v-model="password"
          type="password"
          required
          autocomplete="current-password"
          size="lg"
          icon="i-lucide-lock"
          :placeholder="t('auth.passwordPlaceholder')"
        />
      </UFormField>
      <UAlert
        v-if="errorMsg"
        color="error"
        variant="subtle"
        icon="i-lucide-circle-alert"
        :title="errorMsg"
      />
      <UButton
        type="submit"
        block
        size="lg"
        :loading="loading"
        class="font-medium"
      >
        {{ t('auth.login') }}
      </UButton>
    </form>

    <template #footer>
      {{ t('auth.noAccount') }}
      <NuxtLink
        to="/signup"
        class="text-primary font-medium hover:underline"
      >
        {{ t('auth.signup') }}
      </NuxtLink>
    </template>
  </AuthShell>
</template>
