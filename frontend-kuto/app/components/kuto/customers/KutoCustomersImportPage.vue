<script setup lang="ts">
import {
  kutoCustomerImportColumnsForSheet,
  kutoCustomerImportDefaultMapping,
  kutoCustomerImportDuplicateRows,
  kutoCustomerImportFieldDefs,
  kutoCustomerImportFieldsForSheet,
  kutoCustomerImportHistory,
  kutoCustomerImportOwnerOptions,
  kutoCustomerImportPreviewCounts,
  kutoCustomerImportPreviewRows,
  kutoCustomerImportResultMock,
  kutoCustomerImportSampleFileName,
  kutoCustomerImportSheets,
  kutoCustomerImportSteps,
  kutoCustomerImportSummaryMeta,
  type KutoCustomerImportDuplicateAction,
  type KutoCustomerImportOwnerMode,
  type KutoCustomerImportPreviewStatus,
  type KutoCustomerImportSheetId,
  type KutoCustomerImportStepId
} from '~/config/kutoCustomersImportMock'
import {
  kutoControlClass,
  kutoKpiGrid4Class,
  kutoSelectMenuUi,
  kutoShellCardClass
} from '~/config/kutoTheme'
import {
  kutoCustomerTierBadgeClass,
  kutoCustomerTypeBadgeClass
} from '~/utils/kutoCustomerBadges'

const { t } = useI18n()

const currentStep = ref<KutoCustomerImportStepId>('upload')
const activeSheet = ref<KutoCustomerImportSheetId>('companies')
const fileName = ref<string | null>(null)
const fileInputRef = ref<HTMLInputElement | null>(null)
const mapping = ref<Record<string, string>>({ ...kutoCustomerImportDefaultMapping })
const previewFilter = ref<'all' | KutoCustomerImportPreviewStatus>('all')
const importing = ref(false)
const templateHint = ref(false)
const ownerMode = ref<KutoCustomerImportOwnerMode>('single')
const defaultOwner = ref('somsak')
const duplicateActions = ref<Record<string, KutoCustomerImportDuplicateAction>>({
  d1: 'skip',
  d2: 'import'
})

const stepIndex = computed(() =>
  kutoCustomerImportSteps.findIndex(s => s.id === currentStep.value)
)

const currentStepLabelKey = computed(() =>
  kutoCustomerImportSteps[stepIndex.value]?.labelKey ?? ''
)

const hasFile = computed(() => !!fileName.value)

const mappingItems = computed(() => [
  { label: t('kuto.customers.import.mapping.skip'), value: '' },
  ...kutoCustomerImportColumnsForSheet(activeSheet.value).map(col => ({
    label: col.header,
    value: col.key
  }))
])

const activeSheetFields = computed(() =>
  kutoCustomerImportFieldsForSheet(activeSheet.value)
)

const requiredMapped = computed(() =>
  kutoCustomerImportFieldDefs
    .filter(f => f.required)
    .every(f => !!mapping.value[f.key])
)

const filteredPreviewRows = computed(() => {
  if (previewFilter.value === 'all') return kutoCustomerImportPreviewRows
  return kutoCustomerImportPreviewRows.filter(r => r.status === previewFilter.value)
})

const previewCounts = computed(() =>
  kutoCustomerImportPreviewCounts(kutoCustomerImportPreviewRows)
)

const duplicateActionItems = computed(() => [
  { label: t('kuto.customers.import.duplicates.actionSkip'), value: 'skip' as const },
  { label: t('kuto.customers.import.duplicates.actionImport'), value: 'import' as const },
  { label: t('kuto.customers.import.duplicates.actionMerge'), value: 'merge' as const }
])

const ownerModeItems = computed(() => [
  { label: t('kuto.customers.import.owner.modeSingle'), value: 'single' as const },
  { label: t('kuto.customers.import.owner.modeRoundRobin'), value: 'roundRobin' as const },
  { label: t('kuto.customers.import.owner.modeByTier'), value: 'byTier' as const }
])

const ownerSelectItems = computed(() =>
  kutoCustomerImportOwnerOptions.map(o => ({
    label: t(o.labelKey),
    value: o.value
  }))
)

