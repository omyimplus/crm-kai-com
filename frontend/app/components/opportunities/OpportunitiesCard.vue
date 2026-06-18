<script setup lang="ts">
import type { Opportunity } from '~/types/crm'
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
  <div class="grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
    <UCard
      v-for="row in opportunities"
      :key="row.id"
      class="rounded-2xl"
    >
      <div class="space-y-3">
        <div class="flex items-start justify-between gap-2">
          <div class="min-w-0">
            <p class="truncate font-semibold text-gray-900 dark:text-gray-100">
              {{ row.title }}
            </p>
            <p class="truncate text-xs text-gray-500 dark:text-gray-400">
              {{ row.opportunity_code }}
            </p>
          </div>
          <OpportunitiesStageBadge
            :stage-name="row.stage_name"
            :stage-color="row.stage_color"
            :probability="row.probability"
          />
        </div>

        <div class="space-y-1 text-sm text-gray-600 dark:text-gray-300">
          <p class="truncate">
            {{ row.company_name || t('opportunities.emptyCell') }}
          </p>
          <p class="font-medium text-emerald-700 dark:text-emerald-300">
            {{ formatCurrency(row.estimated_value) }}
          </p>
          <p class="text-xs text-gray-500 dark:text-gray-400">
            {{ opportunityAssigneeDisplay(row, t('opportunities.emptyCell')) }}
            ·
            {{ row.close_date ? formatDate(row.close_date) : t('opportunities.notSet') }}
          </p>
        </div>

        <div class="flex flex-wrap gap-2">
          <UButton
            size="sm"
            variant="soft"
            icon="i-lucide-eye"
            @click="emit('view', row)"
          >
            {{ t('opportunities.view') }}
          </UButton>
          <UButton
            v-if="canWrite"
            size="sm"
            variant="soft"
            icon="i-lucide-pencil"
            @click="emit('edit', row)"
          >
            {{ t('common.edit') }}
          </UButton>
        </div>
      </div>
    </UCard>
  </div>
</template>
