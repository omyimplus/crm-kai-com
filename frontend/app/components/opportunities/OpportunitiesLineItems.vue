<script setup lang="ts">
import type { Category, Product, Service } from '~/types/crm'
import type { OpportunityLineItemDraft } from '~/types/crm'
import type { OpportunityLineType } from '~/utils/masterCategoryCascade'
import {
  canPickCatalogItem,
  cascadeOptions,
  categoriesForModule,
  maxCascadeLevels,
  resolveCategoryPath
} from '~/utils/masterCategoryCascade'
import {
  computeLineTotal,
  productSelectOptions,
  serviceSelectOptions,
  syncLineItemTotals
} from '~/utils/masterOpportunityLineItems'
import { defaultMasterServiceFormInput } from '~/utils/masterService'
import { defaultMasterProductFormInput } from '~/utils/masterProduct'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import { SERVICE_CATEGORY_MODULE_KEY, CATEGORY_MODULE_KEY } from '~/config/masterCategory'

const lineItems = defineModel<OpportunityLineItemDraft[]>({ required: true })

const props = withDefaults(defineProps<{
  productCategories: Category[]
  serviceCategories: Category[]
  products: Product[]
  services: Service[]
  readonly?: boolean
}>(), {
  readonly: false
})

const emit = defineEmits<{
  'items-changed': []
}>()

const { t } = useI18n()
const { formatCurrency } = useFormat()
const { create: createProduct } = useProducts()
const { create: createService } = useServices()

const quickCreateOpen = ref(false)
const quickCreateLineId = ref<string | null>(null)
const quickCreateType = ref<OpportunityLineType>('product')
const quickCreateCategoryId = ref<string | null>(null)
const savingQuickCreate = ref(false)
const quickCreateError = ref('')

const productForm = ref(defaultMasterProductFormInput())
const serviceForm = ref(defaultMasterServiceFormInput())

const totalValue = computed(() =>
  lineItems.value.reduce((sum, row) => sum + computeLineTotal(row.quantity, row.unit_price), 0)
)

function categoriesForLine(lineType: OpportunityLineType) {
  return lineType === 'product'
    ? categoriesForModule(props.productCategories, CATEGORY_MODULE_KEY)
    : categoriesForModule(props.serviceCategories, SERVICE_CATEGORY_MODULE_KEY)
}

function updateRow(index: number, patch: Partial<OpportunityLineItemDraft>) {
  lineItems.value = lineItems.value.map((row, rowIndex) =>
    rowIndex === index ? syncLineItemTotals({ ...row, ...patch }) : row
  )
}

function setLineType(index: number, lineType: OpportunityLineType) {
  updateRow(index, {
    line_type: lineType,
    category_path: Array.from({ length: maxCascadeLevels(lineType) }, () => null),
    category_id: null,
    product_id: null,
    service_id: null,
    item_name: '',
    unit_price: '0'
  })
}

function setCascadeLevel(index: number, level: number, categoryId: string | null) {
  const row = lineItems.value[index]
  if (!row) return
  const nextPath = [...row.category_path]
  nextPath[level] = categoryId
  for (let i = level + 1; i < nextPath.length; i += 1) {
    nextPath[i] = null
  }
  const leafId = resolveCategoryPath(categoriesForLine(row.line_type), nextPath)
  updateRow(index, {
    category_path: nextPath,
    category_id: leafId,
    product_id: null,
    service_id: null,
    item_name: ''
  })
}

function itemOptionsForRow(row: OpportunityLineItemDraft) {
  if (!canPickCatalogItem(categoriesForLine(row.line_type), row.category_id, row.line_type)) {
    return []
  }
  return row.line_type === 'product'
    ? productSelectOptions(props.products, row.category_id)
    : serviceSelectOptions(props.services, row.category_id)
}

