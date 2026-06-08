<script setup lang="ts">
import type { SettingsTabKey } from '~/config/settingsTabs'

const props = defineProps<{
  tabKey: SettingsTabKey
}>()

const { t } = useI18n()

const tabIcons: Record<SettingsTabKey, string> = {
  companyInfo: 'i-lucide-building-2',
  notifications: 'i-lucide-bell',
  email: 'i-lucide-mail',
  authProviders: 'i-lucide-key-round'
}
</script>

<template>
  <UCard>
    <div class="flex flex-col items-center px-6 py-10 text-center">
      <div
        class="mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-green-500/10 text-green-600 dark:text-green-400"
      >
        <UIcon
          :name="tabIcons[props.tabKey]"
          class="h-7 w-7"
        />
      </div>
      <UBadge
        color="warning"
        variant="subtle"
        class="mb-3"
      >
        {{ t('setup.comingSoon') }}
      </UBadge>
      <p class="text-sm text-gray-500 dark:text-gray-400">
        {{ t(`setup.settings.tabs.${tabKey}.soon`) }}
      </p>
    </div>
  </UCard>
</template>
