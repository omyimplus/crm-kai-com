<script setup lang="ts">
import type { MasterProductFormInput } from '~/utils/masterProduct'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import {
  PRODUCT_CURRENCIES,
  PRODUCT_STATUSES,
  masterProductSectionThemes
} from '~/config/masterProduct'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'

const props = defineProps<{
  modelValue: MasterProductFormInput
  categoryOptions: { label: string, value: string }[]
  unitOptions: { label: string, value: string }[]
  readonly?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: MasterProductFormInput]
  'create-category': []
  'create-unit': []
}>()

const { t } = useI18n()

const form = computed({
  get: () => props.modelValue,
  set: (value) => {
    emit('update:modelValue', {
      ...value,
      category_id: normalizeSelectValue(value.category_id),
      unit_id: normalizeSelectValue(value.unit_id)
    })
  }
})

const statusOptions = computed(() =>
  PRODUCT_STATUSES.map(value => ({
    value,
    label: t(`masterData.products.options.status.${value}`)
  }))
)

const currencyOptions = computed(() =>
  PRODUCT_CURRENCIES.map(value => ({
    value,
    label: value
  }))
)

const categorySelectOptions = computed(() => [
  { value: null, label: t('masterData.products.fields.noCategory') },
  ...props.categoryOptions
])

const unitSelectOptions = computed(() => [
  { value: null, label: t('masterData.products.fields.noUnit') },
  ...props.unitOptions
])
</script>

<template>
  <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
    <AppFormSection
      :title="t('masterData.products.sections.basicInfo')"
      :icon="masterProductSectionThemes.basicInfo.icon"
      :icon-class="masterProductSectionThemes.basicInfo.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.products.fields.code')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.product_code"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.products.fields.name')"
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
          :label="t('masterData.products.fields.description')"
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
          :label="t('masterData.products.fields.category')"
          :class="appFormFieldClass"
        >
          <div class="flex items-start gap-2">
            <USelectMenu
              v-model="form.category_id"
              :items="categorySelectOptions"
              value-key="value"
              searchable
              size="lg"
              :disabled="readonly"
              :placeholder="t('masterData.products.fields.categoryPlaceholder')"
              class="min-w-0 flex-1"
              :ui="appSelectMenuUi"
            />
            <AppIconButton
              v-if="!readonly"
              icon="i-lucide-plus"
              variant="outline"
              size="sm"
              class="mt-0.5 shrink-0"
              :aria-label="t('masterData.products.createCategoryButton')"
              @click="emit('create-category')"
            />
          </div>
        </UFormField>

        <UFormField
          :label="t('masterData.products.fields.unit')"
          :class="appFormFieldClass"
        >
          <div class="flex items-start gap-2">
            <USelectMenu
              v-model="form.unit_id"
              :items="unitSelectOptions"
              value-key="value"
              searchable
              size="lg"
              :disabled="readonly"
              :placeholder="t('masterData.products.fields.unitPlaceholder')"
              class="min-w-0 flex-1"
              :ui="appSelectMenuUi"
            />
            <AppIconButton
              v-if="!readonly"
              icon="i-lucide-plus"
              variant="outline"
              size="sm"
              class="mt-0.5 shrink-0"
              :aria-label="t('masterData.products.createUnitButton')"
              @click="emit('create-unit')"
            />
          </div>
        </UFormField>
      </div>
    </AppFormSection>

    <AppFormSection
      :title="t('masterData.products.sections.pricing')"
      :icon="masterProductSectionThemes.pricing.icon"
      :icon-class="masterProductSectionThemes.pricing.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.products.fields.listPrice')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model.number="form.list_price"
            type="number"
            min="0"
            step="0.01"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.products.fields.costPrice')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model.number="form.cost_price"
            type="number"
            min="0"
            step="0.01"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.products.fields.currency')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.currency"
            :items="currencyOptions"
            value-key="value"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.products.fields.barcode')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.barcode"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.products.fields.status')"
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

        <UFormField :class="appFormFieldClass">
          <UCheckbox
            v-model="form.is_sellable"
            :disabled="readonly"
            :label="t('masterData.products.fields.isSellable')"
          />
        </UFormField>
      </div>
    </AppFormSection>

    <div class="xl:col-span-2">
      <UFormField
        :label="t('masterData.products.fields.notes')"
        :class="appFormFieldClass"
      >
        <UTextarea
          v-model="form.notes"
          :rows="3"
          :disabled="readonly"
          :placeholder="t('masterData.products.fields.notesPlaceholder')"
          :class="appFormFieldClass"
          :ui="appTextareaUi"
        />
      </UFormField>
    </div>

    <div
      v-if="$slots.gallery"
      class="xl:col-span-2"
    >
      <slot name="gallery" />
    </div>
  </div>
</template>
