<script setup lang="ts">
definePageMeta({ middleware: 'guest', layout: false })

const { t } = useI18n()
const supabase = useSupabaseClient()
const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMsg = ref('')

async function login() {
  loading.value = true
  errorMsg.value = ''
  const { error } = await supabase.auth.signInWithPassword({
    email: email.value,
    password: password.value
  })
  loading.value = false
  if (error) {
    errorMsg.value = error.message
    return
  }
  await supabase.auth.getSession()
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
      <UFormField :label="t('auth.email')">
        <UInput
          v-model="email"
          type="email"
          required
          autocomplete="email"
          size="lg"
          icon="i-lucide-mail"
          :placeholder="t('auth.emailPlaceholder')"
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