function setItemId(index: number, value: string | null) {
  const row = lineItems.value[index]
  if (!row || !value) return
  const options = itemOptionsForRow(row)
  const match = options.find(option => option.value === value)
  if (row.line_type === 'product') {
    updateRow(index, {
      product_id: value,
      service_id: null,
      item_name: match?.label.split(' — ').slice(1).join(' — ') ?? row.item_name,
      unit_price: String(match?.price ?? row.unit_price)
    })
  } else {
    updateRow(index, {
      service_id: value,
      product_id: null,
      item_name: match?.label.split(' — ').slice(1).join(' — ') ?? row.item_name,
      unit_price: String(match?.price ?? row.unit_price)
    })
  }
}

function selectedItemId(row: OpportunityLineItemDraft) {
  return row.line_type === 'product' ? row.product_id : row.service_id
}

function addRow(lineType: OpportunityLineType = 'product') {
  lineItems.value = [
    ...lineItems.value,
    {
      id: crypto.randomUUID(),
      line_type: lineType,
      category_path: Array.from({ length: maxCascadeLevels(lineType) }, () => null),
      category_id: null,
      product_id: null,
      service_id: null,
      item_name: '',
      line_description: '',
      quantity: '1',
      unit_price: '0',
      line_total: '0'
    }
  ]
}

function removeRow(id: string) {
  lineItems.value = lineItems.value.filter(row => row.id !== id)
}

function openQuickCreate(index: number) {
  const row = lineItems.value[index]
  if (!row?.category_id) return
  quickCreateLineId.value = row.id
  quickCreateType.value = row.line_type
  quickCreateCategoryId.value = row.category_id
  quickCreateError.value = ''
  if (row.line_type === 'product') {
    productForm.value = {
      ...defaultMasterProductFormInput(),
      category_id: row.category_id
    }
  } else {
    serviceForm.value = {
      ...defaultMasterServiceFormInput(),
      category_id: row.category_id
    }
  }
  quickCreateOpen.value = true
}

async function saveQuickCreate() {
  quickCreateError.value = ''
  savingQuickCreate.value = true
  try {
    const lineIndex = lineItems.value.findIndex(row => row.id === quickCreateLineId.value)
    if (lineIndex < 0) return

    if (quickCreateType.value === 'product') {
      const created = await createProduct(productForm.value)
      emit('items-changed')
      setItemId(lineIndex, created.id)
    } else {
      const created = await createService(serviceForm.value)
      emit('items-changed')
      setItemId(lineIndex, created.id)
    }
    quickCreateOpen.value = false
  } catch (error) {
    quickCreateError.value = error instanceof Error ? error.message : t('opportunities.lineItems.quickCreateFailed')
  } finally {
    savingQuickCreate.value = false
  }
}

function cascadeParentId(
  categories: Category[],
  path: (string | null)[],
  level: number
) {
  if (level === 0) return null
  return path[level - 1] ?? null
}
</script>

