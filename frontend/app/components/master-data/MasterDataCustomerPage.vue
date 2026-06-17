<script setup lang="ts">
import { appFormErrorClass } from '~/config/appFormUi'
import type { CustomerCompanyAddressDraft } from '~/utils/masterCustomer'
import {
  billAddressesFromLegacyAddress,
  companyToFormInput,
  defaultMasterCustomerFormInput,
  formToCompanyPayload,
  mapCompanyAddressRows,
  validateMasterCustomerForm
} from '~/utils/masterCustomer'

const props = defineProps<{
  mode: 'new' | 'edit'
  customerId?: string | null
}>()

const { t } = useI18n()
const {
  get,
  create,
  update,
  listBillAddresses,
  listShipAddresses,
  syncBillAddresses,
  syncShipAddresses
} = useCompanies()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterCustomerFormInput())
const billAddresses = ref<CustomerCompanyAddressDraft[]>([])
const shipAddresses = ref<CustomerCompanyAddressDraft[]>([])

const isEdit = computed(() => props.mode === 'edit')

const pageTitle = computed(() =>
  isEdit.value ? t('masterData.customer.editTitle') : t('masterData.customer.newTitle')
)
const pageSubtitle = computed(() =>
  isEdit.value ? t('masterData.customer.editSubtitle') : t('masterData.customer.newSubtitle')
)

if (isEdit.value && props.customerId) {
  try {
    const row = await get(props.customerId)
    form.value = companyToFormInput(row)
    const [bills, ships] = await Promise.all([
      listBillAddresses(props.customerId),
      listShipAddresses(props.customerId)
    ])
    billAddresses.value = bills.length
      ? mapCompanyAddressRows(bills)
      : billAddressesFromLegacyAddress(props.customerId, row.address)
    shipAddresses.value = mapCompanyAddressRows(ships)
  } catch (e) {
    console.error(e)
    await navigateTo('/app/customer')
  }
}

async function save() {
  const validationKey = validateMasterCustomerForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.customer.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    const payload = formToCompanyPayload(form.value, billAddresses.value)
    if (isEdit.value && props.customerId) {
      await update(props.customerId, payload)
      await syncBillAddresses(props.customerId, billAddresses.value)
      await syncShipAddresses(props.customerId, shipAddresses.value)
      await navigateTo(`/app/customer/${props.customerId}`)
    } else {
      const row = await create(payload)
      await syncBillAddresses(row.id, billAddresses.value)
      await syncShipAddresses(row.id, shipAddresses.value)
      await navigateTo(`/app/customer/${row.id}`)
    }
  } catch (e: unknown) {
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div>
    <UButton
      to="/app/customer"
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
        >
          {{ errorMsg }}
        </p>

        <MasterDataCustomerForm
          v-model="form"
          v-model:bill-addresses="billAddresses"
          v-model:ship-addresses="shipAddresses"
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.customer.actions') }}
          </p>
          <UButton
            type="button"
            block
            size="lg"
            icon="i-lucide-check"
            :loading="saving"
            @click="save"
          >
            {{ isEdit ? t('common.save') : t('masterData.customer.create') }}
          </UButton>
          <UButton
            type="button"
            block
            class="mt-2"
            variant="outline"
            color="neutral"
            to="/app/customer"
          >
            {{ t('common.cancel') }}
          </UButton>
          <p class="mt-4 text-xs leading-relaxed text-gray-500 dark:text-gray-400">
            {{ t('masterData.customer.creditBalanceHint') }}
          </p>
        </UCard>
      </aside>
    </form>
  </div>
</template>
