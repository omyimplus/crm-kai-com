<script setup lang="ts">
import type { Company, Contact } from '~/types/crm'
import { appTableBadgeClass, appTableTextClass } from '~/config/appFormUi'
import { contactDisplayName } from '~/utils/masterContact'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  companyId: string | null
  linkedContactId?: string | null
  linkedContactName?: string | null
}>()

const { t } = useI18n()
const { get, getDefaultBillAddress } = useCompanies()
const { listByCompany } = useContacts()

const loading = ref(false)
const errorMsg = ref('')
const company = ref<Company | null>(null)
const address = ref<string | null>(null)
const contacts = ref<Contact[]>([])

const dialogTitle = computed(() =>
  company.value?.name ?? props.linkedContactName ?? t('tasks.customerInfo.titleFallback')
)

const linkedContact = computed(() => {
  if (!props.linkedContactId) return null
  return contacts.value.find(row => row.id === props.linkedContactId) ?? null
})

function displayValue(value: string | null | undefined) {
  return value?.trim() || t('common.empty')
}

async function loadCustomer(companyId: string) {
  loading.value = true
  errorMsg.value = ''
  company.value = null
  address.value = null
  contacts.value = []

  try {
    const [companyRow, billAddress, contactRows] = await Promise.all([
      get(companyId),
      getDefaultBillAddress(companyId),
      listByCompany(companyId)
    ])
    company.value = companyRow
    address.value = billAddress?.address?.trim() || companyRow.address?.trim() || null
    contacts.value = contactRows
  } catch (error) {
    console.error(error)
    errorMsg.value = t('tasks.customerInfo.loadFailed')
  } finally {
    loading.value = false
  }
}

