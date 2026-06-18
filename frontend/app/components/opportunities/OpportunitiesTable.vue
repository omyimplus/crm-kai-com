<script setup lang="ts">
import type { Opportunity } from '~/types/crm'
import { appTableRowClass, appTableTextClass } from '~/config/appFormUi'
import { opportunityAssigneeDisplay } from '~/utils/masterOpportunities'

defineProps<{
  opportunities: Opportunity[]
  canWrite: boolean
}>()

const emit = defineEmits<{
  view: [row: Opportunity]
  edit: [row: Opportunity]
  delete: [row: Opportunity]
}>()

const { t } = useI18n()
const { formatCurrency, formatDate } = useFormat()
</script>

<template>
  <AppDataTable
    embedded
    table-class="table-fixed min-w-[64rem]"
  >
    <template #head>
      <AppDataTableRow>
        <AppDataTableTh class="w-[min(18rem,34vw)]">
          {{ t('opportunities.columns.title') }}
        </AppDataTableTh>
        <AppDataTableTh class="hidden w-[9rem] md:table-cell">
          {{ t('opportunities.columns.customer') }}
        </AppDataTableTh>
        <AppDataTableTh
          align="right"
          class="w-[6.5rem] whitespace-nowrap"
        >
          {{ t('opportunities.columns.value') }}
        </AppDataTableTh>
        <AppDataTableTh class="hidden w-[8.5rem] lg:table-cell">
          {{ t('opportunities.columns.closeDate') }}
        </AppDataTableTh>
        <AppDataTableTh class="hidden w-[7.5rem] lg:table-cell">
          {{ t('opportunities.columns.assigned') }}
        </AppDataTableTh>
        <AppDataTableTh class="w-[9rem] max-w-[9rem]">
          {{ t('opportunities.columns.stage') }}
        </AppDataTableTh>
        <AppDataTableTh
          align="right"
          class="w-[10rem] whitespace-nowrap"
          :aria-label="t('opportunities.columns.actions')"
        />
      </AppDataTableRow>
    </template>

    <AppDataTableRow
      v-for="row in opportunities"
      :key="row.id"
      :class="appTableRowClass"
    >
      <AppDataTableTd :class="appTableRowClass">
        <div class="min-w-0">
          <p class="truncate font-medium text-gray-900 dark:text-gray-100">
            {{ row.title }}
          </p>
          <p
            class="truncate text-xs text-gray-500 dark:text-gray-400"
            :class="appTableTextClass"
          >
            {{ row.opportunity_code }}
          </p>
        </div>
      </AppDataTableTd>

      <AppDataTableTd
        class="hidden md:table-cell"
        :class="appTableRowClass"
      >
        <span
          class="block truncate"
          :class="appTableTextClass"
        >
          {{ row.company_name || t('opportunities.emptyCell') }}
        </span>
      </AppDataTableTd>

      <AppDataTableTd
        align="right"
        :class="appTableRowClass"
      >
        <span class="font-medium text-emerald-700 dark:text-emerald-300">
          {{ formatCurrency(row.estimated_value) }}
        </span>
      </AppDataTableTd>

      <AppDataTableTd
        class="hidden lg:table-cell"
        :class="appTableRowClass"
      >
        <span :class="appTableTextClass">
          {{ row.close_date ? formatDate(row.close_date) : t('opportunities.notSet') }}
        </span>
      </AppDataTableTd>

      <AppDataTableTd
        class="hidden lg:table-cell"
        :class="appTableRowClass"
      >
        <span
          class="block truncate"
          :class="appTableTextClass"
        >
          {{ opportunityAssigneeDisplay(row, t('opportunities.emptyCell')) }}
        </span>
      </AppDataTableTd>

      <AppDataTableTd :class="appTableRowClass">
        <OpportunitiesStageBadge
          :stage-name="row.stage_name"
          :stage-color="row.stage_color"
          :probability="row.probability"
        />
      </AppDataTableTd>

      <AppDataTableTd
        align="right"
        :class="appTableRowClass"
      >
        <div class="flex items-center justify-end gap-1">
          <UButton
            variant="ghost"
            color="neutral"
            size="sm"
            icon="i-lucide-eye"
            :aria-label="t('opportunities.view')"
            @click="emit('view', row)"
          />
          <UButton
            v-if="canWrite"
            variant="ghost"
            color="neutral"
            size="sm"
            icon="i-lucide-pencil"
            :aria-label="t('common.edit')"
            @click="emit('edit', row)"
          />
          <UButton
            v-if="canWrite"
            variant="ghost"
            color="error"
            size="sm"
            icon="i-lucide-trash-2"
            :aria-label="t('common.delete')"
            @click="emit('delete', row)"
          />
        </div>
      </AppDataTableTd>
    </AppDataTableRow>
  </AppDataTable>
</template>
