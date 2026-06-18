<script setup lang="ts">
import type {
  Category,
  Company,
  CompanyBillAddress,
  OpportunityFormInput,
  OpportunityProjectDraft,
  PipelineStage,
  SalesTeam,
  TaskAssignee
} from '~/types/crm'
import { opportunitiesSectionThemes } from '~/config/masterOpportunities'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import { companyBillAddressSelectOptions, stageOptionLabel } from '~/utils/masterOpportunities'
import {
  defaultOpportunityProjectDraft,
  opportunityProductGroupSelectOptions,
  opportunityProjectSubTypeSelectOptions,
  opportunityProjectTypeSelectOptions,
  sumOpportunityProjectsValue
} from '~/utils/masterOpportunityProjects'

const form = defineModel<OpportunityFormInput>({ required: true })
const projects = defineModel<OpportunityProjectDraft[]>('projects', { required: true })

const props = withDefaults(defineProps<{
  stages: PipelineStage[]
  companies: Company[]
  assignees: TaskAssignee[]
  salesTeams: SalesTeam[]
  categories?: Category[]
  billAddresses?: CompanyBillAddress[]
  opportunityCode?: string | null
  leadCode?: string | null
  leadId?: string | null
  lockLeadFields?: boolean
  readonly?: boolean
}>(), {
  categories: () => [],
  billAddresses: () => [],
  lockLeadFields: true
})

const emit = defineEmits<{
  'bill-addresses-changed': []
}>()

const { t } = useI18n()
const { formatCurrency } = useFormat()
const { pipelineStageLabel } = usePipelineStageLabel()

const billAddressModalOpen = ref(false)

const customerName = computed(() =>
  props.companies.find(row => row.id === form.value.company_id)?.name ?? null
)

const noneOption = computed(() => ({
  label: t('opportunities.none'),
  value: null as string | null
}))

const companyOptions = computed(() =>
  props.companies.map(row => ({
    label: row.name,
    value: row.id
  }))
)

const stageOptions = computed(() =>
  props.stages.map(stage => ({
    label: stageOptionLabel(stage, name => pipelineStageLabel(name)),
    value: stage.id,
    probability: stage.probability
  }))
)

const assigneeOptions = computed(() =>
  props.assignees.map(row => ({
    label: row.full_name?.trim() || row.username || row.id,
    value: row.id
  }))
)

const salesTeamOptions = computed(() =>
  props.salesTeams
    .filter(row => row.status === 'active')
    .map(row => ({
      label: row.name,
      value: row.id
    }))
)

const billAddressOptions = computed(() =>
  companyBillAddressSelectOptions(props.billAddresses, form.value.address_bill_to)
)

const selectedBillAddressId = computed({
  get() {
    const current = form.value.address_bill_to.trim()
    const match = props.billAddresses.find(row => row.address.trim() === current)
    if (match) return match.id
    if (current) return `legacy:${current}`
    return null
  },
  set(value: string | null) {
    if (props.readonly || !value) return
    if (value.startsWith('legacy:')) {
      form.value = {
        ...form.value,
        address_bill_to: value.slice('legacy:'.length)
      }
      return
    }
    const row = props.billAddresses.find(address => address.id === value)
    if (row) {
      form.value = {
        ...form.value,
        address_bill_to: row.address.trim()
      }
    }
  }
})

function onBillAddressSaved(payload: { address: string }) {
  form.value = {
    ...form.value,
    address_bill_to: payload.address
  }
  emit('bill-addresses-changed')
}

function fieldLockedFromLead(leadField = false) {
  return Boolean(props.readonly || (leadField && props.lockLeadFields))
}

function onStageChange(stageId: string | null) {
  if (!stageId || props.readonly) return
  const stage = props.stages.find(row => row.id === stageId)
  if (stage) {
    form.value = {
      ...form.value,
      stage_id: stageId,
      probability: stage.probability
    }
  }
}

watch(
  () => form.value.stage_id,
  (next, prev) => {
    if (next && next !== prev) onStageChange(next)
  }
)

const projectsTotalValue = computed(() => sumOpportunityProjectsValue(projects.value))

function addProject() {
  projects.value = [...projects.value, defaultOpportunityProjectDraft()]
}

function removeProject(id: string) {
  projects.value = projects.value.filter(row => row.id !== id)
}
</script>

