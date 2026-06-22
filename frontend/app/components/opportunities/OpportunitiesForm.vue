<script setup lang="ts">
import type {
  Category,
  Company,
  OpportunityFormInput,
  OpportunityLineItemDraft,
  PipelineStage,
  Product,
  SalesTeam,
  Service,
  TaskAssignee
} from '~/types/crm'
import { opportunitiesSectionThemes } from '~/config/masterOpportunities'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import { stageOptionLabel } from '~/utils/masterOpportunities'

const form = defineModel<OpportunityFormInput>({ required: true })
const lineItems = defineModel<OpportunityLineItemDraft[]>('lineItems', { required: true })

const props = withDefaults(defineProps<{
  stages: PipelineStage[]
  companies: Company[]
  assignees: TaskAssignee[]
  salesTeams: SalesTeam[]
  productCategories?: Category[]
  serviceCategories?: Category[]
  products?: Product[]
  services?: Service[]
  opportunityCode?: string | null
  leadCode?: string | null
  leadId?: string | null
  lockLeadFields?: boolean
  customerInForm?: boolean
  readonly?: boolean
}>(), {
  productCategories: () => [],
  serviceCategories: () => [],
  products: () => [],
  services: () => [],
  lockLeadFields: true,
  customerInForm: false
})

const emit = defineEmits<{
  'catalog-changed': []
}>()

const { t } = useI18n()
const { pipelineStageLabel } = usePipelineStageLabel()

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
            v-if="customerInForm"
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
            v-else-if="readonly"
            :label="t('opportunities.fields.customer')"
          >
            <p class="text-sm font-medium text-gray-900 dark:text-gray-100">
              {{ customerName || t('opportunities.notSet') }}
            </p>
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

    <OpportunitiesLineItems
      v-model="lineItems"
      :product-categories="productCategories"
      :service-categories="serviceCategories"
      :products="products"
      :services="services"
      :readonly="readonly"
      @items-changed="emit('catalog-changed')"
    />

    <p
      v-if="lockLeadFields && leadId && !readonly"
      class="text-xs text-gray-500 dark:text-gray-400"
    >
      {{ t('opportunities.fields.estimatedValueSyncLead') }}
    </p>
  </div>
</template>
