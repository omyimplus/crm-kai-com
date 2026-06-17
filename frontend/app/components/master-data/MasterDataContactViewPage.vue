<script setup lang="ts">
import { contactDisplayName, contactToFormInput } from '~/utils/masterContact'

const props = defineProps<{
  contactId: string
}>()

const { t } = useI18n()
const { get } = useContacts()
const { list: listCompanies } = useCompanies()

const loading = ref(true)
const form = ref(contactToFormInput({
  id: '',
  org_id: '',
  company_id: null,
  first_name: '',
  last_name: null,
  email: null,
  phone: null,
  mobile: null,
  job_title: null,
  department: null,
  contact_role: 'other',
  is_main_contact: false,
  notes: null,
  owner_id: null,
  created_at: ''
}))
const companies = ref<{ label: string, value: string }[]>([])
const deleteOpen = ref(false)

try {
  const [row, companyRows] = await Promise.all([
    get(props.contactId),
    listCompanies()
  ])
  form.value = contactToFormInput(row)
  companies.value = companyRows.map(c => ({ label: c.name, value: c.id }))
} catch (e) {
  console.error(e)
  await navigateTo('/app/contact')
} finally {
  loading.value = false
}

function onDeleted() {
  navigateTo('/app/contact')
}
</script>

<template>
  <div>
    <UButton
      to="/app/contact"
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
            {{ contactDisplayName(form) }}
          </h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ t('masterData.contact.viewSubtitle') }}
          </p>
        </div>

        <MasterDataContactForm
          v-model="form"
          :customer-options="companies"
          readonly
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.contact.actions') }}
          </p>
          <UButton
            block
            size="lg"
            icon="i-lucide-pencil"
            :to="`/app/contact/${contactId}/edit`"
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
            to="/app/contact"
          >
            {{ t('common.back') }}
          </UButton>
        </UCard>
      </aside>
    </div>

    <MasterDataContactDeleteModal
      v-model:open="deleteOpen"
      :contact-id="contactId"
      :contact-name="contactDisplayName(form)"
      @deleted="onDeleted"
    />
  </div>
</template>