<template>
  <AppFormSection
    :title="t('opportunities.lineItems.title')"
    icon="i-lucide-list"
    icon-class="bg-teal-100 text-teal-700 dark:bg-teal-950/60 dark:text-teal-300"
  >
    <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
      <p class="text-sm text-gray-600 dark:text-gray-300">
        {{ t('opportunities.lineItems.totalValue') }}
        <span class="font-semibold text-gray-900 dark:text-gray-100">
          {{ formatCurrency(totalValue) }}
        </span>
      </p>
      <div
        v-if="!readonly"
        class="flex flex-wrap gap-2"
      >
        <UButton
          size="sm"
          variant="soft"
          color="primary"
          icon="i-lucide-plus"
          @click="addRow('product')"
        >
          {{ t('opportunities.lineItems.addProduct') }}
        </UButton>
        <UButton
          size="sm"
          variant="soft"
          color="neutral"
          icon="i-lucide-plus"
          @click="addRow('service')"
        >
          {{ t('opportunities.lineItems.addService') }}
        </UButton>
      </div>
    </div>

    <p
      v-if="!lineItems.length"
      class="rounded-xl border border-dashed border-gray-300 px-4 py-8 text-center text-sm text-gray-500 dark:border-gray-600 dark:text-gray-400"
    >
      {{ t('opportunities.lineItems.empty') }}
    </p>

    <div
      v-else
      class="overflow-hidden rounded-xl border border-gray-200 dark:border-gray-800"
    >
      <div class="overflow-x-auto">
        <table class="min-w-full text-sm">
          <thead class="bg-sky-100 text-sky-950 dark:bg-sky-950/40 dark:text-sky-100">
            <tr>
              <th class="w-12 px-3 py-2 text-start font-semibold">
                {{ t('opportunities.lineItems.columns.no') }}
              </th>
              <th class="min-w-[28rem] px-3 py-2 text-start font-semibold">
                {{ t('opportunities.lineItems.columns.item') }}
              </th>
              <th class="w-24 px-3 py-2 text-end font-semibold">
                {{ t('opportunities.lineItems.columns.qty') }}
              </th>
              <th class="w-32 px-3 py-2 text-end font-semibold">
                {{ t('opportunities.lineItems.columns.unitPrice') }}
              </th>
              <th class="w-32 px-3 py-2 text-end font-semibold">
                {{ t('opportunities.lineItems.columns.total') }}
              </th>
              <th
                v-if="!readonly"
                class="w-12 px-2 py-2"
              />
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-gray-800">
            <tr
              v-for="(row, index) in lineItems"
              :key="row.id"
              class="align-top bg-white dark:bg-gray-950"
            >
              <td class="px-3 py-3 text-gray-500">
                {{ index + 1 }}
              </td>
              <td class="px-3 py-3">
                <div class="space-y-3">
                  <div class="inline-flex rounded-lg border border-gray-200 p-1 dark:border-gray-700">
                    <UButton
                      type="button"
                      size="xs"
                      :variant="row.line_type === 'product' ? 'solid' : 'ghost'"
                      :disabled="readonly"
                      @click="setLineType(index, 'product')"
                    >
                      {{ t('opportunities.lineItems.types.product') }}
                    </UButton>
                    <UButton
                      type="button"
                      size="xs"
                      :variant="row.line_type === 'service' ? 'solid' : 'ghost'"
                      :disabled="readonly"
                      @click="setLineType(index, 'service')"
                    >
                      {{ t('opportunities.lineItems.types.service') }}
                    </UButton>
                  </div>

                  <div class="grid gap-2 sm:grid-cols-3">
                    <USelectMenu
                      v-for="level in maxCascadeLevels(row.line_type)"
                      :key="`${row.id}-level-${level}`"
                      :model-value="row.category_path[level - 1]"
                      :items="cascadeOptions(
                        categoriesForLine(row.line_type),
                        cascadeParentId(categoriesForLine(row.line_type), row.category_path, level - 1)
                      )"
                      value-key="value"
                      :disabled="readonly || (level > 1 && !row.category_path[level - 2])"
                      :class="appFormFieldClass"
                      :ui="appSelectMenuUi"
                      :placeholder="t('opportunities.lineItems.categoryLevel', { level })"
                      @update:model-value="setCascadeLevel(index, level - 1, normalizeSelectValue($event))"
                    />
                  </div>

                  <USelectMenu
                    v-if="canPickCatalogItem(categoriesForLine(row.line_type), row.category_id, row.line_type)"
                    :model-value="selectedItemId(row)"
                    :items="[
                      ...itemOptionsForRow(row),
                      { value: '__create__', label: t('opportunities.lineItems.addItemOption') }
                    ]"
                    value-key="value"
                    searchable
                    :disabled="readonly"
                    :class="appFormFieldClass"
                    :ui="appSelectMenuUi"
                    :placeholder="t('opportunities.lineItems.itemPlaceholder')"
                    @update:model-value="(value) => {
                      if (value === '__create__') openQuickCreate(index)
                      else setItemId(index, normalizeSelectValue(value))
                    }"
                  />
                  <p
                    v-else-if="row.category_id"
                    class="text-xs text-amber-700 dark:text-amber-300"
                  >
                    {{ row.line_type === 'product'
                      ? t('opportunities.lineItems.pickCategoryProduct')
                      : t('opportunities.lineItems.pickCategoryService') }}
                  </p>

                  <UTextarea
                    :model-value="row.line_description"
                    :readonly="readonly"
                    :rows="2"
                    :class="appFormFieldClass"
                    :ui="appTextareaUi"
                    :placeholder="t('opportunities.lineItems.descriptionPlaceholder')"
                    @update:model-value="updateRow(index, { line_description: String($event ?? '') })"
                  />
                </div>
              </td>
              <td class="px-3 py-3">
                <UInput
                  :model-value="row.quantity"
                  type="number"
                  min="0.0001"
                  step="any"
                  :readonly="readonly"
                  :class="appFormFieldClass"
                  :ui="appInputUi"
                  @update:model-value="updateRow(index, { quantity: String($event ?? '1') })"
                />
              </td>
              <td class="px-3 py-3">
                <UInput
                  :model-value="row.unit_price"
                  type="number"
                  min="0"
                  step="any"
                  :readonly="readonly"
                  :class="appFormFieldClass"
                  :ui="appInputUi"
                  @update:model-value="updateRow(index, { unit_price: String($event ?? '0') })"
                />
              </td>
              <td class="px-3 py-3 text-end font-medium tabular-nums">
                {{ formatCurrency(computeLineTotal(row.quantity, row.unit_price)) }}
              </td>
              <td
                v-if="!readonly"
                class="px-2 py-3"
              >
                <UButton
                  variant="ghost"
                  color="error"
                  icon="i-lucide-trash-2"
                  size="xs"
                  :aria-label="t('common.delete')"
                  @click="removeRow(row.id)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <AppDialog
      v-model:open="quickCreateOpen"
      :title="quickCreateType === 'product'
        ? t('opportunities.lineItems.quickCreateProduct')
        : t('opportunities.lineItems.quickCreateService')"
      size="lg"
    >
      <p
        v-if="quickCreateError"
        class="mb-3 text-sm text-red-600 dark:text-red-400"
        role="alert"
      >
        {{ quickCreateError }}
      </p>

      <div
        v-if="quickCreateType === 'product'"
        class="grid gap-4 sm:grid-cols-2"
      >
        <UFormField
          :label="t('masterData.products.fields.code')"
          required
        >
          <UInput
            v-model="productForm.product_code"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>
        <UFormField
          :label="t('masterData.products.fields.name')"
          required
        >
          <UInput
            v-model="productForm.name"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>
        <UFormField
          :label="t('masterData.products.fields.listPrice')"
          class="sm:col-span-2"
        >
          <UInput
            v-model.number="productForm.list_price"
            type="number"
            min="0"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>
      </div>

      <div
        v-else
        class="grid gap-4 sm:grid-cols-2"
      >
        <UFormField
          :label="t('appMenu.service.fields.code')"
          required
        >
          <UInput
            v-model="serviceForm.service_code"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>
        <UFormField
          :label="t('appMenu.service.fields.name')"
          required
        >
          <UInput
            v-model="serviceForm.name"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>
        <UFormField
          :label="t('appMenu.service.fields.kind')"
        >
          <USelectMenu
            v-model="serviceForm.service_kind"
            :items="['repair', 'maintenance', 'installation', 'consulting', 'other'].map(value => ({
              value,
              label: t(`appMenu.service.options.kind.${value}`)
            }))"
            value-key="value"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>
        <UFormField
          :label="t('appMenu.service.fields.listPrice')"
        >
          <UInput
            v-model.number="serviceForm.list_price"
            type="number"
            min="0"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>
      </div>

      <template #footer>
        <AppDialogFooter @cancel="quickCreateOpen = false">
          <UButton
            color="primary"
            :loading="savingQuickCreate"
            @click="saveQuickCreate"
          >
            {{ t('common.save') }}
          </UButton>
        </AppDialogFooter>
      </template>
    </AppDialog>
  </AppFormSection>
</template>
