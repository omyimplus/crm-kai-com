<script setup lang="ts">
import type { MasterContactFormInput } from '~/utils/masterContact'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import { CONTACT_ROLES, masterContactSectionThemes } from '~/config/masterContact'

const props = defineProps<{
  modelValue: MasterContactFormInput
  customerOptions: { label: string, value: string }[]
  readonly?: boolean
  /** ลูกค้าถูกกำหนดจากบริบท (เช่น หน้าดูลูกค้า) — ไม่แสดง select */
  fixedCustomerId?: string
  fixedCustomerName?: string
}>()

const emit = defineEmits<{
  'update:modelValue': [value: MasterContactFormInput]
}>()

const { t } = useI18n()

const form = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value)
})

const roleOptions = computed(() =>
  CONTACT_ROLES.map(value => ({
    value,
    label: t(`masterData.contact.options.role.${value}`)
  }))
)

const hasFixedCustomer = computed(() => Boolean(props.fixedCustomerId))

watch(
  () => props.fixedCustomerId,
  (customerId) => {
    if (customerId && form.value.company_id !== customerId) {
      form.value = { ...form.value, company_id: customerId }
    }
  },
  { immediate: true }
)
</script>

<template>
  <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
    <AppFormSection
      :title="t('masterData.contact.sections.contactInfo')"
      :icon="masterContactSectionThemes.contactInfo.icon"
      :icon-class="masterContactSectionThemes.contactInfo.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.contact.fields.firstName')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.first_name"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.contact.fields.lastName')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.last_name"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.contact.fields.email')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.email"
            type="email"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.contact.fields.phone')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.phone"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.contact.fields.mobile')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.mobile"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>
      </div>
    </AppFormSection>

    <AppFormSection
      :title="t('masterData.contact.sections.workDetails')"
      :icon="masterContactSectionThemes.workDetails.icon"
      :icon-class="masterContactSectionThemes.workDetails.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.contact.fields.customer')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-if="hasFixedCustomer"
            :model-value="fixedCustomerName || fixedCustomerId"
            size="lg"
            disabled
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
          <USelectMenu
            v-else
            v-model="form.company_id"
            :items="customerOptions"
            value-key="value"
            size="lg"
            searchable
            :placeholder="t('masterData.contact.fields.customerPlaceholder')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.contact.fields.jobTitle')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.job_title"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.contact.fields.department')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.department"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.contact.fields.role')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.contact_role"
            :items="roleOptions"
            value-key="value"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField :class="appFormFieldClass">
          <UCheckbox
            v-model="form.is_main_contact"
            :label="t('masterData.contact.fields.mainContact')"
            :disabled="readonly"
          />
          <p class="mt-1 text-xs text-muted">
            {{ t('masterData.contact.fields.mainContactHint') }}
          </p>
        </UFormField>

        <UFormField
          :label="t('masterData.contact.fields.notes')"
          :class="appFormFieldClass"
        >
          <UTextarea
            v-model="form.notes"
            :placeholder="t('masterData.contact.fields.notesPlaceholder')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appTextareaUi"
            :rows="3"
          />
        </UFormField>
      </div>
    </AppFormSection>
  </div>
</template>
