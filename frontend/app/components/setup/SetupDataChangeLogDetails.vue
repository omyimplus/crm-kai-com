<script setup lang="ts">
import type { DataChangeLog } from '~/types/crm'
import {
  buildDataChangeDisplayRows,
  buildMetadataTags
} from '~/utils/dataChangeLogDisplay'

const props = defineProps<{
  log: DataChangeLog
}>()

const { t } = useI18n()
const showRaw = ref(false)

const rows = computed(() =>
  buildDataChangeDisplayRows(
    props.log.action,
    props.log.old_data,
    props.log.new_data,
    t
  )
)

const metadataTags = computed(() => buildMetadataTags(props.log.metadata, t))

const isUpdate = computed(() => props.log.action === 'update')

function formatJson(data: Record<string, unknown> | null) {
  if (!data) return '—'
  return JSON.stringify(data, null, 2)
}
</script>

<template>
  <div class="mt-4 border-t border-gray-200 pt-4 dark:border-gray-800">
    <div
      v-if="metadataTags.length"
      class="mb-4 flex flex-wrap gap-2"
    >
      <UBadge
        v-for="tag in metadataTags"
        :key="tag.key"
        color="neutral"
        variant="subtle"
      >
        {{ tag.label }}
      </UBadge>
    </div>

    <p
      v-if="!rows.length"
      class="text-sm text-gray-500"
    >
      {{ t('setup.userActivity.noFieldChanges') }}
    </p>

    <div
      v-else-if="isUpdate"
      class="overflow-x-auto rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <table class="min-w-full divide-y divide-gray-200 text-sm dark:divide-gray-800">
        <thead class="bg-gray-50 dark:bg-gray-900/50">
          <tr>
            <th
              scope="col"
              class="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-gray-500"
            >
              {{ t('setup.userActivity.fieldColumn') }}
            </th>
            <th
              scope="col"
              class="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-gray-500"
            >
              {{ t('setup.userActivity.before') }}
            </th>
            <th
              scope="col"
              class="px-3 py-2 text-left text-xs font-semibold uppercase tracking-wide text-gray-500"
            >
              {{ t('setup.userActivity.after') }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200 dark:divide-gray-800">
          <tr
            v-for="row in rows"
            :key="row.key"
            class="bg-white dark:bg-gray-950"
          >
            <td class="whitespace-nowrap px-3 py-2 font-medium text-gray-700 dark:text-gray-200">
              {{ row.label }}
            </td>
            <td class="max-w-xs px-3 py-2 text-gray-600 dark:text-gray-400">
              <span class="whitespace-pre-wrap break-words">{{ row.before ?? t('setup.userActivity.fieldValues.empty') }}</span>
            </td>
            <td class="max-w-xs px-3 py-2 text-gray-900 dark:text-gray-100">
              <span class="whitespace-pre-wrap break-words font-medium">{{ row.after ?? t('setup.userActivity.fieldValues.empty') }}</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <dl
      v-else
      class="divide-y divide-gray-200 rounded-lg border border-gray-200 dark:divide-gray-800 dark:border-gray-800"
    >
      <div
        v-for="row in rows"
        :key="row.key"
        class="grid gap-1 px-3 py-2 sm:grid-cols-[minmax(8rem,30%)_1fr]"
      >
        <dt class="text-sm font-medium text-gray-500">
          {{ row.label }}
        </dt>
        <dd class="whitespace-pre-wrap break-words text-sm text-gray-900 dark:text-gray-100">
          {{ row.before ?? row.after }}
        </dd>
      </div>
    </dl>

    <div class="mt-4">
      <UButton
        size="xs"
        variant="ghost"
        color="neutral"
        :icon="showRaw ? 'i-lucide-code-xml' : 'i-lucide-braces'"
        @click="showRaw = !showRaw"
      >
        {{ showRaw ? t('setup.userActivity.hideRaw') : t('setup.userActivity.showRaw') }}
      </UButton>

      <div
        v-if="showRaw"
        class="mt-3 grid gap-4 lg:grid-cols-2"
      >
        <div>
          <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('setup.userActivity.before') }} (JSON)
          </p>
          <pre class="max-h-64 overflow-auto rounded-lg bg-gray-50 p-3 text-xs dark:bg-gray-900">{{ formatJson(log.old_data) }}</pre>
        </div>
        <div>
          <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('setup.userActivity.after') }} (JSON)
          </p>
          <pre class="max-h-64 overflow-auto rounded-lg bg-gray-50 p-3 text-xs dark:bg-gray-900">{{ formatJson(log.new_data) }}</pre>
        </div>
      </div>
    </div>
  </div>
</template>