const confirmSummary = computed(() => ({
  importRows: previewCounts.value.valid + previewCounts.value.warning,
  errorRows: previewCounts.value.error,
  duplicateRows: kutoCustomerImportDuplicateRows.length,
  duplicateSkip: Object.values(duplicateActions.value).filter(a => a === 'skip').length,
  ownerLabel:
    ownerMode.value === 'single'
      ? t(`kuto.customers.import.owner.${defaultOwner.value}`)
      : t(`kuto.customers.import.owner.modeLabelValues.${ownerMode.value}`)
}))

const {
  page: historyPage,
  pagedItems: pagedHistory,
  totalItems: historyTotal,
  totalPages: historyTotalPages,
  rangeStart: historyRangeStart,
  rangeEnd: historyRangeEnd,
  pageSize: historyPageSize
} = useKutoPagination(computed(() => kutoCustomerImportHistory), 3)

const {
  page: previewPage,
  pagedItems: pagedPreviewRows,
  totalItems: previewTotal,
  totalPages: previewTotalPages,
  rangeStart: previewRangeStart,
  rangeEnd: previewRangeEnd,
  pageSize: previewPageSize
} = useKutoPagination(filteredPreviewRows, 5)

function openFilePicker() {
  fileInputRef.value?.click()
}

function onFileSelected(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (file) {
    fileName.value = file.name
    templateHint.value = false
  }
}

function onDropZoneClick() {
  openFilePicker()
}

function downloadTemplate() {
  templateHint.value = true
  fileName.value = kutoCustomerImportSampleFileName
  mapping.value = { ...kutoCustomerImportDefaultMapping }
}

function goToStep(step: KutoCustomerImportStepId) {
  currentStep.value = step
}

function goNext() {
  const idx = stepIndex.value
  if (idx < kutoCustomerImportSteps.length - 1) {
    currentStep.value = kutoCustomerImportSteps[idx + 1]!.id
  }
}

function goBack() {
  const idx = stepIndex.value
  if (idx > 0) currentStep.value = kutoCustomerImportSteps[idx - 1]!.id
}

async function runImport() {
  importing.value = true
  await new Promise(resolve => setTimeout(resolve, 900))
  importing.value = false
  currentStep.value = 'result'
}

function resetWizard() {
  currentStep.value = 'upload'
  activeSheet.value = 'companies'
  fileName.value = null
  mapping.value = { ...kutoCustomerImportDefaultMapping }
  previewFilter.value = 'all'
  ownerMode.value = 'single'
  defaultOwner.value = 'somsak'
  duplicateActions.value = { d1: 'skip', d2: 'import' }
  templateHint.value = false
  if (fileInputRef.value) fileInputRef.value.value = ''
}

function previewStatusClass(status: KutoCustomerImportPreviewStatus) {
  if (status === 'valid') return 'bg-emerald-50 text-emerald-700 ring-emerald-200/80'
  if (status === 'warning') return 'bg-amber-50 text-amber-700 ring-amber-200/80'
  return 'bg-red-50 text-red-700 ring-red-200/80'
}

function historyStatusClass(statusKey: string) {
  if (statusKey.includes('completed')) return 'bg-emerald-50 text-emerald-700 ring-emerald-200/80'
  if (statusKey.includes('partial')) return 'bg-amber-50 text-amber-700 ring-amber-200/80'
  return 'bg-red-50 text-red-700 ring-red-200/80'
}

function stepCircleClass(index: number) {
  if (index < stepIndex.value) return 'border-teal-500 bg-teal-500 text-white'
  if (index === stepIndex.value) return 'border-teal-500 bg-teal-500 text-white'
  return 'border-gray-200 bg-gray-50 text-gray-400'
}

function stepConnectorClass(index: number) {
  return index < stepIndex.value ? 'bg-teal-400' : 'bg-gray-200'
}

function stepLabelClass(index: number) {
  if (index === stepIndex.value) return 'text-teal-600'
  if (index < stepIndex.value) return 'text-teal-700/80'
  return 'text-gray-400'
}
</script>

