<script setup lang="ts">
import type { MasterJobCodeFormInput } from '~/utils/masterJobCode'
import {
  appFormFieldClass,
  appFormSwitchBoxClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import {
  JOB_CODE_DATE_PARTS,
  JOB_CODE_DATE_STYLES,
  JOB_CODE_RECORD_STATUSES,
  JOB_CODE_RESET_RULES,
  JOB_CODE_SEGMENT_SEPARATORS,
  JOB_CODE_SEGMENTS,
  type JobCodeDatePart,
  type JobCodeModuleKey,
  type JobCodeSegment,
  masterJobCodeSectionThemes
} from '~/config/masterJobCode'
import {
  enabledJobCodeDatePartOrder,
  mergeJobCodeDatePartOrder,
  normalizeJobCodePrefixInput,
  previewMasterJobCode
} from '~/utils/masterJobCode'

const props = defineProps<{
  modelValue: MasterJobCodeFormInput
  readonly?: boolean
  lockModuleKey?: JobCodeModuleKey | null
}>()

const emit = defineEmits<{
  'update:modelValue': [value: MasterJobCodeFormInput]
}>()

const { t } = useI18n()

const form = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value)
})

const preview = computed(() => previewMasterJobCode(form.value))

const enabledDatePartCount = computed(() => enabledJobCodeDatePartOrder(form.value).length)

const visibleDatePartOrder = computed({
  get: () => enabledJobCodeDatePartOrder(form.value),
  set: (order: JobCodeDatePart[]) => {
    form.value = {
      ...form.value,
      date_part_order: mergeJobCodeDatePartOrder(form.value, order)
    }
  }
})

const separatorOptions = computed(() =>
  JOB_CODE_SEGMENT_SEPARATORS.map(value => ({
    value,
    label: value
  }))
)

const datePartLabels = computed(() =>
  Object.fromEntries(
    JOB_CODE_DATE_PARTS.map(part => [
      part,
      t(`masterData.jobCode.options.datePart.${part}`)
    ])
  ) as Record<JobCodeDatePart, string>
)

const segmentLabels = computed(() =>
  Object.fromEntries(
    JOB_CODE_SEGMENTS.map(part => [
      part,
      t(`masterData.jobCode.options.segment.${part}`)
    ])
  ) as Record<JobCodeSegment, string>
)

const dateStyleOptions = computed(() =>
  JOB_CODE_DATE_STYLES.map(value => ({
    value,
    label: t(`masterData.jobCode.options.dateStyle.${value}`)
  }))
)

const resetRuleOptions = computed(() =>
  JOB_CODE_RESET_RULES.map(value => ({
    value,
    label: t(`masterData.jobCode.options.resetRule.${value}`)
  }))
)

const recordStatusOptions = computed(() =>
  JOB_CODE_RECORD_STATUSES.map(value => ({
    value,
    label: t(`masterData.jobCode.options.recordStatus.${value}`)
  }))
)

function onPrefixInput(value: string) {
  form.value = {
    ...form.value,
    prefix: normalizeJobCodePrefixInput(value)
  }
}
</script>

