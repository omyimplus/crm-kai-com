<script setup lang="ts">
import type { CustomerCompanyAddressDraft, MasterCustomerFormInput } from '~/utils/masterCustomer'
import { applyIndividualCustomerTypeRules } from '~/utils/masterCustomer'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import {
  CUSTOMER_INDUSTRY_SEGMENTS,
  CUSTOMER_PAYMENT_CODES,
  CUSTOMER_SALES_GRADES,
  CUSTOMER_STATUSES,
  CUSTOMER_WHT_RATE_OPTIONS,
  CUSTOMER_TYPES,
  CUSTOMER_VAT_CURRENCIES,
  masterCustomerSectionThemes
} from '~/config/masterCustomer'
import { normalizeWebsiteUrl } from '~/utils/websiteUrl'

const props = withDefaults(defineProps<{
  modelValue: MasterCustomerFormInput
  billAddresses?: CustomerCompanyAddressDraft[]
  shipAddresses?: CustomerCompanyAddressDraft[]
  readonly?: boolean
  /** ซ่อนที่อยู่จัดส่ง — ใช้บนหน้าลีด (สร้างลูกค้าใหม่) */
  showShipTo?: boolean
}>(), {
  showShipTo: true
})

const emit = defineEmits<{
  'update:modelValue': [value: MasterCustomerFormInput]
  'update:billAddresses': [value: CustomerCompanyAddressDraft[]]
  'update:shipAddresses': [value: CustomerCompanyAddressDraft[]]
}>()

const { t } = useI18n()
const supabase = useSupabaseClient()
const { profile } = useProfile()

const form = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value)
})

const isIndividualCustomer = computed(() => form.value.customer_type === 'individual')

watch(
  () => form.value.customer_type,
  (type) => {
    if (type !== 'individual') return
    const next = applyIndividualCustomerTypeRules(form.value)
    if (
      next.industry_segment !== form.value.industry_segment
      || next.industry !== form.value.industry
    ) {
      form.value = next
    }
  }
)

const localBillAddresses = computed({
  get: () => props.billAddresses ?? [],
  set: value => emit('update:billAddresses', value)
})

const localShipAddresses = computed({
  get: () => props.shipAddresses ?? [],
  set: value => emit('update:shipAddresses', value)
})

const ownerOptions = ref<{ label: string, value: string | null }[]>([])

const customerTypeOptions = computed(() =>
  CUSTOMER_TYPES.map(value => ({
    value,
    label: t(`masterData.customer.options.customerType.${value}`)
  }))
)

const industrySegmentOptions = computed(() => [
  { value: null, label: t('masterData.customer.options.notSpecified') },
  ...CUSTOMER_INDUSTRY_SEGMENTS.map(value => ({
    value,
    label: t(`masterData.customer.options.industrySegment.${value}`)
  }))
])

const statusOptions = computed(() =>
  CUSTOMER_STATUSES.map(value => ({
    value,
    label: t(`masterData.customer.options.status.${value}`)
  }))
)

const salesGradeOptions = computed(() =>
  CUSTOMER_SALES_GRADES.map(value => ({
    value,
    label: t(`masterData.customer.options.salesGrade.${value}`)
  }))
)

const paymentCodeOptions = computed(() => [
  { value: null, label: t('masterData.customer.options.notSpecified') },
  ...CUSTOMER_PAYMENT_CODES.map(value => ({
    value,
    label: t(`masterData.customer.options.paymentCode.${value}`)
  }))
])

const whtRateOptions = computed(() => [
  { value: null, label: t('masterData.customer.options.notSpecified') },
  ...CUSTOMER_WHT_RATE_OPTIONS.map(value => ({
    value,
    label: t(`masterData.customer.options.whtRate.${value}`)
  }))
])

const vatCurrencyOptions = computed(() =>
  CUSTOMER_VAT_CURRENCIES.map(value => ({
    value,
    label: value
  }))
)

async function loadOwners() {
  if (!profile.value?.org_id) return
  const { data } = await supabase
    .from('profiles')
    .select('id, full_name')
    .eq('org_id', profile.value.org_id)
    .eq('is_active', true)
    .order('full_name')
  ownerOptions.value = [
    { value: null, label: t('masterData.customer.options.notSpecified') },
    ...((data ?? []) as { id: string, full_name: string | null }[]).map(row => ({
      value: row.id,
      label: row.full_name?.trim() || row.id
    }))
  ]
}

function normalizeWebsiteField() {
  const normalized = normalizeWebsiteUrl(form.value.website)
  if (normalized !== form.value.website) {
    form.value = { ...form.value, website: normalized }
  }
}

onMounted(() => {
  loadOwners()
})
</script>

