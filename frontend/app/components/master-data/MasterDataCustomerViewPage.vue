<script setup lang="ts">
import type { CustomerCompanyAddressDraft } from '~/utils/masterCustomer'
import {
  billAddressesFromLegacyAddress,
  companyToFormInput,
  defaultMasterCustomerFormInput,
  mapCompanyAddressRows
} from '~/utils/masterCustomer'

const props = defineProps<{
  customerId: string
}>()

const { t } = useI18n()
const { get, listBillAddresses, listShipAddresses } = useCompanies()

const loading = ref(true)
const form = ref(defaultMasterCustomerFormInput())
const billAddresses = ref<CustomerCompanyAddressDraft[]>([])
const shipAddresses = ref<CustomerCompanyAddressDraft[]>([])
const deleteOpen = ref(false)

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
} finally {
  loading.value = false
}

function onDeleted() {
  navigateTo('/app/customer')
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

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <div
      v-else
      class="lg:grid lg:grid-cols-[minmax(0,1fr)_17rem] lg:items-start lg:gap-6"
    >
      <div class="min-w-0 space-y-6">
        <div>
          <h1 class="text-2xl font-bold font-heading">
            {{ form.name || t('masterData.customer.viewTitle') }}
          </h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ t('masterData.customer.viewSubtitle') }}
          </p>
        </div>

        <MasterDataCustomerForm
          v-model="form"
          v-model:bill-addresses="billAddresses"
          v-model:ship-addresses="shipAddresses"
          readonly
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.customer.actions') }}
          </p>
          <UButton
            block
            size="lg"
            icon="i-lucide-pencil"
            :to="`/app/customer/${customerId}/edit`"
          >
            {{ t('common.edit') }}
          </UButton>
          <UButton
            block
            class="mt-2"
            variant="outline"
            color="error"
            icon="i-lucide-trash-2"
            @click="deleteOpen = true"
          >
            {{ t('common.delete') }}
          </UButton>
          <UButton
            block
            class="mt-2"
            variant="outline"
            color="neutral"
            to="/app/customer"
          >
            {{ t('common.back') }}
          </UButton>
        </UCard>
      </aside>
    </div>

    <MasterDataCustomerDeleteModal
      v-model:open="deleteOpen"
      :customer-id="customerId"
      :customer-name="form.name"
      @deleted="onDeleted"
    />
  </div>
</template>
