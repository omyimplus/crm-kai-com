<script setup lang="ts">
import { appFormErrorClass } from '~/config/appFormUi'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  partnerId: string
  partnerName: string
}>()

const emit = defineEmits<{ restored: [] }>()

const { t } = useI18n()
const { restore } = usePartners()

const restoring = ref(false)
const errorMsg = ref('')

watch(open, (isOpen) => {
  if (isOpen) errorMsg.value = ''
})

async function confirmRestore() {
  restoring.value = true
  errorMsg.value = ''
  try {
    await restore(props.partnerId)
    open.value = false
    emit('restored')
  } catch (e: unknown) {
    errorMsg.value = getSupabaseErrorMessage(e, t('common.restoreFailed'))
  } finally {
    restoring.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="t('masterData.partner.restoreTitle')"
    size="sm"
  >
    <p class="text-sm leading-relaxed text-gray-600 dark:text-gray-400">
      {{ t('masterData.partner.restoreConfirm', { name: partnerName }) }}
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
          size="lg"
          icon="i-lucide-rotate-ccw"
          :loading="restoring"
          @click="confirmRestore"
        >
          {{ t('common.restore') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
