<script setup lang="ts">
import type { OrgAuthProviderId, OrgAuthProviders } from '~/config/orgAuthProviders'
import { isOAuthProvider } from '~/config/orgAuthProviders'
import {
  appFormErrorClass,
  appFormFieldClass,
  appFormHintClass,
  appInputUi,
  appTextareaUi
} from '~/config/appFormUi'
import {
  oauthSettingsToForm,
  trimOAuthForm
} from '~/utils/orgAuthProviders'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  providerId: OrgAuthProviderId | null
  providers: OrgAuthProviders
}>()

const emit = defineEmits<{ saved: [] }>()

const { t } = useI18n()
const { update } = useOrgAuthProviders()

const saving = ref(false)
const errorMsg = ref('')

const form = ref(oauthSettingsToForm({
  enabled: false,
  clientId: '',
  tenantId: '',
  allowedDomains: '',
  hasClientSecret: false
}))

const isOAuth = computed(() =>
  props.providerId ? isOAuthProvider(props.providerId) : false
)

const showTenantId = computed(() =>
  props.providerId === 'microsoft365' || props.providerId === 'azureAd'
)

const modalTitle = computed(() =>
  props.providerId
    ? t(`setup.settings.authProviders.providers.${props.providerId}.configureTitle`)
    : ''
)

watch(open, (isOpen) => {
  if (!isOpen || !props.providerId) return
  if (isOAuthProvider(props.providerId)) {
    form.value = oauthSettingsToForm(props.providers[props.providerId])
  }
  errorMsg.value = ''
})

async function save() {
  if (!props.providerId || !isOAuthProvider(props.providerId)) return

  saving.value = true
  errorMsg.value = ''
  try {
    const payload = trimOAuthForm(form.value)
    if (!payload.clientId) {
      errorMsg.value = t('setup.settings.authProviders.errors.clientId')
      return
    }
    if (!payload.clientSecret && !props.providers[props.providerId].hasClientSecret) {
      errorMsg.value = t('setup.settings.authProviders.errors.clientSecret')
      return
    }

    await update(props.providers, props.providerId, {
      enabled: props.providers[props.providerId].enabled,
      clientId: payload.clientId,
      clientSecret: payload.clientSecret || '__keep__',
      tenantId: payload.tenantId,
      allowedDomains: payload.allowedDomains
    })
    open.value = false
    emit('saved')
  } catch (e) {
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="modalTitle"
    size="lg"
  >
    <div
      v-if="providerId === 'usernamePassword'"
      class="space-y-3 text-sm text-gray-600 dark:text-gray-300"
    >
      <p>{{ t('setup.settings.authProviders.providers.usernamePassword.configureBody') }}</p>
    </div>

    <form
      v-else-if="isOAuth && providerId"
      id="auth-provider-form"
      class="space-y-5"
      @submit.prevent="save"
    >
      <UFormField
        :class="appFormFieldClass"
        :label="t('setup.settings.authProviders.fields.clientId')"
        required
      >
        <UInput
          v-model="form.clientId"
          class="w-full"
          size="lg"
          :ui="appInputUi"
        />
      </UFormField>

      <UFormField
        :class="appFormFieldClass"
        :label="t('setup.settings.authProviders.fields.clientSecret')"
        required
      >
        <AppPasswordInput
          v-model="form.clientSecret"
          :placeholder="providers[providerId].hasClientSecret
            ? t('setup.settings.authProviders.fields.clientSecretKeep')
            : undefined"
        />
      </UFormField>

      <UFormField
        v-if="showTenantId"
        :class="appFormFieldClass"
        :label="t('setup.settings.authProviders.fields.tenantId')"
      >
        <UInput
          v-model="form.tenantId"
          class="w-full"
          size="lg"
          :placeholder="t('setup.settings.authProviders.fields.tenantIdPlaceholder')"
          :ui="appInputUi"
        />
        <p :class="appFormHintClass">
          {{ t('setup.settings.authProviders.fields.tenantIdHint') }}
        </p>
      </UFormField>

      <UFormField
        :class="appFormFieldClass"
        :label="t('setup.settings.authProviders.fields.allowedDomains')"
      >
        <UTextarea
          v-model="form.allowedDomains"
          class="w-full"
          :rows="2"
          :placeholder="t('setup.settings.authProviders.fields.allowedDomainsPlaceholder')"
          :ui="appTextareaUi"
        />
      </UFormField>

      <p
        v-if="errorMsg"
        :class="appFormErrorClass"
      >
        {{ errorMsg }}
      </p>
    </form>

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          v-if="isOAuth"
          class="w-full sm:w-auto"
          type="submit"
          form="auth-provider-form"
          size="lg"
          :loading="saving"
        >
          {{ t('common.save') }}
        </UButton>
        <UButton
          v-else
          class="w-full sm:w-auto"
          size="lg"
          @click="open = false"
        >
          {{ t('common.cancel') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
