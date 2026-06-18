<script setup lang="ts">
import type { Company, Lead, LeadSource, ModuleStatus, TaskAssignee } from '~/types/crm'
import type { CustomerCompanyAddressDraft } from '~/utils/masterCustomer'
import { defaultMasterCustomerFormInput } from '~/utils/masterCustomer'
import type { LeadCustomerMode } from '~/utils/masterLeads'
import {
  defaultLeadFormInput,
  leadDisplayName,
  leadSnapshotBillAddresses,
  leadSnapshotToCustomerForm,
  leadToFormInput
} from '~/utils/masterLeads'
import { canConvertLead } from '~/utils/masterOpportunities'

const props = defineProps<{
  leadId: string
}>()

const { t } = useI18n()
const { ensurePermissions, canWriteModule } = usePermissions()
const { list, remove, ensureDefaults } = useLeads()
const { getByLeadId } = useOpportunities()
const { listByModule } = useModuleStatuses()
const { listAssignees } = useTasks()
const { list: listCompanies } = useCompanies()
const { list: listLeadSources } = useLeadSources()

await ensurePermissions()

const loading = ref(true)
const lead = ref<Lead | null>(null)
const form = ref(defaultLeadFormInput())
const statuses = ref<ModuleStatus[]>([])
const assignees = ref<TaskAssignee[]>([])
const companies = ref<Company[]>([])
const leadSources = ref<LeadSource[]>([])
const customerMode = ref<LeadCustomerMode>('existing')
const selectedCompanyId = ref<string | null>(null)
const customerForm = ref(defaultMasterCustomerFormInput())
const billAddresses = ref<CustomerCompanyAddressDraft[]>([])
const customerSyncReady = ref(false)
const deleteOpen = ref(false)
const linkedOpportunityId = ref<string | null>(null)

const canWrite = computed(() => canWriteModule('app.lead'))
const canWriteOpportunity = computed(() => canWriteModule('app.opportunity'))
const showConvert = computed(() =>
  canWriteOpportunity.value
  && lead.value
  && !linkedOpportunityId.value
  && canConvertLead(lead.value)
)

try {
  await ensureDefaults()
  const [statusRows, assigneeRows, companyRows, sourceRows, leadRows] = await Promise.all([
    listByModule('lead'),
    listAssignees(),
    listCompanies(),
    listLeadSources(),
    list()
  ])
  statuses.value = statusRows
  assignees.value = assigneeRows
  companies.value = companyRows
  leadSources.value = sourceRows.filter(row => row.status === 'active')

  const row = leadRows.find(item => item.id === props.leadId)
  if (!row) {
    await navigateTo('/app/leads')
  } else {
    lead.value = row
    form.value = leadToFormInput(row)
    linkedOpportunityId.value = await getByLeadId(row.id)

    if (row.company_id) {
      customerMode.value = 'existing'
      selectedCompanyId.value = row.company_id
    } else {
      customerMode.value = 'new'
      customerForm.value = leadSnapshotToCustomerForm(row)
      billAddresses.value = leadSnapshotBillAddresses(row)
    }
  }

  customerSyncReady.value = true
} catch (error) {
  console.error(error)
  await navigateTo('/app/leads')
} finally {
  loading.value = false
}

async function confirmDelete() {
  if (!lead.value) return
  try {
    await remove(lead.value.id)
    deleteOpen.value = false
    await navigateTo('/app/leads')
  } catch (error) {
    console.error(error)
  }
}
</script>

<template>
  <div>
    <UButton
      to="/app/leads"
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

    <div
      v-else-if="lead"
      class="lg:grid lg:grid-cols-[minmax(0,1fr)_17rem] lg:items-start lg:gap-6"
    >
      <div class="min-w-0 space-y-6">
        <div>
          <div class="flex flex-wrap items-center gap-2">
            <h1 class="text-2xl font-bold font-heading text-gray-900 dark:text-gray-100">
              {{ leadDisplayName(lead) }}
            </h1>
            <LeadsStatusBadge
              :status-code="lead.status_code"
              :status-name="lead.status_name"
              :status-color="lead.status_color"
            />
          </div>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ lead.lead_code }} · {{ t('leads.viewSubtitle') }}
          </p>
        </div>

        <LeadsForm
          v-model="form"
          :statuses="statuses"
          :assignees="assignees"
          :lead-sources="leadSources"
          readonly
        >
          <LeadsCustomerSection
            v-model:mode="customerMode"
            v-model:company-id="selectedCompanyId"
            v-model:customer-form="customerForm"
            v-model:bill-addresses="billAddresses"
            :companies="companies"
            lock-mode
            :enable-sync="customerSyncReady"
            readonly
          />
        </LeadsForm>
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            {{ t('leads.actions') }}
          </p>
          <UButton
            v-if="showConvert"
            block
            size="lg"
            color="primary"
            icon="i-lucide-sparkles"
            :to="`/app/opportunities/from-lead/${lead.id}`"
          >
            {{ t('leads.convertToOpportunity') }}
          </UButton>
          <UButton
            v-if="linkedOpportunityId"
            block
            :class="showConvert ? 'mt-2' : ''"
            size="lg"
            variant="soft"
            icon="i-lucide-sparkles"
            :to="`/app/opportunities/${linkedOpportunityId}`"
          >
            {{ t('leads.viewOpportunity') }}
          </UButton>
          <UButton
            v-if="canWrite"
            block
            :class="showConvert || linkedOpportunityId ? 'mt-2' : ''"
            size="lg"
            icon="i-lucide-pencil"
            :to="`/app/leads/${lead.id}/edit`"
          >
            {{ t('common.edit') }}
          </UButton>
          <UButton
            v-if="canWrite"
            block
            class="mt-2"
            color="error"
            variant="soft"
            icon="i-lucide-trash-2"
            @click="deleteOpen = true"
          >
            {{ t('common.delete') }}
          </UButton>
        </UCard>
      </aside>
    </div>

    <AppDialog
      v-model:open="deleteOpen"
      :title="t('leads.deleteTitle')"
      size="sm"
    >
      <p class="text-sm text-gray-600 dark:text-gray-300">
        {{ t('leads.deleteConfirm', { name: lead ? leadDisplayName(lead) : '' }) }}
      </p>
      <template #footer>
        <AppDialogFooter @cancel="deleteOpen = false">
          <UButton
            color="error"
            @click="confirmDelete"
          >
            {{ t('common.delete') }}
          </UButton>
        </AppDialogFooter>
      </template>
    </AppDialog>
  </div>
</template>
