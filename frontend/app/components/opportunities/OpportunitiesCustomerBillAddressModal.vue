<script setup lang="ts">
import { appFormErrorClass, appFormFieldClass, appFormSwitchBoxClass, appInputUi, appTextareaUi } from '~/config/appFormUi'
import {
  billAddressesFromLegacyAddress,
  companyToFormInput,
  formToCompanyPayload,
  mapCompanyAddressRows,
  normalizeCompanyAddressDefaults,
  type CustomerCompanyAddressDraft
} from '~/utils/masterCustomer'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  companyId: string
  customerName?: string | null
}>()

const emit = defineEmits<{
  saved: [payload: { address: string }]
}>()

const { t } = useI18n()
const { get, update, listBillAddresses, syncBillAddresses } = useCompanies()

const saving = ref(false)
const errorMsg = ref('')
const label = ref('')
const address = ref('')
const isDefault = ref(true)

const dialogTitle = computed(() =>
  props.customerName?.trim()
    ? t('opportunities.billToModal.titleNamed', { name: props.customerName.trim() })
    : t('opportunities.billToModal.title')
)

function resetForm(makeDefault: boolean) {
  label.value = ''
  address.value = ''
  isDefault.value = makeDefault
  errorMsg.value = ''
}

watch(
  () => [open.value, props.companyId] as const,
  async ([isOpen, companyId]) => {
    if (!isOpen || !companyId) return
    resetForm(true)
    try {
      const existing = await listBillAddresses(companyId)
      resetForm(existing.length === 0)
    } catch {
      resetForm(true)
    }
  }
)

async function save() {
  const trimmedAddress = address.value.trim()
  if (!trimmedAddress) {
    errorMsg.value = t('opportunities.billToModal.addressRequired')
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    const companyRow = await get(props.companyId)
    const existing = await listBillAddresses(props.companyId)
    const drafts: CustomerCompanyAddressDraft[] = existing.length
      ? mapCompanyAddressRows(existing)
      : billAddressesFromLegacyAddress(props.companyId, companyRow.address)

    const id = crypto.randomUUID()
    const makeDefault = isDefault.value || drafts.length === 0
    const nextDrafts = normalizeCompanyAddressDefaults([
      ...drafts.map(row => ({
        ...row,
        is_default: makeDefault ? false : row.is_default
      })),
      {
        id,
        label: label.value.trim(),
        address: trimmedAddress,
        is_default: makeDefault
      }
    ])

    await syncBillAddresses(props.companyId, nextDrafts)
    await update(props.companyId, formToCompanyPayload(companyToFormInput(companyRow), nextDrafts))

    emit('saved', { address: trimmedAddress })
    open.value = false
  } catch (error) {
    errorMsg.value = getSupabaseErrorMessage(error, t('opportunities.billToModal.saveFailed'))
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="dialogTitle"
    :description="t('opportunities.billToModal.subtitle')"
    size="md"
  >
    <div class="space-y-4">
      <p
        v-if="errorMsg"
        :class="appFormErrorClass"
        role="alert"
      >
        {{ errorMsg }}
      </p>

      <UFormField
        :label="t('masterData.customer.bill.label')"
        :class="appFormFieldClass"
      >
        <UInput
          v-model="label"
          :class="appFormFieldClass"
          :ui="appInputUi"
          :placeholder="t('masterData.customer.bill.label')"
        />
      </UFormField>

      <UFormField
        :label="t('masterData.customer.bill.address')"
        required
        :class="appFormFieldClass"
      >
        <UTextarea
          v-model="address"
          :class="appFormFieldClass"
          :ui="appTextareaUi"
          :rows="4"
          :placeholder="t('masterData.customer.bill.address')"
        />
      </UFormField>

      <UFormField :class="appFormFieldClass">
        <div :class="appFormSwitchBoxClass">
          <USwitch v-model="isDefault" />
          <span class="text-sm text-gray-600 dark:text-gray-400">
            {{ t('masterData.customer.bill.useAsDefault') }}
          </span>
        </div>
      </UFormField>
    </div>

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          color="primary"
          size="lg"
          class="w-full sm:w-auto"
          icon="i-lucide-check"
          :loading="saving"
          @click="save"
        >
          {{ t('opportunities.billToModal.save') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
