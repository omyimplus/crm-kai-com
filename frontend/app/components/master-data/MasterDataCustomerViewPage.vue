<script setup lang="ts">
import type { Contact } from '~/types/crm'
import type { CustomerCompanyAddressDraft } from '~/utils/masterCustomer'
import {
  billAddressesFromLegacyAddress,
  companyToFormInput,
  defaultMasterCustomerFormInput,
  mapCompanyAddressRows
} from '~/utils/masterCustomer'
import { contactDisplayName } from '~/utils/masterContact'
import { appTableTextClass } from '~/config/appFormUi'

const props = defineProps<{
  customerId: string
}>()

const { t } = useI18n()
const { get, listBillAddresses, listShipAddresses } = useCompanies()
const { listByCompany } = useContacts()

const loading = ref(true)
const contactsLoading = ref(false)
const form = ref(defaultMasterCustomerFormInput())
const billAddresses = ref<CustomerCompanyAddressDraft[]>([])
const shipAddresses = ref<CustomerCompanyAddressDraft[]>([])
const contacts = ref<Contact[]>([])
const deleteOpen = ref(false)
const contactFormOpen = ref(false)

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

async function refreshContacts() {
  contactsLoading.value = true
  try {
    contacts.value = await listByCompany(props.customerId)
  } catch (e) {
    console.error(e)
    contacts.value = []
  } finally {
    contactsLoading.value = false
  }
}

await refreshContacts()

function onDeleted() {
  navigateTo('/app/customer')
}

function onContactCreated() {
  refreshContacts()
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

        <UCard class="rounded-2xl">
          <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
            <div>
              <h2 class="text-lg font-semibold font-heading">
                {{ t('masterData.customer.contactsPanel.title') }}
              </h2>
              <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                {{ t('masterData.customer.contactsPanel.subtitle') }}
              </p>
            </div>
            <UButton
              icon="i-lucide-user-plus"
              @click="contactFormOpen = true"
            >
              {{ t('masterData.customer.contactsPanel.add') }}
            </UButton>
          </div>

          <p
            v-if="contactsLoading"
            class="text-sm text-gray-500"
          >
            {{ t('common.loading') }}
          </p>

          <p
            v-else-if="!contacts.length"
            class="text-sm text-gray-500"
          >
            {{ t('masterData.customer.contactsPanel.empty') }}
          </p>

          <ul
            v-else
            class="divide-y divide-gray-200 dark:divide-gray-800"
          >
            <li
              v-for="contact in contacts"
              :key="contact.id"
              class="flex items-center justify-between gap-3 py-3 first:pt-0 last:pb-0"
            >
              <div class="min-w-0">
                <NuxtLink
                  :to="`/app/contact/${contact.id}`"
                  class="font-medium text-primary hover:underline"
                >
                  {{ contactDisplayName(contact) }}
                </NuxtLink>
                <p
                  class="mt-0.5 truncate text-sm text-gray-500 dark:text-gray-400"
                  :class="appTableTextClass"
                >
                  {{ contact.email || t('common.empty') }}
                  <span
                    v-if="contact.phone"
                    class="mx-1"
                  >·</span>
                  {{ contact.phone }}
                </p>
              </div>
              <div class="flex shrink-0 items-center gap-1">
                <UBadge
                  v-if="contact.is_main_contact"
                  color="primary"
                  variant="subtle"
                  size="xs"
                >
                  {{ t('masterData.contact.fields.mainContact') }}
                </UBadge>
                <AppIconButton
                  icon="i-lucide-eye"
                  :aria-label="t('masterData.contact.view')"
                  :to="`/app/contact/${contact.id}`"
                />
              </div>
            </li>
          </ul>
        </UCard>
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
            icon="i-lucide-user-plus"
            @click="contactFormOpen = true"
          >
            {{ t('masterData.customer.contactsPanel.add') }}
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

    <MasterDataContactFormModal
      v-model:open="contactFormOpen"
      :customer-id="customerId"
      :customer-name="form.name"
      @created="onContactCreated"
    />
  </div>
</template>
