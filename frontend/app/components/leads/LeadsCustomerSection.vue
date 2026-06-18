<script setup lang="ts">
import type { Company } from '~/types/crm'
import type { CustomerCompanyAddressDraft, MasterCustomerFormInput } from '~/utils/masterCustomer'
import {
  companyToFormInput,
  defaultMasterCustomerFormInput
} from '~/utils/masterCustomer'
import { appFormFieldClass, appFormHintClass, appSelectMenuUi } from '~/config/appFormUi'
import { leadsSectionThemes } from '~/config/masterLeads'
import type { LeadCustomerMode } from '~/utils/masterLeads'

const mode = defineModel<LeadCustomerMode>('mode', { required: true })
const companyId = defineModel<string | null>('companyId', { required: true })
const customerForm = defineModel<MasterCustomerFormInput>('customerForm', { required: true })
const billAddresses = defineModel<CustomerCompanyAddressDraft[]>('billAddresses', { required: true })

const props = defineProps<{
  companies: Company[]
  lockMode?: boolean
  enableSync?: boolean
  readonly?: boolean
}>()

const { t } = useI18n()
const { get } = useCompanies()

const loading = ref(false)

const companyOptions = computed(() =>
  props.companies.map(company => ({
    label: company.name,
    value: company.id
  }))
)

const customerEditPath = computed(() =>
  companyId.value ? `/app/customer/${companyId.value}/edit` : null
)

const customerTypeLabel = computed(() => {
  const type = customerForm.value.customer_type
  return type
    ? t(`masterData.customer.options.customerType.${type}`)
    : t('leads.none')
})

const industrySegmentLabel = computed(() => {
  const segment = customerForm.value.industry_segment
  return segment
    ? t(`masterData.customer.options.industrySegment.${segment}`)
    : t('masterData.customer.options.notSpecified')
})

const salesGradeLabel = computed(() => {
  const grade = customerForm.value.sales_grade
  return grade
    ? t(`masterData.customer.options.salesGrade.${grade}`)
    : t('masterData.customer.options.notSpecified')
})

function setMode(next: LeadCustomerMode) {
  if (props.lockMode || mode.value === next) return
  mode.value = next
  if (next === 'new') {
    companyId.value = null
    customerForm.value = defaultMasterCustomerFormInput()
    billAddresses.value = []
    return
  }
  customerForm.value = defaultMasterCustomerFormInput()
  billAddresses.value = []
}

async function loadExistingCompany(id: string) {
  loading.value = true
  try {
    const row = await get(id)
    customerForm.value = companyToFormInput(row)
  } catch (error) {
    console.error(error)
    companyId.value = null
    customerForm.value = defaultMasterCustomerFormInput()
  } finally {
    loading.value = false
  }
}

watch(
  () => [props.enableSync, mode.value, companyId.value] as const,
  async ([enabled, currentMode, id]) => {
    if (!enabled || currentMode !== 'existing' || !id) return
    await loadExistingCompany(id)
  },
  { immediate: true }
)
</script>

