<script setup lang="ts">
import type { MasterModuleStatusFormInput } from '~/utils/masterModuleStatus'
import {
  appFormErrorClass,
  appFormFieldClass,
  appFormHintClass,
  appFormSwitchBoxClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import {
  MODULE_STATUS_MODULE_KEYS,
  MODULE_STATUS_RECORD_STATUSES,
  type ModuleStatusModuleKey,
  masterModuleStatusSectionThemes
} from '~/config/masterModuleStatus'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'
import {
  MODULE_STATUS_CODE_MAX_LENGTH,
  MODULE_STATUS_CODE_MIN_LENGTH,
  moduleStatusCodeValidationKey,
  normalizeModuleStatusCodeInput,
  validateModuleStatusCode
} from '~/utils/moduleStatusCode'

const props = defineProps<{
  modelValue: MasterModuleStatusFormInput
  readonly?: boolean
  lockModuleKey?: ModuleStatusModuleKey | null
}>()

const emit = defineEmits<{
  'update:modelValue': [value: MasterModuleStatusFormInput]
}>()

const { t } = useI18n()

const form = computed({
  get: () => props.modelValue,
  set: (value) => {
    emit('update:modelValue', {
      ...value,
      module_key: normalizeSelectValue(value.module_key) as MasterModuleStatusFormInput['module_key'],
      status: typeof value.status === 'string'
        ? value.status
        : normalizeSelectValue(value.status) ?? 'active'
    })
  }
})

const moduleOptions = computed(() =>
  MODULE_STATUS_MODULE_KEYS.map(value => ({
    value,
    label: t(`masterData.moduleStatuses.options.module.${value}`)
  }))
)

const recordStatusOptions = computed(() =>
  MODULE_STATUS_RECORD_STATUSES.map(value => ({
    value,
    label: t(`masterData.moduleStatuses.options.recordStatus.${value}`)
  }))
)

const codeTouched = ref(false)

const codeValidation = computed(() => validateModuleStatusCode(form.value.status_code))

const codeFieldError = computed(() => {
  if (props.readonly || !codeTouched.value || codeValidation.value.ok) {
    return ''
  }
  const key = moduleStatusCodeValidationKey(codeValidation.value.errorId!)
  if (key === 'codeTooShort') {
    return t('masterData.moduleStatuses.validation.codeTooShort', { min: MODULE_STATUS_CODE_MIN_LENGTH })
  }
  if (key === 'codeTooLong') {
    return t('masterData.moduleStatuses.validation.codeTooLong', { max: MODULE_STATUS_CODE_MAX_LENGTH })
  }
  return t(`masterData.moduleStatuses.validation.${key}`)
})

function onStatusCodeInput(value: string) {
  form.value = {
    ...form.value,
    status_code: normalizeModuleStatusCodeInput(value)
  }
}
</script>

<template>
  <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
    <AppFormSection
      :title="t('masterData.moduleStatuses.sections.basicInfo')"
      :icon="masterModuleStatusSectionThemes.basicInfo.icon"
      :icon-class="masterModuleStatusSectionThemes.basicInfo.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.moduleStatuses.fields.module')"
          required
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.module_key"
            :items="moduleOptions"
            value-key="value"
            searchable
            size="lg"
            :disabled="readonly || Boolean(lockModuleKey)"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
          <p
            v-if="lockModuleKey && !readonly"
            class="mt-2 text-sm text-gray-500 dark:text-gray-400"
          >
            {{ t('masterData.moduleStatuses.fields.moduleLockedHint') }}
          </p>
        </UFormField>

        <UFormField
          :label="t('masterData.moduleStatuses.fields.code')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            :model-value="form.status_code"
            size="lg"
            :disabled="readonly"
            :placeholder="t('masterData.moduleStatuses.fields.codePlaceholder')"
            autocomplete="off"
            spellcheck="false"
            :maxlength="MODULE_STATUS_CODE_MAX_LENGTH"
            :class="appFormFieldClass"
            :ui="appInputUi"
            @update:model-value="onStatusCodeInput"
            @blur="codeTouched = true"
          />
          <p
            v-if="codeFieldError"
            :class="appFormErrorClass"
          >
            {{ codeFieldError }}
          </p>
          <p
            v-else
            :class="appFormHintClass"
          >
            {{ t('masterData.moduleStatuses.fields.codeHint') }}
          </p>
        </UFormField>

        <UFormField
          :label="t('masterData.moduleStatuses.fields.name')"
          required
          :hint="t('masterData.moduleStatuses.fields.nameHint')"
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
          :label="t('masterData.moduleStatuses.fields.description')"
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
      :title="t('masterData.moduleStatuses.sections.settings')"
      :icon="masterModuleStatusSectionThemes.settings.icon"
      :icon-class="masterModuleStatusSectionThemes.settings.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.moduleStatuses.fields.sortOrder')"
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
          :label="t('masterData.moduleStatuses.fields.color')"
          :hint="t('masterData.moduleStatuses.fields.colorHint')"
          :class="appFormFieldClass"
        >
          <div class="flex items-center gap-3">
            <UInput
              v-model="form.color"
              size="lg"
              :disabled="readonly"
              :placeholder="t('masterData.moduleStatuses.fields.colorPlaceholder')"
              :class="appFormFieldClass"
              :ui="appInputUi"
            />
            <span
              v-if="form.color"
              class="inline-block size-9 shrink-0 rounded-lg border border-gray-200 dark:border-gray-700"
              :style="{ backgroundColor: form.color }"
            />
          </div>
        </UFormField>

        <UFormField
          :label="t('masterData.moduleStatuses.fields.isDefault')"
          :hint="t('masterData.moduleStatuses.fields.isDefaultHint')"
          :class="appFormFieldClass"
        >
          <div :class="appFormSwitchBoxClass">
            <USwitch
              v-model="form.is_default"
              :disabled="readonly"
            />
            <span class="text-sm text-gray-600 dark:text-gray-400">
              {{ t('masterData.moduleStatuses.fields.isDefaultLabel') }}
            </span>
          </div>
        </UFormField>

        <UFormField
          :label="t('masterData.moduleStatuses.fields.recordStatus')"
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
          :label="t('masterData.moduleStatuses.fields.notes')"
          :class="appFormFieldClass"
        >
          <UTextarea
            v-model="form.notes"
            :rows="4"
            :disabled="readonly"
            :placeholder="t('masterData.moduleStatuses.fields.notesPlaceholder')"
            :class="appFormFieldClass"
            :ui="appTextareaUi"
          />
        </UFormField>
      </div>
    </AppFormSection>
  </div>
</template>
