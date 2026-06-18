<script setup lang="ts">
import type { MasterLeadSourceFormInput } from '~/utils/masterLeadSource'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import { LEAD_SOURCE_STATUSES, masterLeadSourceSectionThemes } from '~/config/masterLeadSource'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'

const props = defineProps<{
  modelValue: MasterLeadSourceFormInput
  readonly?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: MasterLeadSourceFormInput]
}>()

const { t } = useI18n()

const form = computed({
  get: () => props.modelValue,
  set: (value) => {
    emit('update:modelValue', {
      ...value,
      status: typeof value.status === 'string'
        ? value.status
        : normalizeSelectValue(value.status) ?? 'active'
    })
  }
})

const statusOptions = computed(() =>
  LEAD_SOURCE_STATUSES.map(value => ({
    value,
    label: t(`masterData.leadSource.options.status.${value}`)
  }))
)
</script>

<template>
  <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
    <AppFormSection
      :title="t('masterData.leadSource.sections.basicInfo')"
      :icon="masterLeadSourceSectionThemes.basicInfo.icon"
      :icon-class="masterLeadSourceSectionThemes.basicInfo.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.leadSource.fields.code')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.source_code"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.leadSource.fields.name')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.name"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.leadSource.fields.description')"
          :class="appFormFieldClass"
        >
          <UTextarea
            v-model="form.description"
            :rows="3"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appTextareaUi"
          />
        </UFormField>
      </div>
    </AppFormSection>

    <AppFormSection
      :title="t('masterData.leadSource.sections.settings')"
      :icon="masterLeadSourceSectionThemes.settings.icon"
      :icon-class="masterLeadSourceSectionThemes.settings.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.leadSource.fields.sortOrder')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model.number="form.sort_order"
            type="number"
            min="0"
            step="1"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.leadSource.fields.status')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.status"
            :items="statusOptions"
            value-key="value"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.leadSource.fields.notes')"
          :class="appFormFieldClass"
        >
          <UTextarea
            v-model="form.notes"
            :rows="4"
            :disabled="readonly"
            :placeholder="t('masterData.leadSource.fields.notesPlaceholder')"
            :class="appFormFieldClass"
            :ui="appTextareaUi"
          />
        </UFormField>
      </div>
    </AppFormSection>
  </div>
</template>
