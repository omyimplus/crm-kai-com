<script setup lang="ts">
import {
  DEFAULT_ORG_NOTIFICATION_SETTINGS,
  ORG_NOTIFICATION_SETTING_KEYS,
  type OrgNotificationSettingKey,
  type OrgNotificationSettings
} from '~/config/orgNotificationSettings'

const { t } = useI18n()
const { get, update, sendTestEmail } = useOrgNotificationSettings()

const settings = ref<OrgNotificationSettings>({ ...DEFAULT_ORG_NOTIFICATION_SETTINGS })
const loading = ref(true)
const savingKey = ref<OrgNotificationSettingKey | null>(null)
const sendingEmail = ref(false)
const errorMsg = ref('')
const sendEmailMsg = ref('')
const sendEmailError = ref(false)

async function refresh() {
  loading.value = true
  errorMsg.value = ''
  try {
    settings.value = await get()
  } catch (e) {
    console.error(e)
    errorMsg.value = e instanceof Error ? e.message : t('common.loadFailed')
  } finally {
    loading.value = false
  }
}

await refresh()

async function onToggle(key: OrgNotificationSettingKey, enabled: boolean) {
  const previous = settings.value[key]
  settings.value = { ...settings.value, [key]: enabled }
  savingKey.value = key
  errorMsg.value = ''
  try {
    await update(settings.value)
  } catch (e) {
    settings.value = { ...settings.value, [key]: previous }
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    savingKey.value = null
  }
}

async function onSendEmail() {
  sendingEmail.value = true
  sendEmailMsg.value = ''
  sendEmailError.value = false
  try {
    await sendTestEmail()
    sendEmailMsg.value = t('setup.settings.notifications.sendEmailSuccess')
  } catch (e) {
    sendEmailError.value = true
    const message = e instanceof Error ? e.message : t('common.saveFailed')
    if (message.toLowerCase().includes('email service not configured')) {
      sendEmailMsg.value = t('setup.settings.notifications.sendEmailNotConfigured')
    } else if (message.toLowerCase().includes('not available yet')) {
      sendEmailMsg.value = t('setup.settings.notifications.sendEmailSoon')
    } else {
      sendEmailMsg.value = message
    }
  } finally {
    sendingEmail.value = false
  }
}
</script>

<template>
  <div class="space-y-6">
    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <template v-else>
      <UCard>
        <h2 class="mb-1 text-base font-semibold font-heading text-gray-900 dark:text-gray-100">
          {{ t('setup.settings.notifications.preferencesTitle') }}
        </h2>

        <ul class="mt-4 divide-y divide-gray-200 dark:divide-gray-800">
          <li
            v-for="key in ORG_NOTIFICATION_SETTING_KEYS"
            :key="key"
            class="flex items-center justify-between gap-4 py-4 first:pt-0 last:pb-0"
          >
            <div class="min-w-0">
              <p class="font-medium text-gray-900 dark:text-gray-100">
                {{ t(`setup.settings.notifications.items.${key}.title`) }}
              </p>
              <p class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
                {{ t(`setup.settings.notifications.items.${key}.description`) }}
              </p>
            </div>
            <USwitch
              :model-value="settings[key]"
              :disabled="savingKey === key"
              :aria-label="t(`setup.settings.notifications.items.${key}.title`)"
              @update:model-value="onToggle(key, $event)"
            />
          </li>
        </ul>

        <p
          v-if="errorMsg"
          class="mt-4 text-sm text-red-600 dark:text-red-400"
        >
          {{ errorMsg }}
        </p>
      </UCard>

      <UCard>
        <h2 class="text-base font-semibold font-heading text-gray-900 dark:text-gray-100">
          {{ t('setup.settings.notifications.sendEmailTitle') }}
        </h2>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('setup.settings.notifications.sendEmailHint') }}
        </p>

        <div class="mt-4 flex flex-wrap items-center gap-3">
          <UButton
            icon="i-lucide-send"
            :loading="sendingEmail"
            @click="onSendEmail"
          >
            {{ t('setup.settings.notifications.sendEmailAction') }}
          </UButton>
        </div>

        <p
          v-if="sendEmailMsg"
          class="mt-3 text-sm"
          :class="sendEmailError ? 'text-amber-700 dark:text-amber-300' : 'text-green-700 dark:text-green-300'"
        >
          {{ sendEmailMsg }}
        </p>
      </UCard>
    </template>
  </div>
</template>