watch(
  () => [open.value, props.companyId] as const,
  ([isOpen, companyId]) => {
    if (!isOpen || !companyId) return
    loadCustomer(companyId)
  }
)
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="dialogTitle"
    :description="t('tasks.customerInfo.hint')"
    size="lg"
  >
    <div v-if="loading" class="py-6 text-center text-sm text-gray-500 dark:text-gray-400">
      {{ t('common.loading') }}
    </div>

    <p
      v-else-if="errorMsg"
      class="text-sm text-red-500"
    >
      {{ errorMsg }}
    </p>

    <div
      v-else-if="company"
      class="space-y-5"
    >
      <section
        v-if="linkedContactId"
        class="rounded-xl border border-primary/25 bg-primary/5 p-4 dark:border-primary/35 dark:bg-primary/10"
      >
        <p class="text-xs font-semibold uppercase tracking-wide text-primary">
          {{ t('tasks.customerInfo.linkedContact') }}
        </p>
        <p class="mt-2 font-semibold text-gray-900 dark:text-gray-100">
          {{ linkedContact ? contactDisplayName(linkedContact) : (linkedContactName || t('common.empty')) }}
        </p>
        <dl
          v-if="linkedContact"
          class="mt-3 grid gap-2 text-sm sm:grid-cols-2"
          :class="appTableTextClass"
        >
          <div>
            <dt class="text-gray-500 dark:text-gray-400">{{ t('masterData.customer.fields.email') }}</dt>
            <dd class="mt-0.5 text-gray-900 dark:text-gray-100">
              <a
                v-if="linkedContact.email"
                :href="`mailto:${linkedContact.email}`"
                class="text-primary hover:underline"
              >
                {{ linkedContact.email }}
              </a>
              <span v-else>{{ t('common.empty') }}</span>
            </dd>
          </div>
          <div>
            <dt class="text-gray-500 dark:text-gray-400">{{ t('masterData.customer.fields.phone') }}</dt>
            <dd class="mt-0.5 text-gray-900 dark:text-gray-100">
              <a
                v-if="linkedContact.phone"
                :href="`tel:${linkedContact.phone}`"
                class="text-primary hover:underline"
              >
                {{ linkedContact.phone }}
              </a>
              <span v-else>{{ t('common.empty') }}</span>
            </dd>
          </div>
        </dl>
      </section>

      <section>
        <h3 class="text-sm font-semibold font-heading text-gray-900 dark:text-gray-100">
          {{ t('tasks.customerInfo.contactSection') }}
        </h3>
        <dl
          class="mt-3 grid gap-3 text-sm sm:grid-cols-2"
          :class="appTableTextClass"
        >
          <div>
            <dt class="text-gray-500 dark:text-gray-400">{{ t('masterData.customer.fields.phone') }}</dt>
            <dd class="mt-0.5 text-gray-900 dark:text-gray-100">
              <a
                v-if="company.phone"
                :href="`tel:${company.phone}`"
                class="text-primary hover:underline"
              >
                {{ company.phone }}
              </a>
              <span v-else>{{ t('common.empty') }}</span>
            </dd>
          </div>
          <div>
            <dt class="text-gray-500 dark:text-gray-400">{{ t('masterData.customer.fields.mobile') }}</dt>
            <dd class="mt-0.5 text-gray-900 dark:text-gray-100">
              <a
                v-if="company.mobile"
                :href="`tel:${company.mobile}`"
                class="text-primary hover:underline"
              >
                {{ company.mobile }}
              </a>
              <span v-else>{{ t('common.empty') }}</span>
            </dd>
          </div>
          <div class="sm:col-span-2">
            <dt class="text-gray-500 dark:text-gray-400">{{ t('masterData.customer.fields.email') }}</dt>
            <dd class="mt-0.5 text-gray-900 dark:text-gray-100">
              <a
                v-if="company.email"
                :href="`mailto:${company.email}`"
                class="text-primary hover:underline"
              >
                {{ company.email }}
              </a>
              <span v-else>{{ t('common.empty') }}</span>
            </dd>
          </div>
          <div class="sm:col-span-2">
            <dt class="text-gray-500 dark:text-gray-400">{{ t('tasks.customerInfo.address') }}</dt>
            <dd class="mt-0.5 whitespace-pre-line text-gray-900 dark:text-gray-100">
              {{ displayValue(address) }}
            </dd>
          </div>
        </dl>
      </section>

      <section>
        <h3 class="text-sm font-semibold font-heading text-gray-900 dark:text-gray-100">
          {{ t('masterData.customer.contactsPanel.title') }}
        </h3>
        <ul
          v-if="contacts.length"
          class="mt-3 divide-y divide-gray-200 dark:divide-gray-800"
        >
          <li
            v-for="contact in contacts"
            :key="contact.id"
            class="flex items-start justify-between gap-3 py-3 first:pt-0 last:pb-0"
          >
            <div class="min-w-0">
              <NuxtLink
                :to="`/app/contact/${contact.id}`"
                class="font-medium text-primary hover:underline"
              >
                {{ contactDisplayName(contact) }}
              </NuxtLink>
              <p
                class="mt-0.5 text-sm text-gray-500 dark:text-gray-400"
                :class="appTableTextClass"
              >
                <span v-if="contact.email">{{ contact.email }}</span>
                <span
                  v-if="contact.email && contact.phone"
                  class="mx-1"
                >·</span>
                <span v-if="contact.phone">{{ contact.phone }}</span>
                <span v-if="!contact.email && !contact.phone">{{ t('common.empty') }}</span>
              </p>
            </div>
            <div class="flex shrink-0 items-center gap-1">
              <UBadge
                v-if="contact.id === linkedContactId"
                color="primary"
                variant="subtle"
                size="xs"
                :class="appTableBadgeClass"
              >
                {{ t('tasks.customerInfo.linkedContactBadge') }}
              </UBadge>
              <UBadge
                v-if="contact.is_main_contact"
                color="neutral"
                variant="subtle"
                size="xs"
                :class="appTableBadgeClass"
              >
                {{ t('masterData.contact.fields.mainContact') }}
              </UBadge>
            </div>
          </li>
        </ul>
        <p
          v-else
          class="mt-3 text-sm text-gray-500 dark:text-gray-400"
        >
          {{ t('masterData.customer.contactsPanel.empty') }}
        </p>
      </section>
    </div>

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          v-if="companyId"
          color="primary"
          size="lg"
          icon="i-lucide-building-2"
          :to="`/app/customer/${companyId}`"
        >
          {{ t('tasks.customerInfo.openProfile') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
