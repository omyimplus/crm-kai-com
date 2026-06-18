<script setup lang="ts">
import type { Category } from '~/types/crm'
import { appFormErrorClass } from '~/config/appFormUi'
import {
  categorySaveErrorMessage,
  defaultMasterCategoryFormInput,
  validateMasterCategoryForm
} from '~/utils/masterCategory'

const open = defineModel<boolean>('open', { required: true })

defineProps<{
  parentOptions: { label: string, value: string }[]
}>()

const emit = defineEmits<{
  saved: [category: Category]
}>()

const { t } = useI18n()
const { create } = useCategories()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterCategoryFormInput())

watch(open, (isOpen) => {
  if (isOpen) {
    form.value = defaultMasterCategoryFormInput()
    errorMsg.value = ''
  }
})

async function save() {
  const validationKey = validateMasterCategoryForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.category.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    const row = await create(form.value)
    open.value = false
    emit('saved', row)
  } catch (e: unknown) {
    errorMsg.value = categorySaveErrorMessage(e, t)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="t('masterData.category.newTitle')"
    :description="t('masterData.category.newSubtitle')"
    size="2xl"
  >
    <form
      id="master-category-create-form"
      class="space-y-4"
      @submit.prevent="save"
    >
      <p
        v-if="errorMsg"
        :class="appFormErrorClass"
      >
        {{ errorMsg }}
      </p>

      <MasterDataCategoryForm
        v-model="form"
        :parent-options="parentOptions"
      />
    </form>

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          type="submit"
          form="master-category-create-form"
          size="lg"
          icon="i-lucide-check"
          :loading="saving"
        >
          {{ t('masterData.category.create') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
