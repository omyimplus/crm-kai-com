<script setup lang="ts">
import { appFormErrorClass } from '~/config/appFormUi'
import {
  defaultMasterPartnerFormInput,
  partnerSaveErrorMessage,
  partnerToFormInput,
  validateMasterPartnerForm
} from '~/utils/masterPartner'

const props = defineProps<{
  mode: 'new' | 'edit'
  partnerId?: string | null
}>()

const { t } = useI18n()
const { get, create, update } = usePartners()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterPartnerFormInput())

const isEdit = computed(() => props.mode === 'edit')

const pageTitle = computed(() =>
  isEdit.value ? t('masterData.partner.editTitle') : t('masterData.partner.newTitle')
)
const pageSubtitle = computed(() =>
  isEdit.value ? t('masterData.partner.editSubtitle') : t('masterData.partner.newSubtitle')
)

if (isEdit.value && props.partnerId) {
  try {
    const row = await get(props.partnerId)
    form.value = partnerToFormInput(row)
  } catch (e) {
    console.error(e)
    await navigateTo('/app/partner')
  }
}

async function save() {
  const validationKey = validateMasterPartnerForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.partner.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    if (isEdit.value && props.partnerId) {
      await update(props.partnerId, form.value)
      await navigateTo(`/app/partner/${props.partnerId}`)
    } else {
      const row = await create(form.value)
      await navigateTo(`/app/partner/${row.id}`)
    }
  } catch (e: unknown) {
    errorMsg.value = partnerSaveErrorMessage(e, t)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div>
    <UButton
      to="/app/partner"
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

        <MasterDataPartnerForm v-model="form" />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.partner.actions') }}
          </p>
          <UButton
            type="button"
            block
            size="lg"
            icon="i-lucide-check"
            :loading="saving"
            @click="save"
          >
            {{ isEdit ? t('common.save') : t('masterData.partner.create') }}
          </UButton>
          <UButton
            type="button"
            block
            class="mt-2"
            variant="outline"
            color="neutral"
            to="/app/partner"
          >
            {{ t('common.cancel') }}
          </UButton>
        </UCard>
      </aside>
    </form>
  </div>
</template>
