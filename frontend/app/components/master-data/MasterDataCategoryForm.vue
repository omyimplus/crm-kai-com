<script setup lang="ts">
import type { MasterCategoryFormInput } from '~/utils/masterCategory'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import {
  CATEGORY_STATUSES,
  masterCategorySectionThemes
} from '~/config/masterCategory'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'

const props = defineProps<{
  modelValue: MasterCategoryFormInput
  parentOptions: { label: string, value: string }[]
  readonly?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: MasterCategoryFormInput]
}>()

const { t } = useI18n()

const form = computed({
  get: () => props.modelValue,
  set: (value) => {
    emit('update:modelValue', {
      ...value,
      parent_id: normalizeSelectValue(value.parent_id),
      status: typeof value.status === 'string'
        ? value.status
        : normalizeSelectValue(value.status) ?? 'active'
    })
  }
})

const statusOptions = computed(() =>
  CATEGORY_STATUSES.map(value => ({
    value,
    label: t(`masterData.category.options.status.${value}`)
  }))
)

const parentSelectOptions = computed(() => [
  { value: null, label: t('masterData.category.fields.noParent') },
  ...props.parentOptions
])
</script>

<template>
  <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
    <AppFormSection
      :title="t('masterData.category.sections.basicInfo')"
      :icon="masterCategorySectionThemes.basicInfo.icon"
      :icon-class="masterCategorySectionThemes.basicInfo.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.category.fields.code')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.category_code"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.category.fields.name')"
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
          :label="t('masterData.category.fields.description')"
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

        <UFormField
          :label="t('masterData.category.fields.color')"
          :hint="t('masterData.category.fields.colorHint')"
          :class="appFormFieldClass"
        >
          <div class="flex items-center gap-3">
            <UInput
              v-model="form.color"
              size="lg"
              :disabled="readonly"
              :placeholder="t('masterData.category.fields.colorPlaceholder')"
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
          :label="t('masterData.category.fields.status')"
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
      </div>
    </AppFormSection>

    <AppFormSection
      :title="t('masterData.category.sections.hierarchy')"
      :icon="masterCategorySectionThemes.hierarchy.icon"
      :icon-class="masterCategorySectionThemes.hierarchy.iconClass"
    >
      <div class="space-y-5">
        <p class="rounded-xl border border-violet-200 bg-violet-50 px-4 py-3 text-sm text-violet-900 dark:border-violet-900/50 dark:bg-violet-950/30 dark:text-violet-200">
          {{ t('masterData.category.hierarchyHint') }}
        </p>

        <UFormField
          :label="t('masterData.category.fields.parent')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.parent_id"
            :items="parentSelectOptions"
            value-key="value"
            searchable
            size="lg"
            :disabled="readonly"
            :placeholder="t('masterData.category.fields.parentPlaceholder')"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.category.fields.sortOrder')"
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
          :label="t('masterData.category.fields.notes')"
          :class="appFormFieldClass"
        >
          <UTextarea
            v-model="form.notes"
            :rows="4"
            :disabled="readonly"
            :placeholder="t('masterData.category.fields.notesPlaceholder')"
            :class="appFormFieldClass"
            :ui="appTextareaUi"
          />
        </UFormField>
      </div>
    </AppFormSection>
  </div>
</template>
