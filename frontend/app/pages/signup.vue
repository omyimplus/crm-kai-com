<script setup lang="ts">
definePageMeta({ middleware: 'guest', layout: false })

const { t } = useI18n()
const supabase = useSupabaseClient()
const route = useRoute()
const email = ref('')
const password = ref('')
const fullName = ref('')
const loading = ref(false)
const errorMsg = ref('')
const successMsg = ref('')

const isComplete = computed(() => route.query.complete === '1')

const pageTitle = computed(() =>
  isComplete.value ? t('auth.completeProfileTitle') : t('auth.signupTitle')
)

async function signup() {
  loading.value = true
  errorMsg.value = ''
  successMsg.value = ''

  if (!isComplete.value) {
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
      await navigateTo('/app', { replace: true })
      return
    }
    errorMsg.value = rpcError.message
    return
  }

  loading.value = false
  await navigateTo('/app', { replace: true })
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
      <UFormField
        v-if="!isComplete"
        :label="t('auth.password')"
      >
        <UInput
          v-model="password"
          type="password"
          required
          minlength="6"
          size="lg"
          icon="i-lucide-lock"
          :placeholder="t('auth.passwordPlaceholder')"
        />
      </UFormField>
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
