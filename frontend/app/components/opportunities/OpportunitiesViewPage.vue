<script setup lang="ts">
import type { Category, Company, Opportunity, OpportunityLineItemDraft, PipelineStage, Product, SalesTeam, Service, TaskAssignee } from '~/types/crm'
import {
  opportunityToFormInput,
  defaultOpportunityFormInput
} from '~/utils/masterOpportunities'
import {
  defaultOpportunityLineItemDraft,
  opportunityLineItemsToDrafts
} from '~/utils/masterOpportunityLineItems'
import { SERVICE_CATEGORY_MODULE_KEY, CATEGORY_MODULE_KEY } from '~/config/masterCategory'

const props = defineProps<{
  opportunityId: string
}>()

const { t } = useI18n()
const { ensurePermissions, canWriteModule } = usePermissions()
const { list, listLineItems, remove, ensureDefaults } = useOpportunities()
const { getDefaultPipeline } = useDeals()
const { listAssignees } = useTasks()
const { list: listCompanies } = useCompanies()
const { list: listSalesTeams } = useSalesTeams()
const { list: listCategories } = useCategories()
const { list: listProducts } = useProducts()
const { list: listServices } = useServices()

await ensurePermissions()

const loading = ref(true)
const opportunity = ref<Opportunity | null>(null)
const form = ref(defaultOpportunityFormInput())
const lineItems = ref<OpportunityLineItemDraft[]>([])
const stages = ref<PipelineStage[]>([])
const assignees = ref<TaskAssignee[]>([])
const companies = ref<Company[]>([])
const salesTeams = ref<SalesTeam[]>([])
const productCategories = ref<Category[]>([])
const serviceCategories = ref<Category[]>([])
const products = ref<Product[]>([])
const services = ref<Service[]>([])
const deleteOpen = ref(false)

const canWrite = computed(() => canWriteModule('app.opportunity'))

try {
  await ensureDefaults()
  const [pipelineData, assigneeRows, companyRows, teamRows, productCatResult, serviceCatResult, productResult, serviceResult, rows] = await Promise.all([
    getDefaultPipeline(),
    listAssignees(),
    listCompanies(),
    listSalesTeams(),
    listCategories(CATEGORY_MODULE_KEY).catch(() => [] as Category[]),
    listCategories(SERVICE_CATEGORY_MODULE_KEY).catch(() => [] as Category[]),
    listProducts().catch(() => [] as Product[]),
    listServices().catch(() => [] as Service[]),
    list()
  ])
  stages.value = pipelineData.stages
  assignees.value = assigneeRows
  companies.value = companyRows
  salesTeams.value = teamRows
  productCategories.value = productCatResult
  serviceCategories.value = serviceCatResult
  products.value = productResult
  services.value = serviceResult

  const row = rows.find(item => item.id === props.opportunityId)
  if (!row) {
    await navigateTo('/app/opportunities')
  } else {
    opportunity.value = row
    form.value = opportunityToFormInput(row)
    const itemRows = await listLineItems(row.id)
    lineItems.value = itemRows.length
      ? opportunityLineItemsToDrafts(itemRows, [...productCatResult, ...serviceCatResult])
      : [defaultOpportunityLineItemDraft()]
  }
} catch (error) {
  console.error(error)
  await navigateTo('/app/opportunities')
} finally {
  loading.value = false
}

async function confirmDelete() {
  if (!opportunity.value) return
  try {
    await remove(opportunity.value.id)
    deleteOpen.value = false
    await navigateTo('/app/opportunities')
  } catch (error) {
    console.error(error)
  }
}
</script>

<template>
  <div>
    <UButton
      to="/app/opportunities"
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
      v-else-if="opportunity"
      class="lg:grid lg:grid-cols-[minmax(0,1fr)_17rem] lg:items-start lg:gap-6"
    >
      <div class="min-w-0 space-y-6">
        <div>
          <div class="flex flex-wrap items-center gap-2">
            <h1 class="text-2xl font-bold font-heading text-gray-900 dark:text-gray-100">
              {{ opportunity.title }}
            </h1>
            <OpportunitiesStageBadge
              :stage-name="opportunity.stage_name"
              :stage-color="opportunity.stage_color"
              :probability="opportunity.probability"
            />
          </div>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ opportunity.opportunity_code }} · {{ t('opportunities.viewSubtitle') }}
          </p>
        </div>

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
          :opportunity-code="opportunity.opportunity_code"
          :lead-code="opportunity.lead_code"
          :lead-id="opportunity.lead_id"
          :lock-lead-fields="Boolean(opportunity.lead_id)"
          :customer-in-form="Boolean(opportunity.lead_id)"
          readonly
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0 lg:self-start">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
            {{ t('opportunities.actions') }}
          </p>
          <UButton
            v-if="canWrite"
            block
            size="lg"
            icon="i-lucide-pencil"
            :to="`/app/opportunities/${opportunity.id}/edit`"
          >
            {{ t('common.edit') }}
          </UButton>
          <UButton
            v-if="opportunity.lead_id"
            block
            class="mt-2"
            variant="soft"
            icon="i-lucide-user-plus"
            :to="`/app/leads/${opportunity.lead_id}`"
          >
            {{ t('opportunities.viewLead') }}
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
      :title="t('opportunities.deleteTitle')"
      size="sm"
    >
      <p class="text-sm text-gray-600 dark:text-gray-300">
        {{ t('opportunities.deleteConfirm', { name: opportunity?.title ?? '' }) }}
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
