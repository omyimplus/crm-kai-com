<script setup lang="ts">
import {
  DEFAULT_ORG_AUTH_PROVIDERS,
  ORG_AUTH_PROVIDER_ICONS,
  ORG_AUTH_PROVIDER_IDS,
  type OrgAuthProviderId,
  type OrgAuthProviders
} from '~/config/orgAuthProviders'
import { appFormInfoClass } from '~/config/appFormUi'

const { t } = useI18n()
const { get, update } = useOrgAuthProviders()

const providers = ref<OrgAuthProviders>({ ...DEFAULT_ORG_AUTH_PROVIDERS })
const loading = ref(true)
const savingId = ref<OrgAuthProviderId | null>(null)
const errorMsg = ref('')
const configureOpen = ref(false)
const configuringId = ref<OrgAuthProviderId | null>(null)

const tipItems = computed(() => [
  t('setup.settings.authProviders.tips.microsoftAzure'),
  t('setup.settings.authProviders.tips.google'),
  t('setup.settings.authProviders.tips.tenantCommon'),
  t('setup.settings.authProviders.tips.allowedDomains'),
  t('setup.settings.authProviders.tips.envVars')
])

async function refresh() {
  loading.value = true
  errorMsg.value = ''
  try {
    providers.value = await get()
  } catch (e) {
    console.error(e)
    errorMsg.value = e instanceof Error ? e.message : t('common.loadFailed')
  } finally {
    loading.value = false
  }
}

await refresh()

function openConfigure(id: OrgAuthProviderId) {
  configuringId.value = id
  configureOpen.value = true
}

async function onToggle(id: OrgAuthProviderId, enabled: boolean) {
  const previous = providers.value[id].enabled
  providers.value = {
    ...providers.value,
    [id]: { ...providers.value[id], enabled }
  }

  savingId.value = id
  errorMsg.value = ''
  try {
    await update(providers.value, id, { enabled })
    await refresh()
  } catch (e) {
    providers.value = {
      ...providers.value,
      [id]: { ...providers.value[id], enabled: previous }
    }
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    savingId.value = null
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
        <div class="mb-6 flex items-start gap-3">
          <div
            class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-primary/10 text-primary"
          >
            <UIcon
              name="i-lucide-key-round"
              class="size-5"
            />
          </div>
          <div>
            <h2 class="text-base font-semibold font-heading text-gray-900 dark:text-gray-100">
              {{ t('setup.settings.authProviders.title') }}
            </h2>
            <p class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
              {{ t('setup.settings.authProviders.subtitle') }}
            </p>
          </div>
        </div>

        <ul class="divide-y divide-gray-200 dark:divide-gray-800">
          <li
            v-for="id in ORG_AUTH_PROVIDER_IDS"
            :key="id"
            class="flex flex-wrap items-center justify-between gap-3 py-4 first:pt-0 last:pb-0"
          >
            <div class="flex min-w-0 items-center gap-3">
              <div
                class="flex size-11 shrink-0 items-center justify-center rounded-xl border border-gray-200 bg-gray-50 text-gray-600 dark:border-gray-700 dark:bg-gray-800/50 dark:text-gray-300"
              >
                <UIcon
                  :name="ORG_AUTH_PROVIDER_ICONS[id]"
                  class="size-5"
                />
              </div>
              <p class="font-medium text-gray-900 dark:text-gray-100">
                {{ t(`setup.settings.authProviders.providers.${id}.name`) }}
              </p>
            </div>

            <div class="flex items-center gap-2 sm:gap-3">
              <UButton
                size="sm"
                variant="soft"
                color="neutral"
                icon="i-lucide-pencil"
                class="rounded-lg"
                @click="openConfigure(id)"
              >
                {{ t('setup.settings.authProviders.configure') }}
              </UButton>
              <USwitch
                :model-value="providers[id].enabled"
                :disabled="savingId === id"
                :aria-label="t(`setup.settings.authProviders.providers.${id}.name`)"
                @update:model-value="onToggle(id, $event)"
              />
            </div>
          </li>
        </ul>

        <p
          v-if="errorMsg"
          class="mt-4 text-sm text-red-600 dark:text-red-400"
        >
          {{ errorMsg }}
        </p>
      </UCard>

      <div :class="appFormInfoClass">
        <p class="mb-2 font-semibold">
          {{ t('setup.settings.authProviders.tipsTitle') }}
        </p>
        <ul class="list-disc space-y-1 ps-5">
          <li
            v-for="(tip, index) in tipItems"
            :key="index"
          >
            {{ tip }}
          </li>
        </ul>
      </div>
    </template>

    <SetupSettingsAuthProviderFormModal
      v-model:open="configureOpen"
      :provider-id="configuringId"
      :providers="providers"
      @saved="refresh"
    />
  </div>
</template>
