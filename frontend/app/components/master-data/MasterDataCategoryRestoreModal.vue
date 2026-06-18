<script setup lang="ts">
import { appFormErrorClass } from '~/config/appFormUi'
import { categorySaveErrorMessage } from '~/utils/masterCategory'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  categoryId: string
  categoryName: string
  parentDeleted?: boolean
}>()

const emit = defineEmits<{ restored: [] }>()

const { t } = useI18n()
const { restore } = useCategories()

const restoring = ref(false)
const errorMsg = ref('')

watch(open, (isOpen) => {
  if (isOpen) errorMsg.value = ''
})

async function confirmRestore() {
  restoring.value = true
  errorMsg.value = ''
  try {
    await restore(props.categoryId)
    open.value = false
    emit('restored')
  } catch (e: unknown) {
    errorMsg.value = categorySaveErrorMessage(e, t)
  } finally {
    restoring.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="t('masterData.category.restoreTitle')"
    size="sm"
  >
    <p class="text-sm leading-relaxed text-gray-600 dark:text-gray-400">
      {{ t('masterData.category.restoreConfirm', { name: categoryName }) }}
    </p>
    <p
      v-if="parentDeleted"
      class="mt-3 text-sm leading-relaxed text-amber-700 dark:text-amber-300"
    >
      {{ t('masterData.category.restoreParentDeletedHint') }}
    </p>

    <p
      v-if="errorMsg"
      class="mt-4"
      :class="appFormErrorClass"
    >
      {{ errorMsg }}
    </p>

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          class="w-full sm:w-auto"
          color="primary"
          size="lg"
          icon="i-lucide-rotate-ccw"
          :loading="restoring"
          :disabled="parentDeleted"
          @click="confirmRestore"
        >
          {{ t('common.restore') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
