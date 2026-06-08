<script setup lang="ts">
import type { DataChangeAction, DataChangeLog } from '~/types/crm'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t, locale } = useI18n()
const { ensureProfile } = useProfile()
const { canView, list, entityTypes } = useDataChangeLogs()

await ensureProfile()

if (!canView.value) {
  await navigateTo('/app')
}

const logs = ref<DataChangeLog[]>([])
const loading = ref(true)
const expandedId = ref<string | null>(null)
const filterEntityType = ref<string | null>(null)
const filterAction = ref<DataChangeAction | null>(null)

const actionOptions = computed(() => [
  { label: t('setup.userActivity.filters.allActions'), value: null as DataChangeAction | null },
  { label: t('setup.userActivity.actions.create'), value: 'create' as const },
  { label: t('setup.userActivity.actions.update'), value: 'update' as const },
  { label: t('setup.userActivity.actions.delete'), value: 'delete' as const }
])

const entityTypeOptions = computed(() => [
  { label: t('setup.userActivity.filters.allTables'), value: null as string | null },
  ...entityTypes.map(type => ({
    label: t(`setup.userActivity.entityTypes.${type}`),
    value: type
  }))
])

async function refresh() {
  loading.value = true
  try {
    logs.value = await list({
      entityType: filterEntityType.value,
      action: filterAction.value
    })
  } catch (e) {
    console.error(e)
    logs.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

watch([filterEntityType, filterAction], () => {
  refresh()
})

function actionColor(action: DataChangeAction) {
  if (action === 'create') return 'success'
  if (action === 'delete') return 'error'
  return 'info'
}

function formatWhen(iso: string) {
  return new Date(iso).toLocaleString(locale.value === 'th' ? 'th-TH' : 'en-US')
}

function toggleDetails(log: DataChangeLog) {
  expandedId.value = expandedId.value === log.id ? null : log.id
}

function formatJson(data: Record<string, unknown> | null) {
  if (!data) return '—'
  return JSON.stringify(data, null, 2)
}
</script>

<template>
  <div>
    <div class="mb-6">
      <h1 class="text-2xl font-bold font-heading">
        {{ t('setup.userActivity.title') }}
      </h1>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        {{ t('setup.userActivity.subtitle') }}
      </p>
    </div>

    <UCard class="mb-4">
      <div class="flex flex-wrap gap-4">
        <UFormField
          :label="t('setup.userActivity.filters.table')"
          class="min-w-48"
        >
          <USelectMenu
            v-model="filterEntityType"
            :items="entityTypeOptions"
            value-key="value"
          />
        </UFormField>

        <UFormField
          :label="t('setup.userActivity.filters.action')"
          class="min-w-40"
        >
          <USelectMenu
            v-model="filterAction"
            :items="actionOptions"
            value-key="value"
          />
        </UFormField>
      </div>
    </UCard>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!logs.length">
      <p class="text-gray-500">
        {{ t('setup.userActivity.empty') }}
      </p>
    </UCard>

    <div
      v-else
      class="space-y-3"
    >
      <UCard
        v-for="log in logs"
        :key="log.id"
      >
        <div class="flex flex-wrap items-start justify-between gap-3">
          <div class="min-w-0 flex-1">
            <div class="flex flex-wrap items-center gap-2">
              <UBadge
                :color="actionColor(log.action)"
                variant="subtle"
              >
                {{ t(`setup.userActivity.actions.${log.action}`) }}
              </UBadge>
              <UBadge
                color="neutral"
                variant="outline"
              >
                {{ t(`setup.userActivity.entityTypes.${log.entity_type}`, log.entity_type) }}
              </UBadge>
            </div>
            <p class="mt-2 font-medium">
              {{ log.summary || t('setup.userActivity.noSummary') }}
            </p>
            <p class="mt-1 text-sm text-gray-500">
              {{ t('setup.userActivity.by', { name: log.actor_name || t('common.user') }) }}
              · {{ formatWhen(log.created_at) }}
            </p>
            <p class="mt-1 font-mono text-xs text-gray-400">
              {{ log.entity_id }}
            </p>
          </div>

          <UButton
            size="xs"
            variant="ghost"
            color="neutral"
            :icon="expandedId === log.id ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
            @click="toggleDetails(log)"
          >
            {{ t('setup.userActivity.details') }}
          </UButton>
        </div>

        <div
          v-if="expandedId === log.id"
          class="mt-4 grid gap-4 border-t border-gray-200 pt-4 dark:border-gray-800 lg:grid-cols-2"
        >
          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-500">
              {{ t('setup.userActivity.before') }}
            </p>
            <pre class="max-h-64 overflow-auto rounded-lg bg-gray-50 p-3 text-xs dark:bg-gray-900">{{ formatJson(log.old_data) }}</pre>
          </div>
          <div>
            <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-500">
              {{ t('setup.userActivity.after') }}
            </p>
            <pre class="max-h-64 overflow-auto rounded-lg bg-gray-50 p-3 text-xs dark:bg-gray-900">{{ formatJson(log.new_data) }}</pre>
          </div>
        </div>
      </UCard>
    </div>
  </div>
</template>
