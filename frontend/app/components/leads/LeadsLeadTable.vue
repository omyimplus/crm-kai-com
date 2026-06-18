<script setup lang="ts">
import type { Lead } from '~/types/crm'
import {
  appTableRowClass,
  appTableTextClass
} from '~/config/appFormUi'
import {
  leadDisplayName,
  leadTableCompanySubtitle,
  leadTableContactLine
} from '~/utils/masterLeads'

defineProps<{
  leads: Lead[]
  canWrite: boolean
}>()

const emit = defineEmits<{
  edit: [lead: Lead]
  delete: [lead: Lead]
}>()

const { t } = useI18n()
const { formatCurrency, formatDate } = useFormat()
</script>

<template>
  <AppDataTable
    embedded
    table-class="table-fixed min-w-[68rem]"
  >
    <template #head>
      <AppDataTableRow>
        <AppDataTableTh class="w-[min(20rem,36vw)]">
          {{ t('leads.columns.lead') }}
        </AppDataTableTh>
        <AppDataTableTh
          align="right"
          class="w-[6.5rem] whitespace-nowrap"
        >
          {{ t('leads.columns.value') }}
        </AppDataTableTh>
        <AppDataTableTh class="hidden w-[9.5rem] md:table-cell">
          {{ t('leads.columns.nextAction') }}
        </AppDataTableTh>
        <AppDataTableTh class="hidden w-[8rem] lg:table-cell">
          {{ t('leads.columns.source') }}
        </AppDataTableTh>
        <AppDataTableTh class="hidden w-[7.5rem] lg:table-cell">
          {{ t('leads.columns.owner') }}
        </AppDataTableTh>
        <AppDataTableTh class="hidden w-[7.5rem] lg:table-cell">
          {{ t('leads.columns.teleSale') }}
        </AppDataTableTh>
        <AppDataTableTh class="w-[8rem] max-w-[8rem] whitespace-nowrap">
          {{ t('leads.columns.status') }}
        </AppDataTableTh>
        <AppDataTableTh
          align="right"
          class="w-[9.5rem] whitespace-nowrap"
          :aria-label="t('leads.columns.actions')"
        />
      </AppDataTableRow>
    </template>

    <AppDataTableRow
      v-for="lead in leads"
      :key="lead.id"
      :class="appTableRowClass"
    >
      <AppDataTableTd
        class="max-w-[20rem]"
        :class="appTableRowClass"
      >
        <div class="flex min-w-0 items-start gap-3">
          <LeadsScoreBadge
            :score="lead.lead_score"
            size="sm"
            class="mt-0.5"
          />
          <div class="min-w-0 flex-1 overflow-hidden">
            <p
              class="truncate font-medium text-gray-900 dark:text-gray-100"
              :title="leadDisplayName(lead)"
            >
              {{ leadDisplayName(lead) }}
            </p>
            <div class="mt-0.5 flex min-w-0 flex-wrap items-center gap-x-2 gap-y-0.5">
              <span
                class="truncate text-xs text-gray-500 dark:text-gray-400"
                :class="appTableTextClass"
              >
                {{ lead.lead_code }}
              </span>
              <LeadsPriorityBadge
                :priority="lead.priority"
                compact
                class="shrink-0"
              />
            </div>
            <p
              v-if="leadTableCompanySubtitle(lead)"
              class="mt-0.5 truncate text-sm text-gray-600 dark:text-gray-300"
              :class="appTableTextClass"
              :title="leadTableCompanySubtitle(lead) ?? undefined"
            >
              {{ leadTableCompanySubtitle(lead) }}
            </p>
            <p
              v-if="leadTableContactLine(lead)"
              class="mt-0.5 truncate text-xs text-gray-500 dark:text-gray-400 lg:hidden"
              :class="appTableTextClass"
            >
              {{ leadTableContactLine(lead) }}
            </p>
          </div>
        </div>
      </AppDataTableTd>

      <AppDataTableTd
        align="right"
        class="whitespace-nowrap tabular-nums"
        :class="appTableRowClass"
      >
        <span
          class="font-semibold text-gray-900 dark:text-gray-100"
          :class="Number(lead.lead_value) > 0 ? '' : 'font-normal text-gray-400 dark:text-gray-500'"
        >
          {{
            Number(lead.lead_value) > 0
              ? formatCurrency(lead.lead_value)
              : t('leads.emptyCell')
          }}
        </span>
      </AppDataTableTd>

      <AppDataTableTd
        class="hidden max-w-[9.5rem] md:table-cell"
        :class="appTableRowClass"
      >
        <template v-if="lead.next_action_at || lead.next_action?.trim()">
          <p
            v-if="lead.next_action_at"
            class="truncate text-sm text-gray-900 dark:text-gray-100"
          >
            {{ formatDate(lead.next_action_at) }}
          </p>
          <p
            v-if="lead.next_action?.trim()"
            class="truncate text-xs text-gray-500 dark:text-gray-400"
            :class="appTableTextClass"
            :title="lead.next_action"
          >
            {{ lead.next_action }}
          </p>
        </template>
        <span
          v-else
          class="text-gray-400 dark:text-gray-500"
          :class="appTableTextClass"
        >
          {{ t('leads.emptyCell') }}
        </span>
      </AppDataTableTd>

      <AppDataTableTd
        muted
        class="hidden max-w-[8rem] truncate lg:table-cell"
        :class="appTableTextClass"
        :title="lead.lead_source_name ?? undefined"
      >
        {{ lead.lead_source_name || t('leads.emptyCell') }}
      </AppDataTableTd>

      <AppDataTableTd
        muted
        class="hidden max-w-[7.5rem] truncate lg:table-cell"
        :class="appTableTextClass"
        :title="lead.owner_name ?? undefined"
      >
        {{ lead.owner_name || t('leads.emptyCell') }}
      </AppDataTableTd>

      <AppDataTableTd
        muted
        class="hidden max-w-[7.5rem] truncate lg:table-cell"
        :class="appTableTextClass"
        :title="lead.tele_sale_name ?? undefined"
      >
        {{ lead.tele_sale_name || t('leads.emptyCell') }}
      </AppDataTableTd>

      <AppDataTableTd class="max-w-[8rem] whitespace-nowrap">
        <LeadsStatusBadge
          :status-code="lead.status_code"
          :status-name="lead.status_name"
          :status-color="lead.status_color"
          compact
        />
      </AppDataTableTd>

      <AppDataTableTd
        align="right"
        class="w-[9.5rem] whitespace-nowrap"
        @click.stop
      >
        <div class="inline-flex items-center justify-end gap-1">
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
      </AppDataTableTd>
    </AppDataTableRow>
  </AppDataTable>
</template>