<template>
  <AppFormSection
    :title="t('leads.sections.customer')"
    :icon="leadsSectionThemes.customer.icon"
    :icon-class="leadsSectionThemes.customer.iconClass"
  >
    <div class="space-y-5">
      <UFormField
        v-if="!readonly"
        :label="t('leads.fields.customerMode')"
        :hint="t('leads.fields.customerModeHint')"
      >
        <div
          class="inline-flex rounded-lg border border-gray-200 p-1 dark:border-gray-700"
          role="group"
          :aria-label="t('leads.fields.customerMode')"
        >
          <UButton
            type="button"
            size="sm"
            :variant="mode === 'existing' ? 'solid' : 'outline'"
            :disabled="lockMode && mode !== 'existing'"
            @click="setMode('existing')"
          >
            {{ t('leads.options.customerMode.existing') }}
          </UButton>
          <UButton
            type="button"
            size="sm"
            :variant="mode === 'new' ? 'solid' : 'outline'"
            :disabled="lockMode && mode !== 'new'"
            @click="setMode('new')"
          >
            {{ t('leads.options.customerMode.new') }}
          </UButton>
        </div>
      </UFormField>

      <UFormField
        v-if="mode === 'existing' && !readonly"
        :label="t('leads.fields.companySearch')"
        :hint="t('leads.fields.companySearchHint')"
        required
      >
        <USelectMenu
          v-model="companyId"
          size="lg"
          searchable
          :items="companyOptions"
          value-key="value"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
          :placeholder="t('leads.fields.companySearchPlaceholder')"
        />
      </UFormField>

      <p
        v-if="mode === 'existing' && !readonly && !companyId"
        class="text-sm text-gray-500 dark:text-gray-400"
        :class="appFormHintClass"
      >
        {{ t('leads.fields.companySearchEmpty') }}
      </p>

      <div
        v-else-if="loading"
        class="py-6 text-center text-sm text-gray-500 dark:text-gray-400"
      >
        {{ t('common.loading') }}
      </div>

      <template v-else-if="mode === 'existing' && companyId">
        <div class="rounded-lg border border-gray-200 bg-gray-50/80 p-4 dark:border-gray-700 dark:bg-gray-900/40">
          <p class="text-base font-semibold text-gray-900 dark:text-gray-100">
            {{ customerForm.name || t('leads.emptyCell') }}
          </p>
          <dl class="mt-3 grid grid-cols-1 gap-2 text-sm sm:grid-cols-2">
            <div>
              <dt class="text-gray-500 dark:text-gray-400">
                {{ t('masterData.customer.fields.customerType') }}
              </dt>
              <dd class="font-medium text-gray-900 dark:text-gray-100">
                {{ customerTypeLabel }}
              </dd>
            </div>
            <div>
              <dt class="text-gray-500 dark:text-gray-400">
                {{ t('masterData.customer.fields.industrySegment') }}
              </dt>
              <dd class="font-medium text-gray-900 dark:text-gray-100">
                {{ industrySegmentLabel }}
              </dd>
            </div>
            <div>
              <dt class="text-gray-500 dark:text-gray-400">
                {{ t('masterData.customer.fields.salesGrade') }}
              </dt>
              <dd class="font-medium text-gray-900 dark:text-gray-100">
                {{ salesGradeLabel }}
              </dd>
            </div>
            <div v-if="customerForm.email">
              <dt class="text-gray-500 dark:text-gray-400">
                {{ t('masterData.customer.fields.email') }}
              </dt>
              <dd class="font-medium text-gray-900 dark:text-gray-100">
                {{ customerForm.email }}
              </dd>
            </div>
            <div v-if="customerForm.phone">
              <dt class="text-gray-500 dark:text-gray-400">
                {{ t('masterData.customer.fields.phone') }}
              </dt>
              <dd class="font-medium text-gray-900 dark:text-gray-100">
                {{ customerForm.phone }}
              </dd>
            </div>
            <div v-if="customerForm.mobile">
              <dt class="text-gray-500 dark:text-gray-400">
                {{ t('masterData.customer.fields.mobile') }}
              </dt>
              <dd class="font-medium text-gray-900 dark:text-gray-100">
                {{ customerForm.mobile }}
              </dd>
            </div>
          </dl>
          <p class="mt-3 text-sm text-gray-500 dark:text-gray-400">
            {{ t('leads.fields.customerSummaryHint') }}
          </p>
          <UButton
            v-if="customerEditPath && !readonly"
            :to="customerEditPath"
            variant="outline"
            color="neutral"
            size="sm"
            icon="i-lucide-external-link"
            class="mt-4"
          >
            {{ t('leads.fields.editCustomerDetails') }}
          </UButton>
        </div>
      </template>

      <template v-else-if="mode === 'new'">
        <p
          class="text-sm text-gray-500 dark:text-gray-400"
          :class="appFormHintClass"
        >
          {{ t('leads.fields.customerNewFormHint') }}
        </p>
        <MasterDataCustomerForm
          v-model="customerForm"
          v-model:bill-addresses="billAddresses"
          :show-ship-to="false"
          :readonly="readonly"
        />
      </template>
    </div>
  </AppFormSection>
</template>