<template>
  <div class="space-y-4">
    <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900">
          {{ t('kuto.customers.import.title') }}
        </h1>
        <p class="mt-1 text-sm text-shell-muted">
          {{ t('kuto.customers.import.subtitle') }}
        </p>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <NuxtLink
          to="/app/customers"
          :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-3 py-2 text-sm font-semibold text-shell-fg']"
        >
          <UIcon
            name="i-lucide-arrow-left"
            class="size-4"
          />
          {{ t('kuto.customers.import.backToList') }}
        </NuxtLink>
      </div>
    </div>

    <div :class="kutoKpiGrid4Class">
      <KutoKpiCard
        v-for="meta in kutoCustomerImportSummaryMeta"
        :key="meta.key"
        :label="t(meta.labelKey)"
        :value="meta.value"
        :accent="meta.accent"
        :icon="meta.icon"
        :icon-bg="meta.iconBg"
        :sub-label="t(meta.subKey)"
        class="h-full"
      />
    </div>

    <div
      class="overflow-hidden"
      :class="kutoShellCardClass"
    >
      <div class="border-b border-shell-border px-3 py-4 sm:px-4">
        <ol class="flex w-full items-start">
          <li
            v-for="(step, index) in kutoCustomerImportSteps"
            :key="step.id"
            class="flex min-w-0 flex-1 flex-col items-center"
          >
            <div class="flex w-full items-center">
              <div
                class="h-0.5 flex-1"
                :class="index === 0 ? 'bg-transparent' : stepConnectorClass(index - 1)"
              />
              <button
                type="button"
                class="flex shrink-0 flex-col items-center gap-1.5 px-0.5 disabled:cursor-default"
                :disabled="index > stepIndex"
                @click="index < stepIndex && goToStep(step.id)"
              >
                <span
                  class="inline-flex size-8 items-center justify-center rounded-full border text-xs font-bold"
                  :class="stepCircleClass(index)"
                >
                  <UIcon
                    v-if="index < stepIndex"
                    name="i-lucide-check"
                    class="size-3.5"
                  />
                  <span v-else>{{ index + 1 }}</span>
                </span>
              </button>
              <div
                class="h-0.5 flex-1"
                :class="index === kutoCustomerImportSteps.length - 1 ? 'bg-transparent' : stepConnectorClass(index)"
              />
            </div>
            <p
              class="mt-1 max-w-[4.5rem] text-center text-[10px] font-semibold leading-tight sm:max-w-none sm:text-xs"
              :class="stepLabelClass(index)"
            >
              {{ t(step.labelKey) }}
            </p>
          </li>
        </ol>
      </div>

      <div class="p-4 sm:p-6">
        <h2
          v-if="currentStep !== 'result'"
          class="mb-4 text-sm font-bold text-shell-fg"
        >
          {{ t('kuto.customers.import.stepTitle', { step: stepIndex + 1, label: t(currentStepLabelKey) }) }}
        </h2>

        <!-- Step 1: Upload -->
        <div
          v-if="currentStep === 'upload'"
          class="space-y-4"
        >
          <input
            ref="fileInputRef"
            type="file"
            accept=".csv,.xlsx,.xls"
            class="hidden"
            @change="onFileSelected"
          >
          <button
            type="button"
            class="flex w-full flex-col items-center justify-center rounded-xl border-2 border-dashed border-gray-300 bg-gray-50/50 px-6 py-12 transition-colors hover:border-teal-400 hover:bg-teal-50/30"
            @click="onDropZoneClick"
          >
            <UIcon
              name="i-lucide-upload-cloud"
              class="mb-3 size-10 text-teal-500"
            />
            <p class="text-sm font-semibold text-shell-fg">
              {{ t('kuto.customers.import.upload.dropTitle') }}
            </p>
            <p class="mt-1 text-xs text-shell-muted">
              {{ t('kuto.customers.import.upload.dropHint') }}
            </p>
            <p
              v-if="hasFile"
              class="mt-4 inline-flex items-center gap-2 text-sm font-medium text-teal-700"
            >
              <UIcon
                name="i-lucide-file-check-2"
                class="size-4"
              />
              {{ fileName }}
            </p>
          </button>
          <div class="flex justify-center">
            <button
              type="button"
              :class="[kutoControlClass, 'inline-flex items-center justify-center gap-1.5 px-5 py-2.5 text-sm font-semibold']"
              @click="downloadTemplate"
            >
              <UIcon
                name="i-lucide-download"
                class="size-4"
              />
              {{ t('kuto.customers.import.downloadTemplate') }}
            </button>
          </div>
          <p
            v-if="templateHint"
            class="text-center text-xs text-shell-muted"
          >
            {{ t('kuto.customers.import.templateMockHint') }}
          </p>
          <p class="text-center text-xs text-shell-muted">
            {{ t('kuto.customers.import.upload.sheetsHint') }}
          </p>
        </div>

        <!-- Step 2: Mapping -->
        <div
          v-else-if="currentStep === 'mapping'"
          class="space-y-4"
        >
          <div class="flex flex-wrap items-center justify-between gap-2">
            <p class="text-sm text-shell-muted">
              {{ t('kuto.customers.import.mapping.hint', { file: fileName }) }}
            </p>
            <span class="text-xs font-semibold text-teal-600">
              {{ t('kuto.customers.import.mapping.detected', { count: kutoCustomerImportColumnsForSheet(activeSheet).length }) }}
            </span>
          </div>
          <div class="flex flex-wrap gap-2">
            <button
              v-for="sheet in kutoCustomerImportSheets"
              :key="sheet.id"
              type="button"
              class="rounded-full px-3 py-1 text-xs font-semibold transition-colors"
              :class="activeSheet === sheet.id
                ? 'bg-teal-500 text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'"
              @click="activeSheet = sheet.id"
            >
              {{ t(sheet.labelKey) }}
            </button>
          </div>
          <div class="overflow-x-auto rounded-lg border border-shell-border">
            <table class="w-full min-w-[520px] text-left text-sm">
              <thead class="bg-gray-50 text-xs font-semibold text-shell-muted">
                <tr>
                  <th class="px-4 py-3">
                    {{ t('kuto.customers.import.mapping.colField') }}
                  </th>
                  <th class="px-4 py-3">
                    {{ t('kuto.customers.import.mapping.colColumn') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-shell-border">
                <tr
                  v-for="field in activeSheetFields"
                  :key="field.key"
                >
                  <td class="px-4 py-3 font-medium text-shell-fg">
                    {{ t(field.labelKey) }}
                    <span
                      v-if="field.required"
                      class="text-red-500"
                    >*</span>
                  </td>
                  <td class="px-4 py-3">
                    <USelectMenu
                      v-model="mapping[field.key]"
                      :items="mappingItems"
                      value-key="value"
                      :placeholder="t('kuto.customers.import.mapping.selectColumn')"
                      class="min-w-[12rem]"
                      :ui="kutoSelectMenuUi"
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Step 3: Preview -->
        <div
          v-else-if="currentStep === 'preview'"
          class="space-y-4"
        >
          <div class="grid gap-3 sm:grid-cols-3">
            <div class="rounded-lg border border-emerald-200 bg-emerald-50/60 px-4 py-3">
              <p class="text-xs font-medium text-emerald-700">
                {{ t('kuto.customers.import.preview.valid') }}
              </p>
              <p class="text-2xl font-bold text-emerald-700">
                {{ previewCounts.valid }}
              </p>
            </div>
            <div class="rounded-lg border border-amber-200 bg-amber-50/60 px-4 py-3">
              <p class="text-xs font-medium text-amber-700">
                {{ t('kuto.customers.import.preview.warning') }}
              </p>
              <p class="text-2xl font-bold text-amber-700">
                {{ previewCounts.warning }}
              </p>
            </div>
            <div class="rounded-lg border border-red-200 bg-red-50/60 px-4 py-3">
              <p class="text-xs font-medium text-red-700">
                {{ t('kuto.customers.import.preview.error') }}
              </p>
              <p class="text-2xl font-bold text-red-700">
                {{ previewCounts.error }}
              </p>
            </div>
          </div>

          <div class="flex flex-wrap gap-2">
            <button
              v-for="chip in (['all', 'valid', 'warning', 'error'] as const)"
              :key="chip"
              type="button"
              class="rounded-full px-3 py-1 text-xs font-semibold transition-colors"
              :class="previewFilter === chip
                ? 'bg-teal-500 text-white'
                : 'bg-gray-100 text-gray-600 hover:bg-gray-200'"
              @click="previewFilter = chip"
            >
              {{ t(`kuto.customers.import.preview.filter.${chip}`) }}
            </button>
          </div>

          <div>
            <div class="overflow-x-auto rounded-lg border border-shell-border">
              <table class="w-full min-w-[800px] text-left text-sm">
                <thead class="bg-gray-50 text-xs font-semibold text-shell-muted">
                  <tr>
                    <th class="px-3 py-3">
                      {{ t('kuto.customers.import.preview.colRow') }}
                    </th>
                    <th class="px-3 py-3">
                      {{ t('kuto.customers.list.col.customer') }}
                    </th>
                    <th class="px-3 py-3">
                      {{ t('kuto.customers.import.fields.taxId') }}
                    </th>
                    <th class="px-3 py-3">
                      {{ t('kuto.customers.list.col.type') }}
                    </th>
                    <th class="px-3 py-3">
                      {{ t('kuto.customers.list.col.tier') }}
                    </th>
                    <th class="px-3 py-3">
                      {{ t('kuto.customers.list.col.owner') }}
                    </th>
                    <th class="px-3 py-3">
                      {{ t('kuto.customers.import.preview.colStatus') }}
                    </th>
                    <th class="px-3 py-3">
                      {{ t('kuto.customers.import.preview.colMessage') }}
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-shell-border">
                  <tr
                    v-for="row in pagedPreviewRows"
                    :key="row.id"
                    :class="row.status === 'error' ? 'bg-red-50/40' : row.status === 'warning' ? 'bg-amber-50/30' : ''"
                  >
                    <td class="px-3 py-3 font-mono text-xs text-shell-muted">
                      {{ row.rowNo }}
                    </td>
                    <td class="max-w-[10rem] truncate px-3 py-3 font-medium text-shell-fg">
                      {{ row.company || '—' }}
                    </td>
                    <td class="px-3 py-3 font-mono text-xs text-shell-muted">
                      {{ row.taxId }}
                    </td>
                    <td class="px-3 py-3">
                      <span
                        class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                        :class="kutoCustomerTypeBadgeClass(row.customerTypeKey)"
                      >
                        {{ t(row.customerTypeKey) }}
                      </span>
                    </td>
                    <td class="px-3 py-3">
                      <span
                        class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                        :class="kutoCustomerTierBadgeClass(row.tierKey)"
                      >
                        {{ t(row.tierKey) }}
                      </span>
                    </td>
                    <td class="max-w-[8rem] truncate px-3 py-3 text-shell-muted">
                      {{ row.owner }}
                    </td>
                    <td class="px-3 py-3">
                      <span
                        class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                        :class="previewStatusClass(row.status)"
                      >
                        {{ t(`kuto.customers.import.preview.status.${row.status}`) }}
                      </span>
                    </td>
                    <td class="max-w-[12rem] truncate px-3 py-3 text-xs text-shell-muted">
                      {{ row.errorKey ? t(row.errorKey) : '—' }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <KutoPagination
              v-model:page="previewPage"
              :total-items="previewTotal"
              :total-pages="previewTotalPages"
              :range-start="previewRangeStart"
              :range-end="previewRangeEnd"
              :page-size="previewPageSize"
            />
          </div>
          <p class="text-xs text-shell-muted">
            {{ t('kuto.customers.import.preview.skipErrorsHint') }}
          </p>
        </div>

        <!-- Step 4: Duplicates -->
        <div
          v-else-if="currentStep === 'duplicates'"
          class="space-y-4"
        >
          <div class="flex flex-wrap items-center justify-between gap-2">
            <p class="text-sm text-shell-muted">
              {{ t('kuto.customers.import.duplicates.hint') }}
            </p>
            <span class="rounded-full bg-amber-100 px-2.5 py-0.5 text-xs font-bold text-amber-800">
              {{ t('kuto.customers.import.duplicates.found', { count: kutoCustomerImportDuplicateRows.length }) }}
            </span>
          </div>
          <div class="overflow-x-auto rounded-lg border border-shell-border">
            <table class="w-full min-w-[720px] text-left text-sm">
              <thead class="bg-gray-50 text-xs font-semibold text-shell-muted">
                <tr>
                  <th class="px-3 py-3">
                    {{ t('kuto.customers.import.preview.colRow') }}
                  </th>
                  <th class="px-3 py-3">
                    {{ t('kuto.customers.list.col.customer') }}
                  </th>
                  <th class="px-3 py-3">
                    {{ t('kuto.customers.import.fields.taxId') }}
                  </th>
                  <th class="px-3 py-3">
                    {{ t('kuto.customers.import.duplicates.colMatch') }}
                  </th>
                  <th class="px-3 py-3">
                    {{ t('kuto.customers.import.duplicates.colAction') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-shell-border">
                <tr
                  v-for="row in kutoCustomerImportDuplicateRows"
                  :key="row.id"
                  class="bg-amber-50/20"
                >
                  <td class="px-3 py-3 font-mono text-xs text-shell-muted">
                    {{ row.rowNo }}
                  </td>
                  <td class="px-3 py-3 font-medium text-shell-fg">
                    {{ row.company }}
                  </td>
                  <td class="px-3 py-3 font-mono text-xs text-shell-muted">
                    {{ row.taxId }}
                  </td>
                  <td class="px-3 py-3">
                    <span class="font-mono text-xs font-semibold text-teal-700">{{ row.matchCode }}</span>
                    <span class="mt-0.5 block text-xs text-shell-muted">{{ row.matchCompany }}</span>
                  </td>
                  <td class="px-3 py-3">
                    <USelectMenu
                      v-model="duplicateActions[row.id]"
                      :items="duplicateActionItems"
                      value-key="value"
                      class="min-w-[9rem]"
                      :ui="kutoSelectMenuUi"
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Step 5: Owner -->
        <div
          v-else-if="currentStep === 'owner'"
          class="mx-auto max-w-lg space-y-4"
        >
          <p class="text-sm text-shell-muted">
            {{ t('kuto.customers.import.owner.hint') }}
          </p>
          <div class="space-y-3 rounded-xl border border-shell-border bg-gray-50/60 p-4">
            <label class="block text-sm font-semibold text-shell-fg">
              {{ t('kuto.customers.import.owner.modeLabel') }}
            </label>
            <USelectMenu
              v-model="ownerMode"
              :items="ownerModeItems"
              value-key="value"
              class="w-full"
              :ui="kutoSelectMenuUi"
            />
            <div v-if="ownerMode === 'single'">
              <label class="mb-1.5 block text-sm font-semibold text-shell-fg">
                {{ t('kuto.customers.import.owner.defaultLabel') }}
              </label>
              <USelectMenu
                v-model="defaultOwner"
                :items="ownerSelectItems"
                value-key="value"
                class="w-full"
                :ui="kutoSelectMenuUi"
              />
            </div>
            <p
              v-else
              class="text-xs text-shell-muted"
            >
              {{ t(`kuto.customers.import.owner.modeHint.${ownerMode}`) }}
            </p>
          </div>
        </div>

        <!-- Step 6: Confirm -->
        <div
          v-else-if="currentStep === 'confirm'"
          class="mx-auto max-w-lg space-y-4"
        >
          <div class="rounded-xl border border-shell-border bg-gray-50/60 p-4">
            <h3 class="text-sm font-bold text-shell-fg">
              {{ t('kuto.customers.import.confirm.title') }}
            </h3>
            <dl class="mt-3 space-y-2 text-sm">
              <div class="flex justify-between gap-4">
                <dt class="text-shell-muted">
                  {{ t('kuto.customers.import.confirm.file') }}
                </dt>
                <dd class="font-medium text-shell-fg">
                  {{ fileName }}
                </dd>
              </div>
              <div class="flex justify-between gap-4">
                <dt class="text-shell-muted">
                  {{ t('kuto.customers.import.confirm.rows') }}
                </dt>
                <dd class="font-medium text-emerald-700">
                  {{ confirmSummary.importRows }}
                </dd>
              </div>
              <div class="flex justify-between gap-4">
                <dt class="text-shell-muted">
                  {{ t('kuto.customers.import.confirm.errors') }}
                </dt>
                <dd class="font-medium text-red-600">
                  {{ confirmSummary.errorRows }}
                </dd>
              </div>
              <div class="flex justify-between gap-4">
                <dt class="text-shell-muted">
                  {{ t('kuto.customers.import.confirm.duplicates') }}
                </dt>
                <dd class="font-medium text-amber-700">
                  {{ t('kuto.customers.import.confirm.duplicatesDetail', {
                    total: confirmSummary.duplicateRows,
                    skip: confirmSummary.duplicateSkip
                  }) }}
                </dd>
              </div>
              <div class="flex justify-between gap-4">
                <dt class="text-shell-muted">
                  {{ t('kuto.customers.import.confirm.owner') }}
                </dt>
                <dd class="font-medium text-shell-fg">
                  {{ confirmSummary.ownerLabel }}
                </dd>
              </div>
            </dl>
          </div>
          <p class="text-xs text-shell-muted">
            {{ t('kuto.customers.import.confirm.hint') }}
          </p>
        </div>

        <!-- Step 7: Result -->
        <div
          v-else-if="currentStep === 'result'"
          class="mx-auto max-w-lg space-y-5 text-center"
        >
          <div class="mx-auto flex size-16 items-center justify-center rounded-full bg-emerald-100 text-emerald-600">
            <UIcon
              name="i-lucide-circle-check-big"
              class="size-9"
            />
          </div>
          <div>
            <h2 class="text-lg font-bold text-shell-fg">
              {{ t('kuto.customers.import.result.title') }}
            </h2>
            <p class="mt-1 text-sm text-shell-muted">
              {{ t('kuto.customers.import.result.subtitle', { file: fileName }) }}
            </p>
          </div>
          <div class="grid grid-cols-2 gap-3 text-left sm:grid-cols-4">
            <div class="rounded-lg border border-emerald-200 bg-emerald-50/60 p-3">
              <p class="text-xs text-emerald-700">
                {{ t('kuto.customers.import.result.imported') }}
              </p>
              <p class="text-xl font-bold text-emerald-700">
                {{ kutoCustomerImportResultMock.imported }}
              </p>
            </div>
            <div class="rounded-lg border border-blue-200 bg-blue-50/60 p-3">
              <p class="text-xs text-blue-700">
                {{ t('kuto.customers.import.result.contacts') }}
              </p>
              <p class="text-xl font-bold text-blue-700">
                {{ kutoCustomerImportResultMock.contactsImported }}
              </p>
            </div>
            <div class="rounded-lg border border-amber-200 bg-amber-50/60 p-3">
              <p class="text-xs text-amber-700">
                {{ t('kuto.customers.import.result.skipped') }}
              </p>
              <p class="text-xl font-bold text-amber-700">
                {{ kutoCustomerImportResultMock.skipped }}
              </p>
            </div>
            <div class="rounded-lg border border-red-200 bg-red-50/60 p-3">
              <p class="text-xs text-red-700">
                {{ t('kuto.customers.import.result.failed') }}
              </p>
              <p class="text-xl font-bold text-red-700">
                {{ kutoCustomerImportResultMock.failed }}
              </p>
            </div>
          </div>
          <div class="flex flex-wrap items-center justify-center gap-2">
            <NuxtLink
              to="/app/customers"
              class="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-4 py-2 text-sm font-semibold text-white hover:bg-teal-600"
            >
              {{ t('kuto.customers.import.result.viewCustomers') }}
            </NuxtLink>
            <button
              type="button"
              :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-4 py-2 text-sm font-semibold']"
              @click="resetWizard"
            >
              {{ t('kuto.customers.import.result.importAnother') }}
            </button>
          </div>
          <p class="text-[11px] text-shell-muted">
            {{ t('kuto.customers.import.mockHint') }}
          </p>
        </div>
      </div>

      <div
        v-if="currentStep !== 'result'"
        class="flex flex-wrap items-center justify-between gap-3 border-t border-shell-border bg-gray-50/80 px-4 py-3 sm:px-6"
      >
        <button
          v-if="stepIndex > 0"
          type="button"
          :class="[kutoControlClass, 'inline-flex items-center gap-1.5 px-4 py-2 text-sm font-semibold']"
          @click="goBack"
        >
          <UIcon
            name="i-lucide-arrow-left"
            class="size-4"
          />
          {{ t('kuto.customers.import.actions.back') }}
        </button>
        <span v-else />

        <div class="flex flex-wrap items-center gap-2">
          <button
            v-if="currentStep === 'upload'"
            type="button"
            class="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-teal-600 disabled:cursor-not-allowed disabled:opacity-40"
            :disabled="!hasFile"
            @click="goNext"
          >
            {{ t('kuto.customers.import.actions.next') }}
            <UIcon
              name="i-lucide-arrow-right"
              class="size-4"
            />
          </button>
          <button
            v-else-if="currentStep === 'mapping'"
            type="button"
            class="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-teal-600 disabled:cursor-not-allowed disabled:opacity-40"
            :disabled="!requiredMapped"
            @click="goNext"
          >
            {{ t('kuto.customers.import.actions.next') }}
            <UIcon
              name="i-lucide-arrow-right"
              class="size-4"
            />
          </button>
          <button
            v-else-if="currentStep === 'preview' || currentStep === 'duplicates' || currentStep === 'owner'"
            type="button"
            class="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-teal-600"
            @click="goNext"
          >
            {{ t('kuto.customers.import.actions.next') }}
            <UIcon
              name="i-lucide-arrow-right"
              class="size-4"
            />
          </button>
          <button
            v-else-if="currentStep === 'confirm'"
            type="button"
            class="inline-flex items-center gap-1.5 rounded-lg bg-teal-500 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-teal-600 disabled:cursor-not-allowed disabled:opacity-40"
            :disabled="importing"
            @click="runImport"
          >
            <UIcon
              v-if="importing"
              name="i-lucide-loader-circle"
              class="size-4 animate-spin"
            />
            {{ importing ? t('kuto.customers.import.actions.importing') : t('kuto.customers.import.actions.import') }}
          </button>
        </div>
      </div>
    </div>

    <div
      class="overflow-hidden"
      :class="kutoShellCardClass"
    >
      <div class="border-b border-shell-border px-4 py-3 sm:px-5">
        <h2 class="text-sm font-bold text-shell-fg">
          {{ t('kuto.customers.import.history.title') }}
        </h2>
        <p class="text-xs text-shell-muted">
          {{ t('kuto.customers.import.history.subtitle') }}
        </p>
      </div>
      <div class="overflow-x-auto">
        <table class="w-full min-w-[720px] text-left text-sm">
          <thead class="bg-gray-50 text-xs font-semibold text-shell-muted">
            <tr>
              <th class="px-4 py-3">
                {{ t('kuto.customers.import.history.colFile') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.customers.import.history.colDate') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.customers.import.history.colUser') }}
              </th>
              <th class="px-3 py-3 text-center">
                {{ t('kuto.customers.import.history.colTotal') }}
              </th>
              <th class="px-3 py-3 text-center">
                {{ t('kuto.customers.import.history.colContacts') }}
              </th>
              <th class="px-3 py-3 text-center">
                {{ t('kuto.customers.import.history.colSuccess') }}
              </th>
              <th class="px-3 py-3 text-center">
                {{ t('kuto.customers.import.history.colFailed') }}
              </th>
              <th class="px-3 py-3">
                {{ t('kuto.customers.import.history.colStatus') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-shell-border">
            <tr
              v-for="row in pagedHistory"
              :key="row.id"
              class="hover:bg-gray-50/80"
            >
              <td class="px-4 py-3 font-medium text-shell-fg">
                <span class="inline-flex items-center gap-2">
                  <UIcon
                    name="i-lucide-file-spreadsheet"
                    class="size-4 text-teal-600"
                  />
                  {{ row.fileName }}
                </span>
              </td>
              <td class="whitespace-nowrap px-3 py-3 text-shell-muted">
                {{ row.importedAt }}
              </td>
              <td class="px-3 py-3 text-shell-muted">
                {{ row.importedBy }}
              </td>
              <td class="px-3 py-3 text-center font-medium">
                {{ row.totalRows }}
              </td>
              <td class="px-3 py-3 text-center font-medium text-blue-700">
                {{ row.contactRows ?? '—' }}
              </td>
              <td class="px-3 py-3 text-center font-medium text-emerald-700">
                {{ row.successRows }}
              </td>
              <td class="px-3 py-3 text-center font-medium text-red-600">
                {{ row.failedRows }}
              </td>
              <td class="px-3 py-3">
                <span
                  class="inline-flex rounded-full px-2 py-0.5 text-[11px] font-semibold ring-1 ring-inset"
                  :class="historyStatusClass(row.statusKey)"
                >
                  {{ t(row.statusKey) }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <KutoPagination
        v-model:page="historyPage"
        :total-items="historyTotal"
        :total-pages="historyTotalPages"
        :range-start="historyRangeStart"
        :range-end="historyRangeEnd"
        :page-size="historyPageSize"
      />
    </div>
  </div>
</template>
