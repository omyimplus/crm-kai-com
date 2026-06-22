<script setup lang="ts">
import type { Category, OpportunityProjectDraft } from '~/types/crm'
import {
  OPPORTUNITY_PROJECT_SUB_TYPES,
  OPPORTUNITY_PROJECT_TYPES
} from '~/config/masterOpportunities'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi
} from '~/config/appFormUi'
import { productCategoryOptions } from '~/utils/masterProduct'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'

const project = defineModel<OpportunityProjectDraft>({ required: true })

const props = withDefaults(defineProps<{
  index: number
  categories?: Category[]
  readonly?: boolean
}>(), {
  categories: () => [],
  readonly: false
})

const emit = defineEmits<{
  remove: []
}>()

const { t } = useI18n()

const noneOption = computed(() => ({
  label: t('opportunities.none'),
  value: null as string | null
}))

function enumOptions(values: readonly string[], i18nPrefix: string) {
  return values.map(value => ({
    label: t(`${i18nPrefix}.${value}`),
    value
  }))
}

function withLegacyOption(
  options: { label: string, value: string | null }[],
  current: string | null
) {
  const trimmed = current?.trim() ?? ''
  if (!trimmed || options.some(option => option.value === trimmed)) {
    return options
  }
  return [{ label: trimmed, value: trimmed }, ...options]
}

const projectTypeOptions = computed(() =>
  withLegacyOption(
    [noneOption.value, ...enumOptions(OPPORTUNITY_PROJECT_TYPES, 'opportunities.options.projectType')],
    project.value.project_type
  )
)

const projectSubTypeOptions = computed(() =>
  withLegacyOption(
    [noneOption.value, ...enumOptions(OPPORTUNITY_PROJECT_SUB_TYPES, 'opportunities.options.projectSubType')],
    project.value.project_sub_type
  )
)

const productGroupOptions = computed(() =>
  withLegacyOption(
    [noneOption.value, ...productCategoryOptions(props.categories)],
    project.value.products_group
  )
)

function setProjectType(value: unknown) {
  project.value = {
    ...project.value,
    project_type: normalizeSelectValue(value)
  }
}

function setProjectSubType(value: unknown) {
  project.value = {
    ...project.value,
    project_sub_type: normalizeSelectValue(value)
  }
}

function setProductsGroup(value: unknown) {
  project.value = {
    ...project.value,
    products_group: normalizeSelectValue(value)
  }
}
</script>

<template>
  <div class="rounded-2xl border border-gray-200 p-4 dark:border-gray-800">
    <div class="mb-4 flex items-start justify-between gap-3">
      <p class="text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
        {{ t('opportunities.projects.itemLabel', { index: index + 1 }) }}
      </p>
      <UButton
        v-if="!readonly"
        variant="ghost"
        color="error"
        icon="i-lucide-trash-2"
        size="xs"
        :aria-label="t('common.delete')"
        @click="emit('remove')"
      />
    </div>

    <div class="grid gap-4 md:grid-cols-2">
      <UFormField :label="t('opportunities.fields.projectName')">
        <UInput
          v-model="project.project_name"
          :readonly="readonly"
          :class="appFormFieldClass"
          :ui="appInputUi"
          :placeholder="t('opportunities.fields.projectNamePlaceholder')"
        />
      </UFormField>

      <UFormField :label="t('opportunities.fields.projectType')">
        <USelectMenu
          :model-value="project.project_type"
          :items="projectTypeOptions"
          value-key="value"
          :disabled="readonly"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
          :placeholder="t('opportunities.fields.projectTypePlaceholder')"
          @update:model-value="setProjectType"
        />
      </UFormField>

      <UFormField :label="t('opportunities.fields.projectSubType')">
        <USelectMenu
          :model-value="project.project_sub_type"
          :items="projectSubTypeOptions"
          value-key="value"
          :disabled="readonly"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
          :placeholder="t('opportunities.fields.projectSubTypePlaceholder')"
          @update:model-value="setProjectSubType"
        />
      </UFormField>

      <UFormField :label="t('opportunities.fields.productsGroup')">
        <USelectMenu
          :model-value="project.products_group"
          :items="productGroupOptions"
          value-key="value"
          searchable
          :disabled="readonly"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
          :placeholder="t('opportunities.fields.productsGroupPlaceholder')"
          @update:model-value="setProductsGroup"
        />
      </UFormField>

      <UFormField :label="t('opportunities.fields.estimatedValue')">
        <UInput
          v-model="project.estimated_value"
          type="number"
          min="0"
          step="0.01"
          :readonly="readonly"
          :class="appFormFieldClass"
          :ui="appInputUi"
        />
      </UFormField>

      <UFormField :label="t('opportunities.fields.projectCosts')">
        <UInput
          v-model="project.project_costs"
          type="number"
          min="0"
          step="0.01"
          :readonly="readonly"
          :class="appFormFieldClass"
          :ui="appInputUi"
        />
      </UFormField>
    </div>
  </div>
</template>
