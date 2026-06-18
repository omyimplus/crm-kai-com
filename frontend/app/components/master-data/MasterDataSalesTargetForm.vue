<script setup lang="ts">
import {
  SALES_TARGET_MONTHS,
  SALES_TARGET_PERIOD_TYPES,
  SALES_TARGET_QUARTERS,
  achievementColor,
  masterSalesTargetSectionThemes,
  salesTargetYearOptions
} from '~/config/masterSalesTarget'
import { appFormFieldClass, appSelectMenuUi } from '~/config/appFormUi'
import type { MasterSalesTargetFormInput } from '~/utils/masterSalesTarget'

const form = defineModel<MasterSalesTargetFormInput>({ required: true })

const props = defineProps<{
  assigneeOptions: { label: string, value: string }[]
  readonly?: boolean
  achievementPct?: number | null
}>()

const showProgress = computed(() =>
  props.readonly && props.achievementPct != null
)

const { t } = useI18n()

const periodTypeOptions = computed(() =>
  SALES_TARGET_PERIOD_TYPES.map(value => ({
    value,
    label: t(`masterData.salesTarget.options.periodType.${value}`)
  }))
)

const yearOptions = computed(() =>
  salesTargetYearOptions().map(year => ({ value: year, label: String(year) }))
)

const monthOptions = computed(() =>
  SALES_TARGET_MONTHS.map(month => ({
    value: month,
    label: t(`masterData.salesTarget.options.months.${month}`)
  }))
)

const quarterOptions = computed(() =>
  SALES_TARGET_QUARTERS.map(quarter => ({
    value: quarter,
    label: t(`masterData.salesTarget.options.quarters.${quarter}`)
  }))
)

watch(
  () => form.value.period_type,
  (type) => {
    if (type === 'month') {
      form.value.period_quarter = null
      if (!form.value.period_month) {
        form.value.period_month = new Date().getMonth() + 1
      }
    } else if (type === 'quarter') {
      form.value.period_month = null
      if (!form.value.period_quarter) {
        form.value.period_quarter = Math.ceil((new Date().getMonth() + 1) / 3)
      }
    } else {
      form.value.period_month = null
      form.value.period_quarter = null
    }
  }
)
</script>

<template>
  <div class="space-y-6">
    <AppFormSection
      :title="t('masterData.salesTarget.sections.main')"
      :icon="masterSalesTargetSectionThemes.main.icon"
      :icon-class="masterSalesTargetSectionThemes.main.iconClass"
    >
    <div class="grid gap-4 md:grid-cols-2">
      <UFormField
        :label="t('masterData.salesTarget.fields.assignee')"
        required
        :class="appFormFieldClass"
      >
        <USelectMenu
          v-model="form.profile_id"
          :items="assigneeOptions"
          value-key="value"
          searchable
          size="lg"
          :disabled="readonly"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
        />
      </UFormField>

      <UFormField
        :label="t('masterData.salesTarget.fields.periodType')"
        required
        :class="appFormFieldClass"
      >
        <USelectMenu
          v-model="form.period_type"
          :items="periodTypeOptions"
          value-key="value"
          size="lg"
          :disabled="readonly"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
        />
      </UFormField>

      <UFormField
        :label="t('masterData.salesTarget.fields.periodYear')"
        required
        :class="appFormFieldClass"
      >
        <USelectMenu
          v-model="form.period_year"
          :items="yearOptions"
          value-key="value"
          size="lg"
          :disabled="readonly"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
        />
      </UFormField>

      <UFormField
        v-if="form.period_type === 'month'"
        :label="t('masterData.salesTarget.fields.periodMonth')"
        required
        :class="appFormFieldClass"
      >
        <USelectMenu
          v-model="form.period_month"
          :items="monthOptions"
          value-key="value"
          size="lg"
          :disabled="readonly"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
        />
      </UFormField>

      <UFormField
        v-if="form.period_type === 'quarter'"
        :label="t('masterData.salesTarget.fields.periodQuarter')"
        required
        :class="appFormFieldClass"
      >
        <USelectMenu
          v-model="form.period_quarter"
          :items="quarterOptions"
          value-key="value"
          size="lg"
          :disabled="readonly"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
        />
      </UFormField>

      <UFormField
        :label="t('masterData.salesTarget.fields.targetAmount')"
        required
        :class="appFormFieldClass"
      >
        <UInput
          v-model.number="form.target_amount"
          type="number"
          min="0"
          step="1"
          size="lg"
          :disabled="readonly"
          :class="appFormFieldClass"
        />
      </UFormField>

      <UFormField
        :label="t('masterData.salesTarget.fields.currentAmount')"
        :class="appFormFieldClass"
      >
        <UInput
          v-model.number="form.current_amount"
          type="number"
          min="0"
          step="1"
          size="lg"
          :disabled="readonly"
          :class="appFormFieldClass"
        />
      </UFormField>

      <UFormField
        :label="t('masterData.salesTarget.fields.currency')"
        :class="appFormFieldClass"
      >
        <UInput
          v-model="form.currency"
          size="lg"
          disabled
          :class="appFormFieldClass"
        />
      </UFormField>

      <UFormField
        :label="t('masterData.salesTarget.fields.notes')"
        class="md:col-span-2"
        :class="appFormFieldClass"
      >
        <UTextarea
          v-model="form.notes"
          :disabled="readonly"
          :rows="3"
          :class="appFormFieldClass"
        />
      </UFormField>
    </div>
    </AppFormSection>

    <AppFormSection
      v-if="showProgress"
      :title="t('masterData.salesTarget.sections.progress')"
      :icon="masterSalesTargetSectionThemes.progress.icon"
      :icon-class="masterSalesTargetSectionThemes.progress.iconClass"
    >
      <div class="flex flex-wrap items-center justify-between gap-3">
        <p class="text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.salesTarget.currentHint') }}
        </p>
        <p class="text-lg font-semibold tabular-nums">
          {{ achievementPct }}%
        </p>
      </div>
      <UProgress
        class="mt-4"
        :model-value="Math.min(achievementPct ?? 0, 100)"
        :color="achievementColor(achievementPct ?? 0)"
        size="md"
      />
      <MasterDataSalesTargetProgressChart :form="form" />
    </AppFormSection>
  </div>
</template>
