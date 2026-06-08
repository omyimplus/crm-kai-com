<script setup lang="ts">
import type { OrgRole } from '~/types/crm'

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
  <UModal v-model:open="open">
    <template #content>
      <UCard>
        <template #header>
          <h2 class="font-semibold font-heading">
            {{ t('setup.roles.deleteTitle') }}
          </h2>
        </template>

        <p class="text-sm text-gray-600 dark:text-gray-400">
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
          class="mt-4 text-sm text-red-500"
        >
          {{ errorMsg }}
        </p>

        <div class="mt-6 flex justify-end gap-2">
          <UButton
            variant="outline"
            color="neutral"
            @click="open = false"
          >
            {{ t('common.cancel') }}
          </UButton>
          <UButton
            color="error"
            :loading="deleting"
            :disabled="!canDelete"
            @click="confirmDelete"
          >
            {{ t('common.delete') }}
          </UButton>
        </div>
      </UCard>
    </template>
  </UModal>
</template>
