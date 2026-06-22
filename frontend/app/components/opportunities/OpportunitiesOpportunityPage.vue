<script setup lang="ts">
import type { Category, Company, Lead, OpportunityLineItemDraft, PipelineStage, Product, SalesTeam, Service, TaskAssignee } from '~/types/crm'
import type { CustomerCompanyAddressDraft, MasterCustomerFormInput } from '~/utils/masterCustomer'
import { appFormErrorClass } from '~/config/appFormUi'
import {
  defaultMasterCustomerFormInput,
  formToCompanyPayload,
  validateMasterCustomerForm
} from '~/utils/masterCustomer'
import type { LeadCustomerMode } from '~/utils/masterLeads'
import { validateLeadCustomerMode } from '~/utils/masterLeads'
import {
  defaultOpportunityFormInput,
  leadToOpportunityPrefill,
  opportunityToFormInput,
  validateOpportunityForm,
  canConvertLead
} from '~/utils/masterOpportunities'
import {
  defaultOpportunityLineItemDraft,
  opportunityLineItemsToDrafts
} from '~/utils/masterOpportunityLineItems'
import { SERVICE_CATEGORY_MODULE_KEY, CATEGORY_MODULE_KEY } from '~/config/masterCategory'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

const props = defineProps<{
  mode: 'new' | 'from-lead' | 'edit'
  leadId?: string | null
  opportunityId?: string | null
}>()

const { t } = useI18n()
const { profile } = useProfile()
const { ensurePermissions } = usePermissions()
const { list: listLeads } = useLeads()
const { list, listLineItems, createFromLead, create, update, ensureDefaults, getByLeadId } = useOpportunities()
const { getDefaultPipeline } = useDeals()
const { listAssignees } = useTasks()
const {
  list: listCompanies,
  create: createCompany,
  syncBillAddresses
} = useCompanies()
const { list: listSalesTeams } = useSalesTeams()
const { list: listCategories } = useCategories()
const { list: listProducts } = useProducts()
const { list: listServices } = useServices()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultOpportunityFormInput())
const lineItems = ref<OpportunityLineItemDraft[]>([defaultOpportunityLineItemDraft()])
const opportunityCode = ref<string | null>(null)
const lead = ref<Lead | null>(null)
const standalone = ref(false)
const stages = ref<PipelineStage[]>([])
const assignees = ref<TaskAssignee[]>([])
const companies = ref<Company[]>([])
const salesTeams = ref<SalesTeam[]>([])
const productCategories = ref<Category[]>([])
const serviceCategories = ref<Category[]>([])
const products = ref<Product[]>([])
const services = ref<Service[]>([])
const loading = ref(true)
const customerMode = ref<LeadCustomerMode>('existing')
const selectedCompanyId = ref<string | null>(null)
const customerForm = ref(defaultMasterCustomerFormInput())
const billAddressDrafts = ref<CustomerCompanyAddressDraft[]>([])
const customerSyncReady = ref(false)
const lockCustomerMode = ref(false)

await ensurePermissions()

const isEdit = computed(() => props.mode === 'edit')
const isFromLead = computed(() => props.mode === 'from-lead')
const isNew = computed(() => props.mode === 'new')
const lockLeadFields = computed(() => isFromLead.value || (isEdit.value && !standalone.value))
const showCustomerSection = computed(() => isNew.value || (isEdit.value && standalone.value))
const customerInForm = computed(() => lockLeadFields.value)

const pageTitle = computed(() => {
  if (isEdit.value) return t('opportunities.editTitle')
  if (isFromLead.value) return t('opportunities.createFromLeadTitle')
  return t('opportunities.createTitle')
})

const pageSubtitle = computed(() => {
  if (isEdit.value) return t('opportunities.editSubtitle')
  if (isFromLead.value) return t('opportunities.createFromLeadSubtitle')
  return t('opportunities.createSubtitle')
})

const backTo = computed(() => {
  if (isEdit.value && props.opportunityId) return `/app/opportunities/${props.opportunityId}`
  if (lead.value) return `/app/leads/${lead.value.id}`
  return '/app/opportunities'
})

watch(
  () => [showCustomerSection.value, selectedCompanyId.value] as const,
  ([visible, companyId]) => {
    if (!visible) return
    form.value = {
      ...form.value,
      company_id: companyId
    }
  }
)

