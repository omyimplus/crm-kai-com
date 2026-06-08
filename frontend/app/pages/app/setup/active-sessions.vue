<script setup lang="ts">
import type { LoginSession } from '~/types/crm'
import { appTableBadgeClass, appTableTextClass } from '~/config/appFormUi'
import { getSessionEndedDisplay } from '~/utils/loginSessionDisplay'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t, locale } = useI18n()
const { ensureProfile } = useProfile()
const { canView, list } = useLoginSession()

await ensureProfile()

if (!canView.value) {
  await navigateTo('/app')
}

const sessions = ref<LoginSession[]>([])
const loading = ref(true)
const refreshing = ref(false)

async function refresh() {
  refreshing.value = true
  try {
    sessions.value = await list()
  } catch (e) {
    console.error(e)
    sessions.value = []
  } finally {
    loading.value = false
    refreshing.value = false
  }
}

await refresh()

const onlineCount = computed(() =>
  sessions.value.filter(session => session.is_online).length
)

const {
  page,
  pagedItems,
  totalItems: paginationTotal,
  totalPages,
  rangeStart,
  rangeEnd,
  pageSize
} = usePagination(sessions)

function displayName(session: LoginSession) {
  return session.full_name?.trim() || session.email || t('common.user')
}

function formatWhen(iso: string | null) {
  if (!iso) {
    return t('setup.activeSessions.never')
  }
  return new Date(iso).toLocaleString(locale.value === 'th' ? 'th-TH' : 'en-US')
}

function deviceLabel(deviceType: LoginSession['device_type']) {
  return t(`setup.activeSessions.devices.${deviceType}`)
}

function deviceIcon(deviceType: LoginSession['device_type']) {
  if (deviceType === 'mobile') return 'i-lucide-smartphone'
  if (deviceType === 'tablet') return 'i-lucide-tablet'
  if (deviceType === 'desktop') return 'i-lucide-monitor'
  return 'i-lucide-help-circle'
}

function browserLabel(browser: string) {
  const key = browser.toLowerCase()
  const known = ['chrome', 'firefox', 'safari', 'edge', 'opera', 'unknown'] as const
  if ((known as readonly string[]).includes(key)) {
    return t(`setup.activeSessions.browsers.${key}`)
  }
  return browser
}

function ipLabel(ip: string | null) {
  return ip?.trim() || t('setup.activeSessions.ipUnknown')
}

function endedLabel(session: LoginSession) {
  const ended = getSessionEndedDisplay(session)
  if (ended.stillActive) {
    return t('setup.activeSessions.stillActive')
  }
  if (!ended.at) {
    return t('setup.activeSessions.never')
  }
  const when = formatWhen(ended.at)
  return ended.approximate
    ? t('setup.activeSessions.endedApprox', { when })
    : when
}
</script>

<template>
  <div>
    <div class="mb-6 flex flex-wrap items-start justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold font-heading">
          {{ t('setup.activeSessions.title') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('setup.activeSessions.subtitle') }}
        </p>
      </div>

      <div class="flex flex-wrap items-center gap-3">
        <UBadge
          v-if="!loading"
          color="success"
          variant="subtle"
          class="px-3 py-1.5 text-sm font-medium"
        >
          {{ t('setup.activeSessions.activeCount', { count: onlineCount }) }}
        </UBadge>
        <UButton
          icon="i-lucide-refresh-cw"
          variant="outline"
          :loading="refreshing"
          @click="refresh"
        >
          {{ t('common.refresh') }}
        </UButton>
      </div>
    </div>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!sessions.length">
      <p class="text-gray-500">
        {{ t('setup.activeSessions.empty') }}
      </p>
    </UCard>

    <div
      v-else
      class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <AppDataTable embedded>
        <template #head>
          <tr>
            <AppDataTableTh>{{ t('setup.activeSessions.columns.user') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('setup.activeSessions.columns.device') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('setup.activeSessions.columns.browser') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('setup.activeSessions.columns.ip') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('setup.activeSessions.columns.loggedIn') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('setup.activeSessions.columns.lastActivity') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('setup.activeSessions.columns.ended') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('setup.activeSessions.columns.status') }}</AppDataTableTh>
          </tr>
        </template>

        <AppDataTableRow
          v-for="session in pagedItems"
          :key="session.id"
        >
          <AppDataTableTd :class="appTableTextClass">
            <div class="font-semibold text-gray-900 dark:text-gray-100">
              {{ displayName(session) }}
            </div>
            <div class="mt-0.5 text-sm text-gray-500 dark:text-gray-400">
              {{ session.email || t('common.empty') }}
            </div>
          </AppDataTableTd>

          <AppDataTableTd :class="appTableTextClass">
            <span class="inline-flex items-center gap-2 text-gray-700 dark:text-gray-300">
              <UIcon
                :name="deviceIcon(session.device_type)"
                class="size-4 shrink-0 text-gray-400"
              />
              {{ deviceLabel(session.device_type) }}
            </span>
          </AppDataTableTd>

          <AppDataTableTd :class="appTableTextClass">
            <span class="inline-flex items-center gap-2 text-gray-700 dark:text-gray-300">
              <UIcon
                name="i-lucide-globe"
                class="size-4 shrink-0 text-gray-400"
              />
              {{ browserLabel(session.browser) }}
            </span>
          </AppDataTableTd>

          <AppDataTableTd :class="appTableTextClass">
            <span class="inline-flex items-center gap-2 text-gray-700 dark:text-gray-300">
              <UIcon
                name="i-lucide-map-pin"
                class="size-4 shrink-0 text-gray-400"
              />
              <span class="font-mono text-sm">{{ ipLabel(session.ip_address) }}</span>
            </span>
          </AppDataTableTd>

          <AppDataTableTd
            :class="appTableTextClass"
            muted
          >
            {{ formatWhen(session.logged_in_at) }}
          </AppDataTableTd>

          <AppDataTableTd
            :class="appTableTextClass"
            muted
          >
            {{ formatWhen(session.last_seen_at) }}
          </AppDataTableTd>

          <AppDataTableTd
            :class="appTableTextClass"
            muted
          >
            <span
              :class="getSessionEndedDisplay(session).approximate
                ? 'text-gray-500 dark:text-gray-400'
                : ''"
            >
              {{ endedLabel(session) }}
            </span>
          </AppDataTableTd>

          <AppDataTableTd :class="appTableTextClass">
            <UBadge
              :color="session.is_online ? 'success' : 'neutral'"
              variant="subtle"
              :class="appTableBadgeClass"
            >
              {{
                session.is_online
                  ? t('setup.activeSessions.statusActive')
                  : t('setup.activeSessions.statusInactive')
              }}
            </UBadge>
          </AppDataTableTd>
        </AppDataTableRow>
      </AppDataTable>

      <AppPagination
        v-model:page="page"
        class="border-t border-gray-200 bg-white px-4 py-3 dark:border-gray-800 dark:bg-gray-900"
        :total-items="paginationTotal"
        :total-pages="totalPages"
        :range-start="rangeStart"
        :range-end="rangeEnd"
        :page-size="pageSize"
      />
    </div>
  </div>
</template>
