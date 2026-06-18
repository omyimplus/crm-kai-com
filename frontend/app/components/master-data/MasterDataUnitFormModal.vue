<script setup lang="ts">
import type { Unit } from '~/types/crm'
import { appFormErrorClass } from '~/config/appFormUi'
import {
  defaultMasterUnitFormInput,
  unitSaveErrorMessage,
  validateMasterUnitForm
} from '~/utils/masterUnit'

const open = defineModel<boolean>('open', { required: true })

const emit = defineEmits<{
  saved: [unit: Unit]
}>()

const { t } = useI18n()
const { create } = useUnits()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterUnitFormInput())

watch(open, (isOpen) => {
  if (isOpen) {
    form.value = defaultMasterUnitFormInput()
    errorMsg.value = ''
  }
})

async function save() {
  const validationKey = validateMasterUnitForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.unit.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    const row = await create(form.value)
    open.value = false
    emit('saved', row)
  } catch (e: unknown) {
    errorMsg.value = unitSaveErrorMessage(e, t)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="t('masterData.unit.newTitle')"
    :description="t('masterData.unit.newSubtitle')"
    size="2xl"
  >
    <form
      id="master-unit-create-form"
      class="space-y-4"
      @submit.prevent="save"
    >
      <p
        v-if="errorMsg"
        :class="appFormErrorClass"
      >
        {{ errorMsg }}
      </p>

      <MasterDataUnitForm v-model="form" />
    </form>

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          type="submit"
          form="master-unit-create-form"
          size="lg"
          icon="i-lucide-check"
          :loading="saving"
        >
          {{ t('masterData.unit.create') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
