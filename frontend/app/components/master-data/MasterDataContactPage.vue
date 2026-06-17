<script setup lang="ts">
import { appFormErrorClass } from '~/config/appFormUi'
import {
  contactToFormInput,
  defaultMasterContactFormInput,
  validateMasterContactForm
} from '~/utils/masterContact'

const props = defineProps<{
  mode: 'new' | 'edit'
  contactId?: string | null
}>()

const { t } = useI18n()
const { list: listCompanies } = useCompanies()
const { get, create, update } = useContacts()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterContactFormInput())
const companies = ref<{ label: string, value: string }[]>([])

const isEdit = computed(() => props.mode === 'edit')

const pageTitle = computed(() =>
  isEdit.value ? t('masterData.contact.editTitle') : t('masterData.contact.newTitle')
)
const pageSubtitle = computed(() =>
  isEdit.value ? t('masterData.contact.editSubtitle') : t('masterData.contact.newSubtitle')
)

try {
  const rows = await listCompanies()
  companies.value = rows.map(c => ({ label: c.name, value: c.id }))
} catch (e) {
  console.error(e)
}

if (isEdit.value && props.contactId) {
  try {
    const row = await get(props.contactId)
    form.value = contactToFormInput(row)
  } catch (e) {
    console.error(e)
    await navigateTo('/app/contact')
  }
}

async function save() {
  const validationKey = validateMasterContactForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.contact.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    const payload = formToContactPayload(form.value)
    if (isEdit.value && props.contactId) {
      await update(props.contactId, form.value)
      await navigateTo(`/app/contact/${props.contactId}`)
    } else {
      const row = await create(form.value)
      await navigateTo(`/app/contact/${row.id}`)
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
      to="/app/contact"
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

        <MasterDataContactForm
          v-model="form"
          :customer-options="companies"
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.contact.actions') }}
          </p>
          <UButton
            type="button"
            block
            size="lg"
            icon="i-lucide-check"
            :loading="saving"
            @click="save"
          >
            {{ isEdit ? t('common.save') : t('masterData.contact.create') }}
          </UButton>
          <UButton
            type="button"
            block
            class="mt-2"
            variant="outline"
            color="neutral"
            to="/app/contact"
          >
            {{ t('common.cancel') }}
          </UButton>
        </UCard>
      </aside>
    </form>
  </div>
</template>
