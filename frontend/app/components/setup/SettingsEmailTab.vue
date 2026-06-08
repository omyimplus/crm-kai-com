<script setup lang="ts">
import {
  appFormErrorClass,
  appFormFieldClass,
  appFormHintClass,
  appFormSwitchBoxClass,
  appInputUi
} from '~/config/appFormUi'
import { DEFAULT_ORG_EMAIL_SETTINGS } from '~/config/orgEmailSettings'
import {
  settingsToForm,
  trimOrgEmailSettingsForm,
  validateOrgEmailSettingsForm
} from '~/utils/orgEmailSettings'

const { t } = useI18n()
const { get, update, testConnection } = useOrgEmailSettings()

const loading = ref(true)
const saving = ref(false)
const testing = ref(false)
const errorMsg = ref('')
const testMsg = ref('')
const testIsError = ref(false)
const testRecipient = ref('')

const saved = ref({ ...DEFAULT_ORG_EMAIL_SETTINGS })
const form = ref(settingsToForm(DEFAULT_ORG_EMAIL_SETTINGS))

async function refresh() {
  loading.value = true
  errorMsg.value = ''
  try {
    saved.value = await get()
    form.value = settingsToForm(saved.value)
  } catch (e) {
    console.error(e)
    errorMsg.value = e instanceof Error ? e.message : t('common.loadFailed')
  } finally {
    loading.value = false
  }
}

await refresh()

function validationErrorKey() {
  return validateOrgEmailSettingsForm(form.value, {
    requirePassword: form.value.enabled && !saved.value.hasPassword
  })
}