<template>
  <div class="space-y-6">
    <AppFormSection
      :title="t('masterData.customer.sections.general')"
      :icon="masterCustomerSectionThemes.general.icon"
      :icon-class="masterCustomerSectionThemes.general.iconClass"
    >
      <div class="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-3">
        <UFormField
          :label="t('masterData.customer.fields.customerType')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.customer_type"
            :items="customerTypeOptions"
            value-key="value"
            :disabled="readonly"
            :class="appFormFieldClass"
            :placeholder="t('masterData.customer.fields.customerTypePlaceholder')"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.email')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.email"
            type="email"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.industrySegment')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.industry_segment"
            :items="industrySegmentOptions"
            value-key="value"
            size="lg"
            :placeholder="t('masterData.customer.fields.industrySegmentPlaceholder')"
            :disabled="readonly || isIndividualCustomer"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.companyName')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.name"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.phone')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.phone"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.owner')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.owner_id"
            :items="ownerOptions"
            value-key="value"
            size="lg"
            :placeholder="t('masterData.customer.fields.ownerPlaceholder')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.mobile')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.mobile"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.salesGrade')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.sales_grade"
            :items="salesGradeOptions"
            value-key="value"
            size="lg"
            :placeholder="t('masterData.customer.fields.salesGradePlaceholder')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.status')"
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
          :label="t('masterData.customer.fields.website')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.website"
            inputmode="url"
            autocomplete="url"
            :placeholder="t('masterData.customer.fields.websitePlaceholder')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
            @blur="normalizeWebsiteField"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.notes')"
          class="md:col-span-2 xl:col-span-3"
          :class="appFormFieldClass"
        >
          <UTextarea
            v-model="form.notes"
            :placeholder="t('masterData.customer.fields.notesPlaceholder')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appTextareaUi"
            :rows="3"
          />
        </UFormField>
      </div>
    </AppFormSection>

    <AppFormSection
      :title="t('masterData.customer.sections.tax')"
      :icon="masterCustomerSectionThemes.tax.icon"
      :icon-class="masterCustomerSectionThemes.tax.iconClass"
    >
      <div class="grid grid-cols-1 gap-5 md:grid-cols-2 xl:grid-cols-3">
        <!-- แถว 1: Tax ID · VAT Group · Credit Term -->
        <UFormField
          :label="t('masterData.customer.fields.taxId')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.tax_id"
            size="lg"
            :placeholder="t('masterData.customer.fields.taxIdPlaceholder')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.vatCurrency')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.vat_currency"
            :items="vatCurrencyOptions"
            value-key="value"
            size="lg"
            :placeholder="t('masterData.customer.fields.vatCurrencyPlaceholder')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.creditTermDays')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model.number="form.credit_term_days"
            type="number"
            min="0"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <!-- แถว 2: Tax Branch · Payment Code · WHT -->
        <UFormField
          :label="t('masterData.customer.fields.taxBranch')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.tax_branch"
            size="lg"
            :placeholder="t('masterData.customer.fields.taxBranchPlaceholder')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.paymentCode')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.payment_code"
            :items="paymentCodeOptions"
            value-key="value"
            size="lg"
            :placeholder="t('masterData.customer.options.notSpecified')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.whtRate')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.tax_vat"
            :items="whtRateOptions"
            value-key="value"
            size="lg"
            :placeholder="t('masterData.customer.fields.whtRatePlaceholder')"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <!-- แถว 3: Credit Limit · Credit Balance (ติดกัน) -->
        <UFormField
          :label="t('masterData.customer.fields.creditLimit')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model.number="form.credit_limit"
            type="number"
            min="0"
            step="0.01"
            size="lg"
            :disabled="readonly"
            class="text-right"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.customer.fields.creditBalance')"
          :class="appFormFieldClass"
        >
          <UInput
            :model-value="form.credit_balance.toFixed(2)"
            readonly
            disabled
            size="lg"
            class="text-right"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>
      </div>
    </AppFormSection>

    <AppFormSection
      :title="t('masterData.customer.sections.billTo')"
      :icon="masterCustomerSectionThemes.billTo.icon"
      :icon-class="masterCustomerSectionThemes.billTo.iconClass"
    >
      <MasterDataCustomerAddressList
        v-model="localBillAddresses"
        i18n-key="bill"
        :readonly="readonly"
      />
    </AppFormSection>

    <AppFormSection
      v-if="showShipTo"
      :title="t('masterData.customer.sections.shipTo')"
      :icon="masterCustomerSectionThemes.shipTo.icon"
      :icon-class="masterCustomerSectionThemes.shipTo.iconClass"
    >
      <MasterDataCustomerAddressList
        v-model="localShipAddresses"
        i18n-key="ship"
        :readonly="readonly"
      />
    </AppFormSection>
  </div>
</template>
