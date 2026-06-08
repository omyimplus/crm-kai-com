<script setup lang="ts">
import type { OrgRole } from '~/types/crm'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  role: OrgRole | null
}>()

const emit = defineEmits<{ saved: [] }>()

const { t } = useI18n()
const { create, update, buildDefaultPermissions } = useOrgRoles()

const saving = ref(false)
const errorMsg = ref('')

const code = ref('')
const label = ref('')
const description = ref('')
const isActive = ref(true)

const isCreate = computed(() => !props.role)

const modalTitle = computed(() =>
  isCreate.value ? t('masterData.roles.createTitle') : t('masterData.roles.editTitle')
)

function resetForm() {
  if (isCreate.value) {
    code.value = ''
    label.value = ''
    description.value = ''
    isActive.value = true
  } else if (props.role) {
    code.value = props.role.code
    label.value = props.role.label
    description.value = props.role.description ?? ''
    isActive.value = props.role.is_active
  }
  errorMsg.value = ''
}

watch(open, (isOpen) => {
  if (isOpen) resetForm()
})

async function save() {
  saving.value = true
  errorMsg.value = ''
  try {
    if (isCreate.value) {
      const roleId = await create({
        code: code.value.trim(),
        label: label.value.trim(),
        description: description.value.trim() || null,
        permissions: buildDefaultPermissions()
      })
      open.value = false
      emit('saved')
      await navigateTo(`/app/master-data/roles/${roleId}`)
      return
    } else if (props.role) {
      await update(props.role.id, {
        label: label.value.trim(),
        description: description.value.trim() || null,
        is_active: isActive.value
      })
    }
    open.value = false
    emit('saved')
  } catch (e: unknown) {
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <UModal v-model:open="open">
    <template #content>
      <UCard>
        <template #header>
          <h2 class="font-semibold font-heading">
            {{ modalTitle }}
          </h2>
        </template>

        <form
          class="space-y-4"
          @submit.prevent="save"
        >
          <UFormField
            :label="t('masterData.roles.code')"
            required
          >
            <UInput
              v-model="code"
              :disabled="!isCreate"
              placeholder="sales_lead"
            />
            <p class="mt-1 text-xs text-gray-500">
              {{ t('masterData.roles.codeHint') }}
            </p>
          </UFormField>

          <UFormField
            :label="t('masterData.roles.label')"
            required
          >
            <UInput v-model="label" />
          </UFormField>

          <UFormField :label="t('masterData.roles.descriptionLabel')">
            <UTextarea
              v-model="description"
              :rows="3"
            />
          </UFormField>

          <UFormField
            v-if="!isCreate"
            :label="t('masterData.roles.status')"
          >
            <div class="flex items-center gap-3">
              <USwitch
                v-model="isActive"
                :disabled="role?.is_system"
              />
              <span class="text-sm text-gray-600 dark:text-gray-400">
                {{ isActive ? t('masterData.roles.active') : t('masterData.roles.inactive') }}
              </span>
            </div>
            <p
              v-if="role?.is_system"
              class="mt-1 text-xs text-gray-500"
            >
              {{ t('masterData.roles.cannotDeactivateSystem') }}
            </p>
          </UFormField>

          <p
            v-if="isCreate"
            class="text-xs text-gray-500"
          >
            {{ t('masterData.roles.createPermissionsHint') }}
          </p>

          <p
            v-if="errorMsg"
            class="text-sm text-red-500"
          >
            {{ errorMsg }}
          </p>

          <div class="flex justify-end gap-2">
            <UButton
              variant="outline"
              color="neutral"
              @click="open = false"
            >
              {{ t('common.cancel') }}
            </UButton>
            <UButton
              type="submit"
              :loading="saving"
            >
              {{ isCreate ? t('common.create') : t('common.save') }}
            </UButton>
          </div>
        </form>
      </UCard>
    </template>
  </UModal>
</template>