<template>
  <div class="space-y-6">
    <UCard class="rounded-2xl border-primary/20 bg-primary/5">
      <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">
        {{ t('masterData.jobCode.previewLabel') }}
      </p>
      <p class="mt-2 font-mono text-xl font-semibold text-primary">
        {{ preview || '—' }}
      </p>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        {{ t('masterData.jobCode.previewHint') }}
      </p>
    </UCard>

    <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
      <AppFormSection
        :title="t('masterData.jobCode.sections.basicInfo')"
        :icon="masterJobCodeSectionThemes.basicInfo.icon"
        :icon-class="masterJobCodeSectionThemes.basicInfo.iconClass"
      >
        <div class="space-y-5">
          <UFormField
            v-if="lockModuleKey"
            :label="t('masterData.jobCode.fields.module')"
            :class="appFormFieldClass"
          >
            <UInput
              :model-value="t(`masterData.jobCode.options.module.${lockModuleKey}`)"
              size="lg"
              disabled
              :class="appFormFieldClass"
              :ui="appInputUi"
            />
          </UFormField>

          <UFormField
            :label="t('masterData.jobCode.fields.prefix')"
            required
            :class="appFormFieldClass"
          >
            <UInput
              :model-value="form.prefix"
              size="lg"
              :disabled="readonly"
              :placeholder="t('masterData.jobCode.fields.prefixPlaceholder')"
              autocomplete="off"
              spellcheck="false"
              maxlength="10"
              :class="appFormFieldClass"
              :ui="appInputUi"
              @update:model-value="onPrefixInput"
            />
            <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
              {{ t('masterData.jobCode.fields.prefixHint') }}
            </p>
          </UFormField>
        </div>
      </AppFormSection>

      <AppFormSection
        :title="t('masterData.jobCode.sections.dateSegment')"
        :icon="masterJobCodeSectionThemes.dateSegment.icon"
        :icon-class="masterJobCodeSectionThemes.dateSegment.iconClass"
      >
        <div class="space-y-5">
          <div :class="appFormSwitchBoxClass">
            <USwitch
              v-model="form.date_enabled"
              :disabled="readonly"
            />
            <span>{{ t('masterData.jobCode.fields.dateEnabled') }}</span>
          </div>

          <template v-if="form.date_enabled">
            <div class="grid gap-3 sm:grid-cols-3">
              <label class="flex items-center gap-2 text-sm">
                <UCheckbox
                  v-model="form.date_include_year"
                  :disabled="readonly"
                />
                {{ t('masterData.jobCode.fields.includeYear') }}
              </label>
              <label class="flex items-center gap-2 text-sm">
                <UCheckbox
                  v-model="form.date_include_month"
                  :disabled="readonly"
                />
                {{ t('masterData.jobCode.fields.includeMonth') }}
              </label>
              <label class="flex items-center gap-2 text-sm">
                <UCheckbox
                  v-model="form.date_include_day"
                  :disabled="readonly"
                />
                {{ t('masterData.jobCode.fields.includeDay') }}
              </label>
            </div>

            <UFormField
              :label="t('masterData.jobCode.fields.dateStyle')"
              :class="appFormFieldClass"
            >
              <USelectMenu
                v-model="form.date_style"
                :items="dateStyleOptions"
                value-key="value"
                size="lg"
                :disabled="readonly"
                :class="appFormFieldClass"
                :ui="appSelectMenuUi"
              />
            </UFormField>

            <div v-if="enabledDatePartCount >= 2">
              <p class="mb-2 text-sm font-medium">
                {{ t('masterData.jobCode.fields.datePartOrder') }}
              </p>
              <MasterDataAppOrderListEditor
                v-model="visibleDatePartOrder"
                :labels="datePartLabels"
                :disabled="readonly"
              />
            </div>
          </template>
        </div>
      </AppFormSection>

      <AppFormSection
        :title="t('masterData.jobCode.sections.numberSegment')"
        :icon="masterJobCodeSectionThemes.numberSegment.icon"
        :icon-class="masterJobCodeSectionThemes.numberSegment.iconClass"
      >
        <div class="space-y-5">
          <UFormField
            :label="t('masterData.jobCode.fields.padLength')"
            :class="appFormFieldClass"
          >
            <UInput
              v-model.number="form.pad_length"
              type="number"
              min="1"
              max="10"
              size="lg"
              :disabled="readonly"
              :class="appFormFieldClass"
              :ui="appInputUi"
            />
          </UFormField>

          <UFormField
            :label="t('masterData.jobCode.fields.startNumber')"
            :class="appFormFieldClass"
          >
            <UInput
              v-model.number="form.start_number"
              type="number"
              min="1"
              size="lg"
              :disabled="readonly"
              :class="appFormFieldClass"
              :ui="appInputUi"
            />
          </UFormField>

          <UFormField
            :label="t('masterData.jobCode.fields.resetRule')"
            :class="appFormFieldClass"
          >
            <USelectMenu
              v-model="form.reset_rule"
              :items="resetRuleOptions"
              value-key="value"
              size="lg"
              :disabled="readonly"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
            <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
              {{ t('masterData.jobCode.fields.resetRuleHint') }}
            </p>
          </UFormField>
        </div>
      </AppFormSection>

      <AppFormSection
        :title="t('masterData.jobCode.sections.layout')"
        :icon="masterJobCodeSectionThemes.layout.icon"
        :icon-class="masterJobCodeSectionThemes.layout.iconClass"
      >
        <div class="space-y-5">
          <div :class="appFormSwitchBoxClass">
            <USwitch
              v-model="form.separator_enabled"
              :disabled="readonly"
            />
            <span>{{ t('masterData.jobCode.fields.separatorEnabled') }}</span>
          </div>

          <UFormField
            v-if="form.separator_enabled"
            :label="t('masterData.jobCode.fields.segmentSeparator')"
            :class="appFormFieldClass"
          >
            <USelectMenu
              v-model="form.segment_separator"
              :items="separatorOptions"
              value-key="value"
              size="lg"
              :disabled="readonly"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
            <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
              {{ t('masterData.jobCode.fields.segmentSeparatorHint') }}
            </p>
          </UFormField>

          <div>
            <p class="mb-2 text-sm font-medium">
              {{ t('masterData.jobCode.fields.segmentOrder') }}
            </p>
            <MasterDataAppOrderListEditor
              v-model="form.segment_order"
              :labels="segmentLabels"
              :disabled="readonly"
            />
          </div>
        </div>
      </AppFormSection>

      <AppFormSection
        :title="t('masterData.jobCode.sections.settings')"
        :icon="masterJobCodeSectionThemes.settings.icon"
        :icon-class="masterJobCodeSectionThemes.settings.iconClass"
      >
        <div class="space-y-5">
          <UFormField
            :label="t('masterData.jobCode.fields.recordStatus')"
            :class="appFormFieldClass"
          >
            <USelectMenu
              v-model="form.status"
              :items="recordStatusOptions"
              value-key="value"
              size="lg"
              :disabled="readonly"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
          </UFormField>

          <UFormField
            :label="t('masterData.jobCode.fields.notes')"
            :class="appFormFieldClass"
          >
            <UTextarea
              v-model="form.notes"
              :rows="3"
              :disabled="readonly"
              :placeholder="t('masterData.jobCode.fields.notesPlaceholder')"
              :class="appFormFieldClass"
              :ui="appTextareaUi"
            />
          </UFormField>
        </div>
      </AppFormSection>
    </div>
  </div>
</template>
