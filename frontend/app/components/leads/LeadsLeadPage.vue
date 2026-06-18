<script setup lang="ts">
import type { Company, LeadSource, ModuleStatus, TaskAssignee } from '~/types/crm'
import type { CustomerCompanyAddressDraft } from '~/utils/masterCustomer'
import {
  defaultMasterCustomerFormInput,
  formToCompanyPayload,
  validateMasterCustomerForm
} from '~/utils/masterCustomer'
import { appFormErrorClass } from '~/config/appFormUi'
import type { LeadCustomerMode } from '~/utils/masterLeads'
import {
  defaultLeadFormInput,
  leadSnapshotBillAddresses,
  leadSnapshotToCustomerForm,
  leadToFormInput,
  syncLeadFieldsFromCustomer,
  validateLeadCustomerMode,
  validateLeadForm
} from '~/utils/masterLeads'
import { resolveDefaultModuleStatus } from '~/utils/masterTasks'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

const props = defineProps<{
  mode: 'new' | 'edit'
  leadId?: string | null
}>()

const { t } = useI18n()
const { profile } = useProfile()
const { create: createLead, update, list, ensureDefaults } = useLeads()
const { listByModule } = useModuleStatuses()
const { listAssignees } = useTasks()
const {
  list: listCompanies,
  create: createCompany,
  syncBillAddresses
} = useCompanies()
const { list: listLeadSources } = useLeadSources()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultLeadFormInput())
const leadCode = ref<string | null>(null)
const statuses = ref<ModuleStatus[]>([])
const assignees = ref<TaskAssignee[]>([])
const companies = ref<Company[]>([])
const leadSources = ref<LeadSource[]>([])
const customerMode = ref<LeadCustomerMode>('existing')
const selectedCompanyId = ref<string | null>(null)
const customerForm = ref(defaultMasterCustomerFormInput())
const billAddresses = ref<CustomerCompanyAddressDraft[]>([])
const customerSyncReady = ref(false)
const lockCustomerMode = ref(false)

const isEdit = computed(() => props.mode === 'edit')

const pageTitle = computed(() =>
  isEdit.value ? t('leads.editTitle') : t('leads.createTitle')
)
const pageSubtitle = computed(() =>
  isEdit.value ? t('leads.editSubtitle') : t('leads.createSubtitle')
)

try {
  await ensureDefaults()
  const [statusRows, assigneeRows, companyRows, sourceRows] = await Promise.all([
    listByModule('lead'),
    listAssignees(),
    listCompanies(),
    listLeadSources()
  ])
  statuses.value = statusRows
  assignees.value = assigneeRows
  companies.value = companyRows
  leadSources.value = sourceRows.filter(row => row.status === 'active')

  if (isEdit.value && props.leadId) {
    const rows = await list()
    const row = rows.find(item => item.id === props.leadId)
    if (!row) {
      await navigateTo('/app/leads')
    } else {
      form.value = leadToFormInput(row)
      leadCode.value = row.lead_code

      if (row.company_id) {
        customerMode.value = 'existing'
        selectedCompanyId.value = row.company_id
        lockCustomerMode.value = true
      } else {
        customerMode.value = 'new'
        customerForm.value = leadSnapshotToCustomerForm(row)
        billAddresses.value = leadSnapshotBillAddresses(row)
      }
    }
  } else {
    form.value.module_status_id = resolveDefaultModuleStatus(statusRows)?.id ?? null
    form.value.owner_id = profile.value?.id ?? null
  }

  customerSyncReady.value = true
} catch (error) {
  console.error(error)
}

async function resolveCompanyId(): Promise<string> {
  if (customerMode.value === 'existing') {
    if (!selectedCompanyId.value) {
      throw new Error('customerRequired')
    }
    return selectedCompanyId.value
  }

  const validationKey = validateMasterCustomerForm(customerForm.value)
  if (validationKey) {
    throw new Error(`masterData.customer.validation.${validationKey}`)
  }

  const payload = formToCompanyPayload(customerForm.value, billAddresses.value)
  const company = await createCompany(payload)
  await syncBillAddresses(company.id, billAddresses.value)
  companies.value = await listCompanies()
  selectedCompanyId.value = company.id
  return company.id
}

async function save() {
  errorMsg.value = ''

  const customerModeError = validateLeadCustomerMode(customerMode.value, selectedCompanyId.value)
  if (customerModeError) {
    errorMsg.value = t(`leads.validation.${customerModeError}`)
    return
  }

  saving.value = true
  try {
    const companyId = await resolveCompanyId()
    const payload = syncLeadFieldsFromCustomer(
      form.value,
      customerForm.value,
      companyId,
      billAddresses.value
    )

    const validationKey = validateLeadForm(payload)
    if (validationKey) {
      errorMsg.value = t(`leads.validation.${validationKey}`)
      return
    }

    if (isEdit.value && props.leadId) {
      await update(props.leadId, payload)
      await navigateTo(`/app/leads/${props.leadId}`)
    } else {
      const row = await createLead(payload)
      await navigateTo(`/app/leads/${row.id}`)
    }
  } catch (error) {
    if (error instanceof Error && error.message.startsWith('masterData.customer.validation.')) {
      errorMsg.value = t(error.message)
      return
    }
    if (error instanceof Error && error.message === 'customerRequired') {
      errorMsg.value = t('leads.validation.customerRequired')
      return
    }
    errorMsg.value = getSupabaseErrorMessage(error, t('leads.errors.saveFailed'))
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div>
    <UButton
      :to="isEdit && leadId ? `/app/leads/${leadId}` : '/app/leads'"
      variant="ghost"
      color="neutral"
      icon="i-lucide-arrow-left"
      size="sm"
      class="mb-4"
    >
      {{ t('common.back') }}
    </UButton>

    <form
      class="lg:grid lg:grid-cols-[minmax(0,1fr)_17rem] lg:items-start lg:gap-6"
      @submit.prevent="save"
    >
      <div class="min-w-0 space-y-6">
        <div>
          <h1 class="text-2xl font-bold font-heading">
            {{ pageTitle }}
          </h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ pageSubtitle }}
          </p>
        </div>

        <p
          v-if="errorMsg"
          :class="appFormErrorClass"
          role="alert"
        >
          {{ errorMsg }}
        </p>

        <LeadsForm
          v-model="form"
          :statuses="statuses"
          :assignees="assignees"
          :lead-sources="leadSources"
          :lead-code="leadCode"
        >
          <LeadsCustomerSection
            v-model:mode="customerMode"
            v-model:company-id="selectedCompanyId"
            v-model:customer-form="customerForm"
            v-model:bill-addresses="billAddresses"
            :companies="companies"
            :lock-mode="lockCustomerMode"
            :enable-sync="customerSyncReady"
          />
        </LeadsForm>
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard>
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            {{ t('leads.actions') }}
          </p>
          <UButton
            type="submit"
            color="primary"
            size="lg"
            class="w-full justify-center"
            icon="i-lucide-check"
            :loading="saving"
          >
            {{ isEdit ? t('leads.save') : t('leads.create') }}
          </UButton>
        </UCard>
      </aside>
    </form>
  </div>
</template>
