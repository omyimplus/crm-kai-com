<script setup lang="ts">
import { validatePasswordPair } from '~/utils/password'

definePageMeta({ middleware: 'guest', layout: false })

const { t } = useI18n()
const supabase = useSupabaseClient()
const { recordLogin } = useLoginSession()
const route = useRoute()

const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const fullName = ref('')
const loading = ref(false)
const errorMsg = ref('')
const successMsg = ref('')

const isComplete = computed(() => route.query.complete === '1')

const pageTitle = computed(() =>
  isComplete.value ? t('auth.completeProfileTitle') : t('auth.signupTitle')
)

function passwordErrorMessage(): string | null {
  const err = validatePasswordPair(password.value, confirmPassword.value)
  if (!err) return null
  if (err === 'mismatch') return t('auth.passwordMismatch')
  if (err === 'tooShort') {
    return t('auth.passwordTooShort', { min: 6 })
  }
  return t('auth.passwordRequired')
}

async function signup() {
  loading.value = true
  errorMsg.value = ''
  successMsg.value = ''

  if (!isComplete.value) {
    const passwordError = passwordErrorMessage()
    if (passwordError) {
      loading.value = false
      errorMsg.value = passwordError
      return
    }
    const { data, error } = await supabase.auth.signUp({
      email: email.value,
      password: password.value
    })
    if (error) {
      loading.value = false
      errorMsg.value = error.message
      return
    }

    if (data.user?.identities?.length === 0) {
      loading.value = false
      errorMsg.value = t('auth.emailAlreadyRegistered')
      return
    }

    let session = data.session

    // signUp บางครั้งไม่คืน session แม้ปิด confirm email — ลอง sign in ต่อทันที
    if (!session) {
      const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
        email: email.value,
        password: password.value
      })
      if (signInError) {
        loading.value = false
        successMsg.value = t('auth.confirmEmailHint')
        return
      }
      session = signInData.session
    }

    if (session) {
      await supabase.auth.setSession({
        access_token: session.access_token,
        refresh_token: session.refresh_token
      })
    }
  }

  const { data: { session: activeSession } } = await supabase.auth.getSession()
  if (!activeSession) {
    loading.value = false
    errorMsg.value = t('auth.loginRequiredForProfile')
    return
  }

  const { error: rpcError } = await supabase.rpc('signup_profile', {
    p_full_name: fullName.value
  })

  if (rpcError) {
    loading.value = false
    if (rpcError.message.includes('Profile already exists')) {
      const { fetchProfile } = useProfile()
      const existing = await fetchProfile()
      await navigateTo(existing?.is_active ? '/app' : '/app/pending', { replace: true })
      return
    }
    errorMsg.value = rpcError.message
    return
  }

  loading.value = false
  const { fetchProfile } = useProfile()
  const created = await fetchProfile()
  if (created?.is_active) {
    await recordLogin()
  }
  await navigateTo(created?.is_active ? '/app' : '/app/pending', { replace: true })
}
</script>

<template>
  <AuthShell
    :title="pageTitle"
    :subtitle="t('auth.signupSubtitle')"
  >
    <form
      class="space-y-5"
      @submit.prevent="signup"
    >
      <UFormField
        v-if="!isComplete"
        :label="t('auth.email')"
      >
        <UInput
          v-model="email"
          type="email"
          required
          size="lg"
          icon="i-lucide-mail"
          :placeholder="t('auth.emailPlaceholder')"
        />
      </UFormField>
      <AppPasswordFieldGroup
        v-if="!isComplete"
        v-model:password="password"
        v-model:confirm-password="confirmPassword"
      />
      <UFormField :label="t('auth.fullName')">
        <UInput
          v-model="fullName"
          required
          size="lg"
          icon="i-lucide-user"
          :placeholder="t('auth.fullNamePlaceholder')"
        />
      </UFormField>
      <UAlert
        v-if="successMsg"
        color="success"
        variant="subtle"
        icon="i-lucide-mail-check"
        :title="successMsg"
      />
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
        {{ isComplete ? t('auth.saveProfile') : t('auth.createAccount') }}
      </UButton>
    </form>

    <template #footer>
      <NuxtLink
        to="/login"
        class="text-primary font-medium hover:underline"
      >
        {{ t('auth.backToLogin') }}
      </NuxtLink>
    </template>
  </AuthShell>
</template>
