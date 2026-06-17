<script setup lang="ts">
definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const route = useRoute()
const isEdit = computed(() => !!route.params.id && route.params.id !== 'new')
const contactId = computed(() => (isEdit.value ? String(route.params.id) : null))

const { ensureProfile } = useProfile()
const { list: listCompanies } = useCompanies()
const { get, create, update } = useContacts()

await ensureProfile()

const companies = await listCompanies()
const loading = ref(false)
const errorMsg = ref('')

const form = reactive({
  first_name: '',
  last_name: '',
  email: '',
  phone: '',
  job_title: '',
  company_id: null as string | null
})

if (isEdit.value && contactId.value) {
  const c = await get(contactId.value)
  form.first_name = c.first_name
  form.last_name = c.last_name || ''
  form.email = c.email || ''
  form.phone = c.phone || ''
  form.job_title = c.job_title || ''
  form.company_id = c.company_id
}

const companyOptions = computed(() =>
  companies.map(c => ({ label: c.name, value: c.id }))
)

async function save() {
  loading.value = true
  errorMsg.value = ''
  try {
    const payload = {
      first_name: form.first_name,
      last_name: form.last_name,
      email: form.email,
      phone: form.phone,
      mobile: '',
      company_id: form.company_id,
      job_title: form.job_title,
      department: '',
      contact_role: 'other' as const,
      is_main_contact: false,
      notes: ''
    }
    if (isEdit.value && contactId.value) {
      await update(contactId.value, payload)
    } else {
      await create(payload)
    }
    await navigateTo('/app/contacts')
  } catch (e: unknown) {
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="max-w-xl">
    <h1 class="text-2xl font-bold mb-6">
      {{ isEdit ? t('contacts.edit') : t('contacts.new') }}
    </h1>
    <UCard>
      <form
        class="space-y-4"
        @submit.prevent="save"
      >
        <UFormField
          :label="t('contacts.firstName')"
          required
        >
          <UInput v-model="form.first_name" />
        </UFormField>
        <UFormField :label="t('contacts.lastName')">
          <UInput v-model="form.last_name" />
        </UFormField>
        <UFormField :label="t('contacts.email')">
          <UInput
            v-model="form.email"
            type="email"
          />
        </UFormField>
        <UFormField :label="t('contacts.phone')">
          <UInput v-model="form.phone" />
        </UFormField>
        <UFormField :label="t('contacts.jobTitle')">
          <UInput v-model="form.job_title" />
        </UFormField>
        <UFormField :label="t('contacts.company')">
          <USelectMenu
            v-model="form.company_id"
            :items="companyOptions"
            value-key="value"
            :placeholder="t('contacts.selectCompany')"
            searchable
          />
        </UFormField>
        <p
          v-if="errorMsg"
          class="text-sm text-red-500"
        >
          {{ errorMsg }}
        </p>
        <div class="flex gap-2">
          <UButton
            type="submit"
            :loading="loading"
          >
            {{ t('common.save') }}
          </UButton>
          <UButton
            to="/app/contacts"
            variant="outline"
            color="neutral"
          >
            {{ t('common.cancel') }}
          </UButton>
        </div>
      </form>
    </UCard>
  </div>
</template>
