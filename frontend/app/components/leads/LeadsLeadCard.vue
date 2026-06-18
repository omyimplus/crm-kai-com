<script setup lang="ts">
import type { Lead } from '~/types/crm'
import { appTableRowClass, appTableTextClass } from '~/config/appFormUi'
import { leadDisplayName } from '~/utils/masterLeads'
import { useLeadStatusLabel } from '~/composables/useLeadStatusLabel'

const props = defineProps<{
  lead: Lead
  canWrite: boolean
}>()

const emit = defineEmits<{
  edit: [lead: Lead]
  delete: [lead: Lead]
}>()

const { t } = useI18n()
const { formatCurrency } = useFormat()
const { leadStatusLabel } = useLeadStatusLabel()
</script>

<template>
  <article
    class="flex h-full flex-col rounded-2xl border border-gray-200 bg-white p-4 shadow-sm transition hover:border-gray-300 hover:shadow-md dark:border-gray-800 dark:bg-gray-900 dark:hover:border-gray-700"
  >
    <div class="mb-3 flex items-start justify-between gap-3">
      <div class="flex min-w-0 items-center gap-3">
        <LeadsScoreBadge :score="lead.lead_score" />
        <div class="min-w-0">
          <h3
            class="truncate font-semibold text-gray-900 dark:text-gray-100"
            :class="appTableRowClass"
          >
            {{ leadDisplayName(lead) }}
          </h3>
          <p
            class="truncate text-sm text-gray-500 dark:text-gray-400"
            :class="appTableTextClass"
          >
            {{ lead.lead_code }}
          </p>
        </div>
      </div>
      <LeadsPriorityBadge :priority="lead.priority" />
    </div>

    <dl
      class="mt-auto space-y-2 text-sm"
      :class="appTableTextClass"
    >
      <div class="flex items-start justify-between gap-2">
        <dt class="shrink-0 text-gray-500 dark:text-gray-400">
          {{ t('leads.columns.value') }}
        </dt>
        <dd class="truncate text-end font-semibold tabular-nums text-gray-900 dark:text-gray-100">
          {{
            Number(lead.lead_value) > 0
              ? formatCurrency(lead.lead_value)
              : t('leads.emptyCell')
          }}
        </dd>
      </div>
      <div
        v-if="lead.company_name"
        class="flex items-start justify-between gap-2"
      >
        <dt class="shrink-0 text-gray-500 dark:text-gray-400">
          {{ t('leads.columns.company') }}
        </dt>
        <dd class="truncate text-end text-gray-900 dark:text-gray-100">
          {{ lead.company_name }}
        </dd>
      </div>
      <div class="flex items-start justify-between gap-2">
        <dt class="shrink-0">{{ t('leads.columns.status') }}</dt>
        <dd>
          <LeadsStatusBadge
            :status-code="lead.status_code"
            :status-name="lead.status_name"
            :status-color="lead.status_color"
          />
        </dd>
      </div>
      <div class="flex items-start justify-between gap-2">
        <dt class="shrink-0">{{ t('leads.columns.source') }}</dt>
        <dd class="truncate text-end text-gray-900 dark:text-gray-100">
          {{ lead.lead_source_name || t('leads.emptyCell') }}
        </dd>
      </div>
    </dl>

    <div
      class="mt-4 flex justify-end gap-1 border-t border-gray-100 pt-3 dark:border-gray-800"
    >
      <AppIconButton
        icon="i-lucide-eye"
        :aria-label="t('leads.view')"
        :to="`/app/leads/${lead.id}`"
      />
      <AppIconButton
        v-if="canWrite"
        icon="i-lucide-pencil"
        :aria-label="t('common.edit')"
        @click="emit('edit', lead)"
      />
      <AppIconButton
        v-if="canWrite"
        icon="i-lucide-trash-2"
        color="error"
        :aria-label="t('common.delete')"
        @click="emit('delete', lead)"
      />
    </div>
  </article>
</template>
