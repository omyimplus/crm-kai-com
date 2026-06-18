<script setup lang="ts">
import type { Category, Company, CompanyBillAddress, Lead, OpportunityProjectDraft, PipelineStage, SalesTeam, TaskAssignee } from '~/types/crm'
import { appFormErrorClass } from '~/config/appFormUi'
import {
  defaultOpportunityFormInput,
  defaultCompanyBillAddressText,
  leadToDefaultProjects,
  leadToOpportunityPrefill,
  legacyOpportunityToProjects,
  opportunityProjectsToDrafts,
  opportunityToFormInput,
  validateOpportunityForm,
  canConvertLead
} from '~/utils/masterOpportunities'
import { defaultOpportunityProjectDraft } from '~/utils/masterOpportunityProjects'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

const props = defineProps<{
  mode: 'from-lead' | 'edit'
  leadId?: string | null
  opportunityId?: string | null
}>()

const { t } = useI18n()
const { profile } = useProfile()
const { ensurePermissions } = usePermissions()
const { list: listLeads } = useLeads()
const { list, listProjects, createFromLead, update, ensureDefaults, getByLeadId } = useOpportunities()
const { getDefaultPipeline } = useDeals()
const { listAssignees } = useTasks()
const { list: listCompanies, listBillAddresses } = useCompanies()
const { list: listSalesTeams } = useSalesTeams()
const { list: listCategories } = useCategories()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultOpportunityFormInput())
const projects = ref<OpportunityProjectDraft[]>([])
const opportunityCode = ref<string | null>(null)
const lead = ref<Lead | null>(null)
const stages = ref<PipelineStage[]>([])
const assignees = ref<TaskAssignee[]>([])
const companies = ref<Company[]>([])
const salesTeams = ref<SalesTeam[]>([])
const categories = ref<Category[]>([])
const billAddresses = ref<CompanyBillAddress[]>([])
const loading = ref(true)

async function loadCustomerBillAddresses(companyId: string | null, applyDefault = false) {
  if (!companyId) {
    billAddresses.value = []
    return
  }
  billAddresses.value = await listBillAddresses(companyId)
  if (applyDefault && !form.value.address_bill_to.trim()) {
    const defaultAddress = defaultCompanyBillAddressText(billAddresses.value)
    if (defaultAddress) {
      form.value = {
        ...form.value,
        address_bill_to: defaultAddress
      }
    }
  }
}

await ensurePermissions()

const isEdit = computed(() => props.mode === 'edit')
const isFromLead = computed(() => props.mode === 'from-lead')

const pageTitle = computed(() =>
  isEdit.value ? t('opportunities.editTitle') : t('opportunities.createTitle')
)
const pageSubtitle = computed(() =>
  isEdit.value ? t('opportunities.editSubtitle') : t('opportunities.createSubtitle')
)

const backTo = computed(() => {
  if (isEdit.value && props.opportunityId) return `/app/opportunities/${props.opportunityId}`
  if (lead.value) return `/app/leads/${lead.value.id}`
  return '/app/opportunities'
})

try {
  await ensureDefaults()
  const [pipelineData, assigneeRows, companyRows, teamRows, categoryRows] = await Promise.all([
    getDefaultPipeline(),
    listAssignees(),
    listCompanies(),
    listSalesTeams(),
    listCategories()
  ])
  stages.value = pipelineData.stages
  assignees.value = assigneeRows
  companies.value = companyRows
  salesTeams.value = teamRows
  categories.value = categoryRows

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
        form.value = leadToOpportunityPrefill(
          row,
          defaultStage,
          profile.value?.id ?? null,
          t('opportunities.defaultTitleSuffix')
        )
        projects.value = leadToDefaultProjects(row)
        await loadCustomerBillAddresses(form.value.company_id, true)
      }
    }
  } else if (isEdit.value && props.opportunityId) {
    const rows = await list()
    const row = rows.find(item => item.id === props.opportunityId)
    if (!row) {
      await navigateTo('/app/opportunities')
    } else {
      opportunityCode.value = row.opportunity_code
      form.value = opportunityToFormInput(row)
      const projectRows = await listProjects(row.id)
      projects.value = projectRows.length
        ? opportunityProjectsToDrafts(projectRows)
        : legacyOpportunityToProjects(row)
      const leadRows = await listLeads()
      const leadRow = leadRows.find(item => item.id === row.lead_id)
      if (leadRow) {
        lead.value = leadRow
      } else {
        lead.value = {
          id: row.lead_id,
          lead_code: row.lead_code
        } as Lead
      }
      if (!projects.value.length) {
        projects.value = leadRow
          ? leadToDefaultProjects(leadRow)
          : [defaultOpportunityProjectDraft()]
      }
      await loadCustomerBillAddresses(form.value.company_id)
    }
  }
} catch (error) {
  console.error(error)
  await navigateTo('/app/opportunities')
} finally {
  loading.value = false
}

async function save() {
  errorMsg.value = ''
  const validationKey = validateOpportunityForm(form.value, projects.value)
  if (validationKey) {
    errorMsg.value = t(`opportunities.validation.${validationKey}`)
    return
  }

  saving.value = true
  try {
    if (isFromLead.value && props.leadId) {
      const created = await createFromLead(props.leadId, form.value, projects.value)
      await navigateTo(`/app/opportunities/${created.id}`)
      return
    }
    if (isEdit.value && props.opportunityId) {
      await update(props.opportunityId, form.value, projects.value)
      await navigateTo(`/app/opportunities/${props.opportunityId}`)
    }
  } catch (error) {
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

        <OpportunitiesForm
          v-model="form"
          v-model:projects="projects"
          :stages="stages"
          :companies="companies"
          :assignees="assignees"
          :sales-teams="salesTeams"
          :categories="categories"
          :bill-addresses="billAddresses"
          :opportunity-code="opportunityCode"
          :lead-code="lead?.lead_code ?? null"
          :lead-id="lead?.id ?? props.leadId ?? null"
          lock-lead-fields
          @bill-addresses-changed="loadCustomerBillAddresses(form.company_id)"
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