<template>
  <div class="space-y-6">
    <div
      v-if="opportunityCode || leadCode"
      class="flex flex-wrap gap-4 rounded-2xl border border-gray-200 bg-gray-50 px-4 py-3 text-sm dark:border-gray-800 dark:bg-gray-900/50"
    >
      <div v-if="opportunityCode">
        <span class="text-gray-500 dark:text-gray-400">{{ t('opportunities.fields.opportunityCode') }}</span>
        <span class="ms-2 font-semibold text-gray-900 dark:text-gray-100">{{ opportunityCode }}</span>
      </div>
      <div v-if="leadCode">
        <span class="text-gray-500 dark:text-gray-400">{{ t('opportunities.fields.leadCode') }}</span>
        <span class="ms-2 font-semibold text-gray-900 dark:text-gray-100">{{ leadCode }}</span>
      </div>
    </div>

    <p
      v-if="lockLeadFields && !readonly"
      class="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-900 dark:border-amber-900/50 dark:bg-amber-950/30 dark:text-amber-200"
    >
      {{ t('opportunities.fields.leadLockedHint') }}
    </p>

    <div class="grid gap-6 xl:grid-cols-2">
      <AppFormSection
        :title="t('opportunities.sections.opportunity')"
        :icon="opportunitiesSectionThemes.opportunity.icon"
        :icon-class="opportunitiesSectionThemes.opportunity.iconClass"
      >
        <div class="space-y-4">
          <UFormField
            :label="t('opportunities.fields.title')"
            required
          >
            <UInput
              v-model="form.title"
              :readonly="fieldLockedFromLead(true)"
              :class="appFormFieldClass"
              :ui="appInputUi"
              :placeholder="t('opportunities.fields.titlePlaceholder')"
            />
          </UFormField>

          <UFormField
            :label="t('opportunities.fields.customer')"
            required
          >
            <USelectMenu
              v-model="form.company_id"
              :items="companyOptions"
              value-key="value"
              :disabled="fieldLockedFromLead(true)"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
              :placeholder="t('opportunities.fields.customerPlaceholder')"
            />
          </UFormField>

          <UFormField
            :label="t('opportunities.fields.stage')"
            required
          >
            <USelectMenu
              v-model="form.stage_id"
              :items="stageOptions"
              value-key="value"
              :disabled="readonly"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
              :placeholder="t('opportunities.fields.stagePlaceholder')"
            />
          </UFormField>

          <UFormField :label="t('opportunities.fields.probability')">
            <UInput
              v-model.number="form.probability"
              type="number"
              min="0"
              max="100"
              readonly
              :class="appFormFieldClass"
              :ui="appInputUi"
              :placeholder="t('opportunities.fields.probabilityPlaceholder')"
            />
            <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
              {{ t('opportunities.fields.probabilityFromStage') }}
            </p>
          </UFormField>

          <UFormField :label="t('opportunities.fields.closeDate')">
            <UInput
              v-model="form.close_date"
              type="date"
              :readonly="readonly"
              :class="appFormFieldClass"
              :ui="appInputUi"
            />
          </UFormField>

          <UFormField :label="t('opportunities.fields.description')">
            <UTextarea
              v-model="form.description"
              :readonly="fieldLockedFromLead(true)"
              :class="appFormFieldClass"
              :ui="appTextareaUi"
              :placeholder="t('opportunities.fields.descriptionPlaceholder')"
              :rows="4"
            />
          </UFormField>
        </div>
      </AppFormSection>

      <AppFormSection
        :title="t('opportunities.sections.people')"
        :icon="opportunitiesSectionThemes.people.icon"
        :icon-class="opportunitiesSectionThemes.people.iconClass"
      >
        <div class="space-y-4">
          <UFormField
            :label="t('opportunities.fields.owner')"
            required
          >
            <USelectMenu
              v-model="form.owner_id"
              :items="assigneeOptions"
              value-key="value"
              :disabled="fieldLockedFromLead(true)"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
              :placeholder="t('opportunities.fields.ownerPlaceholder')"
            />
          </UFormField>

          <UFormField :label="t('opportunities.fields.salesOwner')">
            <USelectMenu
              v-model="form.sales_owner_id"
              :items="[noneOption, ...assigneeOptions]"
              value-key="value"
              :disabled="fieldLockedFromLead(true)"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
              :placeholder="t('opportunities.fields.salesOwnerPlaceholder')"
            />
          </UFormField>

          <UFormField :label="t('opportunities.fields.salesDesigner')">
            <USelectMenu
              v-model="form.sales_designer_id"
              :items="[noneOption, ...assigneeOptions]"
              value-key="value"
              :disabled="readonly"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
              :placeholder="t('opportunities.fields.salesDesignerPlaceholder')"
            />
          </UFormField>

          <UFormField :label="t('opportunities.fields.salesTeam')">
            <USelectMenu
              v-model="form.sales_team_id"
              :items="[noneOption, ...salesTeamOptions]"
              value-key="value"
              :disabled="readonly"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
              :placeholder="t('opportunities.fields.salesTeamPlaceholder')"
            />
          </UFormField>
        </div>
      </AppFormSection>
    </div>

    <AppFormSection
      :title="t('opportunities.sections.address')"
      :icon="opportunitiesSectionThemes.address.icon"
      :icon-class="opportunitiesSectionThemes.address.iconClass"
    >
      <UFormField :label="t('opportunities.fields.addressBillTo')">
        <USelectMenu
          v-if="billAddressOptions.length"
          v-model="selectedBillAddressId"
          :items="billAddressOptions"
          value-key="value"
          :disabled="readonly"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
          :placeholder="t('opportunities.fields.billToPlaceholder')"
        />
        <p
          v-else-if="form.company_id && !readonly"
          class="space-y-3"
        >
          <span class="block text-sm text-amber-700 dark:text-amber-300">
            {{ t('opportunities.fields.billToEmpty') }}
          </span>
          <UButton
            variant="soft"
            color="primary"
            icon="i-lucide-plus"
            size="sm"
            @click="billAddressModalOpen = true"
          >
            {{ t('opportunities.fields.addBillTo') }}
          </UButton>
        </p>
        <p
          v-else
          class="text-sm text-gray-500 dark:text-gray-400"
        >
          {{ t('opportunities.notSet') }}
        </p>
        <p
          v-if="form.address_bill_to"
          class="mt-2 whitespace-pre-wrap rounded-xl border border-gray-200 bg-gray-50 px-3 py-2 text-sm text-gray-700 dark:border-gray-800 dark:bg-gray-900/50 dark:text-gray-300"
        >
          {{ form.address_bill_to }}
        </p>
        <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
          {{ t('opportunities.fields.billToFromCustomer') }}
        </p>
      </UFormField>
      <p class="mt-2 text-xs text-gray-500 dark:text-gray-400">
        {{ t('opportunities.fields.shipToHint') }}
      </p>
    </AppFormSection>

    <AppFormSection
      :title="t('opportunities.sections.projects')"
      :icon="opportunitiesSectionThemes.project.icon"
      :icon-class="opportunitiesSectionThemes.project.iconClass"
    >
      <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
        <p class="text-sm text-gray-600 dark:text-gray-300">
          {{ t('opportunities.projects.totalValue') }}
          <span class="font-semibold text-gray-900 dark:text-gray-100">
            {{ formatCurrency(projectsTotalValue) }}
          </span>
        </p>
        <UButton
          v-if="!readonly"
          variant="soft"
          color="primary"
          icon="i-lucide-plus"
          size="sm"
          @click="addProject"
        >
          {{ t('opportunities.projects.add') }}
        </UButton>
      </div>

      <p
        v-if="!projects.length"
        class="rounded-xl border border-dashed border-gray-300 px-4 py-8 text-center text-sm text-gray-500 dark:border-gray-600 dark:text-gray-400"
      >
        {{ t('opportunities.projects.empty') }}
      </p>

      <div
        v-else
        class="space-y-4"
      >
        <div
          v-for="(row, index) in projects"
          :key="row.id"
          class="rounded-2xl border border-gray-200 p-4 dark:border-gray-800"
        >
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
              @click="removeProject(row.id)"
            />
          </div>

          <div class="grid gap-4 md:grid-cols-2">
            <UFormField :label="t('opportunities.fields.projectName')">
              <UInput
                v-model="row.project_name"
                :readonly="readonly"
                :class="appFormFieldClass"
                :ui="appInputUi"
                :placeholder="t('opportunities.fields.projectNamePlaceholder')"
              />
            </UFormField>

            <UFormField :label="t('opportunities.fields.projectType')">
              <USelectMenu
                v-model="row.project_type"
                :items="opportunityProjectTypeSelectOptions(t, row.project_type)"
                value-key="value"
                :search-input="false"
                :disabled="readonly"
                :class="appFormFieldClass"
                :ui="appSelectMenuUi"
                :placeholder="t('opportunities.fields.projectTypePlaceholder')"
              />
            </UFormField>

            <UFormField :label="t('opportunities.fields.projectSubType')">
              <USelectMenu
                v-model="row.project_sub_type"
                :items="opportunityProjectSubTypeSelectOptions(t, row.project_sub_type)"
                value-key="value"
                :search-input="false"
                :disabled="readonly"
                :class="appFormFieldClass"
                :ui="appSelectMenuUi"
                :placeholder="t('opportunities.fields.projectSubTypePlaceholder')"
              />
            </UFormField>

            <UFormField :label="t('opportunities.fields.productsGroup')">
              <USelectMenu
                v-model="row.products_group"
                :items="opportunityProductGroupSelectOptions(t, categories, row.products_group)"
                value-key="value"
                searchable
                :disabled="readonly"
                :class="appFormFieldClass"
                :ui="appSelectMenuUi"
                :placeholder="t('opportunities.fields.productsGroupPlaceholder')"
              />
            </UFormField>

            <UFormField :label="t('opportunities.fields.estimatedValue')">
              <UInput
                v-model="row.estimated_value"
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
                v-model="row.project_costs"
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
      </div>

      <p class="mt-3 text-xs text-gray-500 dark:text-gray-400">
        {{ t('opportunities.projects.hint') }}
      </p>
      <p
        v-if="lockLeadFields && leadId && !readonly"
        class="mt-2 text-xs text-gray-500 dark:text-gray-400"
      >
        {{ t('opportunities.fields.estimatedValueSyncLead') }}
      </p>
    </AppFormSection>

    <OpportunitiesCustomerBillAddressModal
      v-if="form.company_id"
      v-model:open="billAddressModalOpen"
      :company-id="form.company_id"
      :customer-name="customerName"
      @saved="onBillAddressSaved"
    />
  </div>
</template>