async function refreshCatalog() {
  const [productCatResult, serviceCatResult, productResult, serviceResult] = await Promise.allSettled([
    listCategories(CATEGORY_MODULE_KEY),
    listCategories(SERVICE_CATEGORY_MODULE_KEY),
    listProducts(),
    listServices()
  ])

  productCategories.value = productCatResult.status === 'fulfilled' ? productCatResult.value : []
  serviceCategories.value = serviceCatResult.status === 'fulfilled' ? serviceCatResult.value : []
  products.value = productResult.status === 'fulfilled' ? productResult.value : []
  services.value = serviceResult.status === 'fulfilled' ? serviceResult.value : []

  if (serviceCatResult.status === 'rejected') {
    console.warn('Service categories unavailable:', serviceCatResult.reason)
  }
  if (serviceResult.status === 'rejected') {
    console.warn('Services catalog unavailable:', serviceResult.reason)
  }
}

try {
  await ensureDefaults()
  const [pipelineData, assigneeRows, companyRows, teamRows] = await Promise.all([
    getDefaultPipeline(),
    listAssignees(),
    listCompanies(),
    listSalesTeams()
  ])
  await refreshCatalog()
  stages.value = pipelineData.stages
  assignees.value = assigneeRows
  companies.value = companyRows
  salesTeams.value = teamRows

  const defaultStage = pipelineData.stages.find(
    stage => !stage.is_won && !stage.is_lost
  ) ?? pipelineData.stages[0] ?? null

  if (isFromLead.value && props.leadId) {
    const existingId = await getByLeadId(props.leadId)
    if (existingId) {
      await navigateTo(`/app/opportunities/${existingId}`)
    } else {
      const leadRows = await listLeads()
      const row = leadRows.find(item => item.id === props.leadId)
      if (!row) {
        await navigateTo('/app/leads')
      } else if (!canConvertLead(row)) {
        await navigateTo(`/app/leads/${row.id}`)
      } else {
        lead.value = row
        standalone.value = false
        form.value = leadToOpportunityPrefill(
          row,
          defaultStage,
          profile.value?.id ?? null,
          t('opportunities.defaultTitleSuffix')
        )
        lineItems.value = [{
          ...defaultOpportunityLineItemDraft('product'),
          unit_price: String(row.lead_value ?? 0),
          line_total: String(row.lead_value ?? 0)
        }]
      }
    }
  } else if (isNew.value) {
    standalone.value = true
    form.value = {
      ...defaultOpportunityFormInput(),
      stage_id: defaultStage?.id ?? null,
      probability: defaultStage?.probability ?? 0,
      owner_id: profile.value?.id ?? null
    }
    lineItems.value = [defaultOpportunityLineItemDraft()]
    customerMode.value = 'existing'
    customerSyncReady.value = true
  } else if (isEdit.value && props.opportunityId) {
    const rows = await list()
    const row = rows.find(item => item.id === props.opportunityId)
    if (!row) {
      await navigateTo('/app/opportunities')
    } else {
      opportunityCode.value = row.opportunity_code
      form.value = opportunityToFormInput(row)
      standalone.value = !row.lead_id
      const lineRows = await listLineItems(row.id)
      const allCategories = [...productCategories.value, ...serviceCategories.value]
      lineItems.value = lineRows.length
        ? opportunityLineItemsToDrafts(lineRows, allCategories)
        : [defaultOpportunityLineItemDraft()]
      if (row.lead_id) {
        const leadRows = await listLeads()
        const leadRow = leadRows.find(item => item.id === row.lead_id)
        lead.value = leadRow ?? {
          id: row.lead_id,
          lead_code: row.lead_code
        } as Lead
      } else {
        lead.value = null
        customerMode.value = 'existing'
        selectedCompanyId.value = row.company_id
        lockCustomerMode.value = true
        customerSyncReady.value = true
      }
      if (!lineItems.value.length) {
        lineItems.value = [defaultOpportunityLineItemDraft()]
      }
    }
  }
} catch (error) {
  console.error(error)
  await navigateTo('/app/opportunities')
} finally {
  loading.value = false
}