async function save() {
  const invalid = validationErrorKey()
  if (invalid) {
    errorMsg.value = t(`setup.settings.email.errors.${invalid}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    const payload = trimOrgEmailSettingsForm(form.value)
    await update(payload)
    await refresh()
    form.value.password = ''
  } catch (e) {
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    saving.value = false
  }
}

async function onTestConnection() {
  testing.value = true
  testMsg.value = ''
  testIsError.value = false
  errorMsg.value = ''

  const invalid = validationErrorKey()
  if (invalid) {
    testIsError.value = true
    testMsg.value = t(`setup.settings.email.errors.${invalid}`)
    testing.value = false
    return
  }

  try {
    if (formChanged.value) {
      await update(trimOrgEmailSettingsForm(form.value))
      await refresh()
      form.value.password = ''
    }
    await testConnection(testRecipient.value)
    testMsg.value = t('setup.settings.email.testSuccess')
  } catch (e) {
    testIsError.value = true
    const message = e instanceof Error ? e.message : t('common.saveFailed')
    if (message.toLowerCase().includes('not available yet')) {
      testMsg.value = t('setup.settings.email.testSoon')
    } else if (message.toLowerCase().includes('not configured')
      || message.toLowerCase().includes('disabled')) {
      testMsg.value = t('setup.settings.email.testNotConfigured')
    } else {
      testMsg.value = message
    }
  } finally {
    testing.value = false
  }
}

const formChanged = computed(() => {
  const current = trimOrgEmailSettingsForm(form.value)
  return current.enabled !== saved.value.enabled
    || current.host !== saved.value.host
    || current.port !== saved.value.port
    || current.username !== saved.value.username
    || current.fromName !== saved.value.fromName
    || current.fromEmail !== saved.value.fromEmail
    || current.useSslTls !== saved.value.useSslTls
    || Boolean(current.password)
})
</script>

<template>
  <UCard v-if="loading">
    <p class="text-gray-500">
      {{ t('common.loading') }}
    </p>
  </UCard>

  <UCard v-else>
    <div class="mb-6 flex items-start gap-3">
      <div
        class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary"
      >
        <UIcon
          name="i-lucide-mail"
          class="size-5"
        />
      </div>
      <div>
        <h2 class="text-base font-semibold font-heading text-gray-900 dark:text-gray-100">
          {{ t('setup.settings.email.formTitle') }}
        </h2>
        <p class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
          {{ t('setup.settings.email.formSubtitle') }}
        </p>
      </div>
    </div>

    <form
      class="space-y-5"
      @submit.prevent="save"
    >
      <UFormField :class="appFormFieldClass">
        <div :class="appFormSwitchBoxClass">
          <div class="min-w-0 flex-1">
            <p class="text-sm font-medium text-gray-900 dark:text-gray-100">
              {{ t('setup.settings.email.enabled') }}
            </p>
            <p :class="appFormHintClass">
              {{ t('setup.settings.email.enabledHint') }}
            </p>
          </div>
          <USwitch v-model="form.enabled" />
        </div>
      </UFormField>

      <div class="grid gap-5 sm:grid-cols-2">
        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.email.host')"
          required
        >
          <UInput
            v-model="form.host"
            class="w-full"
            size="lg"
            :ui="appInputUi"
            :disabled="!form.enabled"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.email.port')"
          required
        >
          <UInput
            v-model.number="form.port"
            class="w-full"
            size="lg"
            type="number"
            min="1"
            max="65535"
            :ui="appInputUi"
            :disabled="!form.enabled"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.email.username')"
          required
        >
          <UInput
            v-model="form.username"
            class="w-full"
            size="lg"
            :ui="appInputUi"
            :disabled="!form.enabled"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.email.password')"
          required
        >
          <AppPasswordInput
            v-model="form.password"
            class="w-full"
            :disabled="!form.enabled"
            :placeholder="saved.hasPassword
              ? t('setup.settings.email.passwordKeep')
              : undefined"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.email.fromName')"
          required
        >
          <UInput
            v-model="form.fromName"
            class="w-full"
            size="lg"
            :ui="appInputUi"
            :disabled="!form.enabled"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.settings.email.fromEmail')"
          required
        >
          <UInput
            v-model="form.fromEmail"
            class="w-full"
            size="lg"
            type="email"
            :ui="appInputUi"
            :disabled="!form.enabled"
          />
        </UFormField>
      </div>

      <UFormField :class="appFormFieldClass">
        <div :class="appFormSwitchBoxClass">
          <div class="min-w-0 flex-1">
            <p class="text-sm font-medium text-gray-900 dark:text-gray-100">
              {{ t('setup.settings.email.useSslTls') }}
            </p>
            <p :class="appFormHintClass">
              {{ t('setup.settings.email.useSslTlsHint') }}
            </p>
          </div>
          <USwitch
            v-model="form.useSslTls"
            :disabled="!form.enabled"
          />
        </div>
      </UFormField>

      <UFormField
        :class="appFormFieldClass"
        :label="t('setup.settings.email.testRecipient')"
      >
        <UInput
          v-model="testRecipient"
          class="w-full"
          size="lg"
          type="email"
          :placeholder="t('setup.settings.email.testRecipientPlaceholder')"
          :ui="appInputUi"
          :disabled="!form.enabled"
        />
      </UFormField>

      <p
        v-if="errorMsg"
        :class="appFormErrorClass"
      >
        {{ errorMsg }}
      </p>

      <p
        v-if="testMsg"
        class="text-sm"
        :class="testIsError ? 'text-amber-700 dark:text-amber-300' : 'text-green-700 dark:text-green-300'"
      >
        {{ testMsg }}
      </p>

      <div class="flex flex-col gap-3 border-t border-gray-200 pt-5 sm:flex-row sm:items-center dark:border-gray-800">
        <UButton
          type="submit"
          size="lg"
          icon="i-lucide-save"
          class="w-full sm:flex-1"
          :loading="saving"
        >
          {{ t('common.save') }}
        </UButton>
        <UButton
          type="button"
          size="lg"
          variant="outline"
          color="neutral"
          icon="i-lucide-send"
          class="w-full sm:w-auto"
          :loading="testing"
          :disabled="!form.enabled"
          @click="onTestConnection"
        >
          {{ t('setup.settings.email.testConnection') }}
        </UButton>
      </div>
    </form>
  </UCard>
</template>
