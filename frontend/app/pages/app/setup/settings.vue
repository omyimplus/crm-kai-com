<script setup lang="ts">
import {
  settingsTabs,
  type SettingsTabKey
} from '~/config/settingsTabs'
import {
  appTableRoleTabActiveClass,
  appTableRoleTabBaseClass,
  appTableRoleTabInactiveClass
} from '~/config/appFormUi'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { ensureProfile } = useProfile()
const { canManage } = useOrgSettings()

await ensureProfile()

if (!canManage.value) {
  await navigateTo('/app')
}

const activeTab = ref<SettingsTabKey>('companyInfo')

const tabItems = computed(() =>
  settingsTabs.map(tab => ({
    ...tab,
    label: t(`setup.settings.tabs.${tab.key}.label`)
  }))
)
</script>

<template>
  <div>
    <div class="mb-6">
      <h1 class="text-2xl font-bold font-heading">
        {{ t('setup.settings.title') }}
      </h1>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        {{ t('setup.settings.subtitle') }}
      </p>
    </div>

    <div class="mb-6 flex flex-wrap gap-2">
      <button
        v-for="tab in tabItems"
        :key="tab.key"
        type="button"
        :class="[
          appTableRoleTabBaseClass,
          activeTab === tab.key ? appTableRoleTabActiveClass : appTableRoleTabInactiveClass
        ]"
        @click="activeTab = tab.key"
      >
        <span class="inline-flex items-center gap-2">
          <UIcon
            :name="tab.icon"
            class="size-4 shrink-0"
          />
          {{ tab.label }}
        </span>
      </button>
    </div>

    <SetupSettingsCompanyProfilesTab v-if="activeTab === 'companyInfo'" />

    <SetupSettingsNotificationsTab v-else-if="activeTab === 'notifications'" />

    <SetupSettingsEmailTab v-else-if="activeTab === 'email'" />

    <SetupSettingsAuthProvidersTab v-else-if="activeTab === 'authProviders'" />
  </div>
</template>