async function resolveCompanyId(): Promise<string> {
  if (!showCustomerSection.value) {
    if (!form.value.company_id) {
      throw new Error('customerRequired')
    }
    return form.value.company_id
  }

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

  const payload = formToCompanyPayload(customerForm.value, billAddressDrafts.value)
  const company = await createCompany(payload)
  await syncBillAddresses(company.id, billAddressDrafts.value)
  companies.value = await listCompanies()
  selectedCompanyId.value = company.id
  form.value = {
    ...form.value,
    company_id: company.id
  }
  return company.id
}

async function save() {
  errorMsg.value = ''

  if (showCustomerSection.value) {
    const customerModeError = validateLeadCustomerMode(customerMode.value, selectedCompanyId.value)
    if (customerModeError && customerMode.value === 'existing') {
      errorMsg.value = t(`leads.validation.${customerModeError}`)
      return
    }
  }

  saving.value = true
  try {
    if (showCustomerSection.value) {
      await resolveCompanyId()
    }

    const validationKey = validateOpportunityForm(form.value, lineItems.value)
    if (validationKey) {
      errorMsg.value = t(`opportunities.validation.${validationKey}`)
      return
    }

    if (isFromLead.value && props.leadId) {
      const created = await createFromLead(props.leadId, form.value, lineItems.value)
      await navigateTo(`/app/opportunities/${created.id}`)
      return
    }
    if (isNew.value) {
      const created = await create(form.value, lineItems.value)
      await navigateTo(`/app/opportunities/${created.id}`)
      return
    }
    if (isEdit.value && props.opportunityId) {
      await update(props.opportunityId, form.value, lineItems.value, standalone.value)
      await navigateTo(`/app/opportunities/${props.opportunityId}`)
    }
  } catch (error) {
    if (error instanceof Error && error.message.startsWith('masterData.customer.validation.')) {
      errorMsg.value = t(error.message)
      return
    }
    if (error instanceof Error && error.message === 'customerRequired') {
      errorMsg.value = t('opportunities.validation.customerRequired')
      return
    }
    errorMsg.value = getSupabaseErrorMessage(error, t('opportunities.errors.saveFailed'))
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div>
    <UButton
      :to="backTo"
      variant="ghost"
      color="neutral"
      icon="i-lucide-arrow-left"
      size="sm"
      class="mb-4"
    >
      {{ t('common.back') }}
    </UButton>

    <UCard v-if="loading">
      <p class="text-gray-500 dark:text-gray-400">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <form
      v-else
      class="lg:grid lg:grid-cols-[minmax(0,1fr)_17rem] lg:items-start lg:gap-6"
      @submit.prevent="save"
    >
      <div class="min-w-0 space-y-6">
        <div>
          <div class="flex flex-wrap items-center gap-2">
            <h1 class="text-2xl font-bold font-heading text-gray-900 dark:text-gray-100">
              {{ pageTitle }}
            </h1>
            <UBadge
              color="primary"
              variant="soft"
              size="sm"
            >
              {{ t('opportunities.badge') }}
            </UBadge>
          </div>
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

        <LeadsCustomerSection
          v-if="showCustomerSection"
          v-model:mode="customerMode"
          v-model:company-id="selectedCompanyId"
          v-model:customer-form="customerForm"
          v-model:bill-addresses="billAddressDrafts"
          :companies="companies"
          :lock-mode="lockCustomerMode"
          :enable-sync="customerSyncReady"
        />

        <OpportunitiesForm
          v-model="form"
          v-model:line-items="lineItems"
          :stages="stages"
          :companies="companies"
          :assignees="assignees"
          :sales-teams="salesTeams"
          :product-categories="productCategories"
          :service-categories="serviceCategories"
          :products="products"
          :services="services"
          :opportunity-code="opportunityCode"
          :lead-code="lead?.lead_code ?? null"
          :lead-id="lead?.id ?? props.leadId ?? null"
          :lock-lead-fields="lockLeadFields"
          :customer-in-form="customerInForm"
          @catalog-changed="refreshCatalog"
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0 lg:self-start">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            {{ t('opportunities.actions') }}
          </p>
          <UButton
            type="submit"
            color="primary"
            size="lg"
            class="w-full justify-center"
            icon="i-lucide-check"
            :loading="saving"
          >
            {{ isEdit ? t('opportunities.save') : t('opportunities.create') }}
          </UButton>
        </UCard>
      </aside>
    </form>
  </div>
</template>
