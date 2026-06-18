<script setup lang="ts">
import type { MasterUnitFormInput } from '~/utils/masterUnit'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import { UNIT_STATUSES, masterUnitSectionThemes } from '~/config/masterUnit'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'

const props = defineProps<{
  modelValue: MasterUnitFormInput
  readonly?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: MasterUnitFormInput]
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
  UNIT_STATUSES.map(value => ({
    value,
    label: t(`masterData.unit.options.status.${value}`)
  }))
)
</script>

<template>
  <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
    <AppFormSection
      :title="t('masterData.unit.sections.basicInfo')"
      :icon="masterUnitSectionThemes.basicInfo.icon"
      :icon-class="masterUnitSectionThemes.basicInfo.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.unit.fields.code')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.unit_code"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.unit.fields.name')"
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
          :label="t('masterData.unit.fields.description')"
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
      :title="t('masterData.unit.sections.settings')"
      :icon="masterUnitSectionThemes.settings.icon"
      :icon-class="masterUnitSectionThemes.settings.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.unit.fields.sortOrder')"
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
          :label="t('masterData.unit.fields.status')"
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
          :label="t('masterData.unit.fields.notes')"
          :class="appFormFieldClass"
        >
          <UTextarea
            v-model="form.notes"
            :rows="4"
            :disabled="readonly"
            :placeholder="t('masterData.unit.fields.notesPlaceholder')"
            :class="appFormFieldClass"
            :ui="appTextareaUi"
          />
        </UFormField>
      </div>
    </AppFormSection>
  </div>
</template>
