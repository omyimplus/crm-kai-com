<script setup lang="ts">
import type { MasterPartnerFormInput } from '~/utils/masterPartner'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi
} from '~/config/appFormUi'
import {
  PARTNER_STATUSES,
  PARTNER_TIERS,
  PARTNER_TYPES,
  masterPartnerSectionThemes
} from '~/config/masterPartner'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'

const props = defineProps<{
  modelValue: MasterPartnerFormInput
  readonly?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: MasterPartnerFormInput]
}>()

const { t } = useI18n()

const form = computed({
  get: () => props.modelValue,
  set: (value) => {
    emit('update:modelValue', {
      ...value,
      partner_type: typeof value.partner_type === 'string'
        ? value.partner_type
        : normalizeSelectValue(value.partner_type) ?? 'distributor',
      tier: typeof value.tier === 'string'
        ? value.tier
        : normalizeSelectValue(value.tier) ?? 'silver',
      status: typeof value.status === 'string'
        ? value.status
        : normalizeSelectValue(value.status) ?? 'active'
    })
  }
})

const typeOptions = computed(() =>
  PARTNER_TYPES.map(value => ({
    value,
    label: t(`masterData.partner.options.type.${value}`)
  }))
)

const tierOptions = computed(() =>
  PARTNER_TIERS.map(value => ({
    value,
    label: t(`masterData.partner.options.tier.${value}`)
  }))
)

const statusOptions = computed(() =>
  PARTNER_STATUSES.map(value => ({
    value,
    label: t(`masterData.partner.options.status.${value}`)
  }))
)
</script>

<template>
  <div class="space-y-6">
    <AppFormSection
      :title="t('masterData.partner.sections.partnerInfo')"
      :icon="masterPartnerSectionThemes.partnerInfo.icon"
      :icon-class="masterPartnerSectionThemes.partnerInfo.iconClass"
    >
      <div class="grid grid-cols-1 gap-5 md:grid-cols-2">
        <UFormField
          :label="t('masterData.partner.fields.code')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.partner_code"
            size="lg"
            :placeholder="t('masterData.partner.fields.codePlaceholder')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.partner.fields.companyName')"
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
          :label="t('masterData.partner.fields.type')"
          required
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.partner_type"
            :items="typeOptions"
            value-key="value"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.partner.fields.tier')"
          required
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.tier"
            :items="tierOptions"
            value-key="value"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.partner.fields.status')"
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
          :label="t('masterData.partner.fields.partnerSince')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.partner_since"
            type="date"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>
      </div>
    </AppFormSection>

    <AppFormSection
      :title="t('masterData.partner.sections.contactDetails')"
      :icon="masterPartnerSectionThemes.contactDetails.icon"
      :icon-class="masterPartnerSectionThemes.contactDetails.iconClass"
    >
      <div class="grid grid-cols-1 gap-5 md:grid-cols-2">
        <UFormField
          :label="t('masterData.partner.fields.contactPerson')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.contact_person"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.partner.fields.email')"
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
          :label="t('masterData.partner.fields.phone')"
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
          :label="t('masterData.partner.fields.website')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.website"
            size="lg"
            :placeholder="t('masterData.partner.fields.websitePlaceholder')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.partner.fields.commissionRate')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model.number="form.commission_rate"
            type="number"
            min="0"
            max="100"
            step="0.01"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>
      </div>
    </AppFormSection>
  </div>
</template>
