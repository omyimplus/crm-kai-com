<script setup lang="ts">
import { appFormErrorClass } from '~/config/appFormUi'
import { unitDeleteErrorMessage } from '~/utils/masterUnit'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  unitId: string
  unitName: string
}>()

const emit = defineEmits<{ deleted: [] }>()

const { t } = useI18n()
const { remove } = useUnits()

const deleting = ref(false)
const errorMsg = ref('')

watch(open, (isOpen) => {
  if (isOpen) errorMsg.value = ''
})

async function confirmDelete() {
  deleting.value = true
  errorMsg.value = ''
  try {
    await remove(props.unitId)
    open.value = false
    emit('deleted')
  } catch (e: unknown) {
    errorMsg.value = unitDeleteErrorMessage(e, t)
    if (errorMsg.value === t('common.deleteFailed')) {
      errorMsg.value = getSupabaseErrorMessage(e, t('common.deleteFailed'))
    }
  } finally {
    deleting.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="t('masterData.unit.deleteTitle')"
    size="sm"
  >
    <p class="text-sm leading-relaxed text-gray-600 dark:text-gray-400">
      {{ t('masterData.unit.deleteConfirm', { name: unitName }) }}
    </p>
    <p class="mt-3 text-sm leading-relaxed text-gray-500 dark:text-gray-400">
      {{ t('masterData.unit.deleteSoftHint') }}
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
          color="error"
          size="lg"
          icon="i-lucide-trash-2"
          :loading="deleting"
          @click="confirmDelete"
        >
          {{ t('common.delete') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
