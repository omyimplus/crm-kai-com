<script setup lang="ts">
import { appFormErrorClass } from '~/config/appFormUi'
import {
  defaultMasterContactFormInput,
  validateMasterContactForm
} from '~/utils/masterContact'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  customerId: string
  customerName: string
}>()

const emit = defineEmits<{ created: [contactId: string] }>()

const { t } = useI18n()
const { create } = useContacts()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterContactFormInput())

watch(open, (isOpen) => {
  if (!isOpen) return
  errorMsg.value = ''
  form.value = {
    ...defaultMasterContactFormInput(),
    company_id: props.customerId
  }
})

async function save() {
  const validationKey = validateMasterContactForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.contact.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    const row = await create(form.value)
    open.value = false
    emit('created', row.id)
  } catch (e: unknown) {
    errorMsg.value = getSupabaseErrorMessage(e, t('common.saveFailed'))
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="t('masterData.customer.contactsPanel.addModalTitle')"
    :description="t('masterData.customer.contactsPanel.addModalSubtitle', { name: customerName })"
    size="2xl"
  >
    <p
      v-if="errorMsg"
      class="mb-4"
      :class="appFormErrorClass"
    >
      {{ errorMsg }}
    </p>

    <MasterDataContactForm
      v-model="form"
      :customer-options="[]"
      :fixed-customer-id="customerId"
      :fixed-customer-name="customerName"
    />

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          class="w-full sm:w-auto"
          size="lg"
          icon="i-lucide-check"
          :loading="saving"
          @click="save"
        >
          {{ t('masterData.contact.create') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
