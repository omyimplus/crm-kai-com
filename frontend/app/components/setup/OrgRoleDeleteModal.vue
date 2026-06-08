<script setup lang="ts">
import type { OrgRole } from '~/types/crm'
import { appFormErrorClass } from '~/config/appFormUi'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  role: OrgRole | null
}>()

const emit = defineEmits<{ deleted: [] }>()

const { t } = useI18n()
const { remove } = useOrgRoles()

const deleting = ref(false)
const errorMsg = ref('')

const canDelete = computed(() =>
  props.role
  && !props.role.is_system
  && props.role.user_count === 0
)

watch(open, (isOpen) => {
  if (isOpen) errorMsg.value = ''
})

async function confirmDelete() {
  if (!props.role || !canDelete.value) return

  deleting.value = true
  errorMsg.value = ''
  try {
    await remove(props.role.id)
    open.value = false
    emit('deleted')
  } catch (e: unknown) {
    errorMsg.value = e instanceof Error ? e.message : t('common.deleteFailed')
  } finally {
    deleting.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="t('setup.roles.deleteTitle')"
    size="sm"
  >
    <p class="text-sm leading-relaxed text-gray-600 dark:text-gray-400">
      {{ t('setup.roles.deleteConfirm', { name: role?.label ?? '' }) }}
    </p>

    <UAlert
      v-if="role && role.user_count > 0"
      class="mt-4"
      color="warning"
      variant="subtle"
      :title="t('setup.roles.cannotDeleteAssigned')"
    />

    <UAlert
      v-if="role?.is_system"
      class="mt-4"
      color="warning"
      variant="subtle"
      :title="t('setup.roles.cannotDeleteSystem')"
    />

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
          :loading="deleting"
          :disabled="!canDelete"
          @click="confirmDelete"
        >
          {{ t('common.delete') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
