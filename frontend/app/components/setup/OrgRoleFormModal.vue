<script setup lang="ts">
import type { OrgRole, OrgRoleCreatedPayload } from '~/types/crm'
import {
  normalizeOrgRoleCode,
  ORG_ROLE_CODE_MAX_LENGTH,
  ORG_ROLE_CODE_MIN_LENGTH,
  validateOrgRoleCode
} from '~/utils/orgRoleCode'
import {
  appFormErrorClass,
  appFormFieldClass,
  appFormHintClass,
  appFormInfoClass,
  appFormSwitchBoxClass,
  appInputUi,
  appTextareaUi
} from '~/config/appFormUi'

const open = defineModel<boolean>('open', { required: true })

const props = withDefaults(defineProps<{
  role: OrgRole | null
  /** เมื่อสร้างสำเร็จ — ไปหน้าจัดการสิทธิ์ (ปิดเมื่อเปิดจากฟอร์มผู้ใช้) */
  navigateOnCreate?: boolean
}>(), {
  navigateOnCreate: true
})

const emit = defineEmits<{
  saved: [created?: OrgRoleCreatedPayload]
}>()

const { t } = useI18n()
const { create, update, buildDefaultPermissions } = useOrgRoles()

const saving = ref(false)
const errorMsg = ref('')

const code = ref('')
const label = ref('')
const description = ref('')
const isActive = ref(true)
const codeTouched = ref(false)

const isCreate = computed(() => !props.role)

const codeValidation = computed(() =>
  isCreate.value ? validateOrgRoleCode(code.value) : { ok: true as const }
)

function codeErrorMessage(errorId: NonNullable<typeof codeValidation.value.errorId>): string {
  if (errorId === 'tooShort') {
    return t('setup.roles.codeErrors.tooShort', { min: ORG_ROLE_CODE_MIN_LENGTH })
  }
  if (errorId === 'tooLong') {
    return t('setup.roles.codeErrors.tooLong', { max: ORG_ROLE_CODE_MAX_LENGTH })
  }
  return t(`setup.roles.codeErrors.${errorId}`)
}

const codeFieldError = computed(() => {
  if (!isCreate.value || !codeTouched.value || codeValidation.value.ok) {
    return ''
  }
  return codeErrorMessage(codeValidation.value.errorId!)
})

const modalTitle = computed(() =>
  isCreate.value ? t('setup.roles.createTitle') : t('setup.roles.editTitle')
)

function resetForm() {
  if (isCreate.value) {
    code.value = ''
    label.value = ''
    description.value = ''
    isActive.value = true
    codeTouched.value = false
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
  errorMsg.value = ''

  if (isCreate.value) {
    codeTouched.value = true
    if (!codeValidation.value.ok) {
      return
    }
  }

  const trimmedLabel = label.value.trim()
  if (!trimmedLabel) {
    errorMsg.value = t('setup.roles.labelRequired')
    return
  }

  saving.value = true
  try {
    if (isCreate.value) {
      const trimmedCode = normalizeOrgRoleCode(code.value)

      const roleId = await create({
        code: trimmedCode,
        label: trimmedLabel,
        description: description.value.trim() || null,
        permissions: buildDefaultPermissions()
      })
      open.value = false
      emit('saved', { id: roleId, label: trimmedLabel, code: trimmedCode })
      if (props.navigateOnCreate) {
        await navigateTo(`/app/setup/roles/${roleId}`)
      }
      return
    } else if (props.role) {
      await update(props.role.id, {
        label: trimmedLabel,
        description: description.value.trim() || null,
        is_active: isActive.value
      })
    }
    open.value = false
    emit('saved')
  } catch (e: unknown) {
    const message = e instanceof Error ? e.message : ''
    if (message.includes('Invalid code format')) {
      codeTouched.value = true
      errorMsg.value = t('setup.roles.codeErrors.invalidChars')
    } else if (message.includes('Role code already exists')) {
      errorMsg.value = t('setup.roles.codeErrors.duplicate')
    } else {
      errorMsg.value = message || t('common.saveFailed')
    }
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="modalTitle"
    size="md"
  >
    <form
      id="org-role-form"
      class="space-y-5"
      @submit.prevent="save"
    >
        <UFormField
          v-if="isCreate"
          :class="appFormFieldClass"
          :label="t('setup.roles.code')"
          required
        >
          <UInput
            v-model="code"
            class="w-full"
            size="lg"
            placeholder="sales_lead"
            autocomplete="off"
            spellcheck="false"
            :ui="appInputUi"
            @blur="codeTouched = true"
          />
          <p
            v-if="codeFieldError"
            :class="appFormErrorClass"
          >
            {{ codeFieldError }}
          </p>
          <p
            v-else
            :class="appFormHintClass"
          >
            {{ t('setup.roles.codeHint') }}
          </p>
        </UFormField>

        <UFormField
          v-else
          :class="appFormFieldClass"
          :label="t('setup.roles.code')"
        >
          <UInput
            v-model="code"
            class="w-full"
            size="lg"
            disabled
            :ui="appInputUi"
          />
          <p :class="appFormHintClass">
            {{ t('setup.roles.manage.codeReadonly') }}
          </p>
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.roles.label')"
          required
        >
          <UInput
            v-model="label"
            class="w-full"
            size="lg"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.roles.descriptionLabel')"
        >
          <UTextarea
            v-model="description"
            class="w-full"
            :rows="3"
            :ui="appTextareaUi"
          />
        </UFormField>

        <UFormField
          v-if="!isCreate"
          :class="appFormFieldClass"
          :label="t('setup.roles.status')"
        >
          <div :class="appFormSwitchBoxClass">
            <USwitch
              v-model="isActive"
              :disabled="role?.is_system"
            />
            <span class="text-sm text-gray-600 dark:text-gray-400">
              {{ isActive ? t('setup.roles.active') : t('setup.roles.inactive') }}
            </span>
          </div>
          <p
            v-if="role?.is_system"
            class="mt-1.5 text-xs text-gray-500"
          >
            {{ t('setup.roles.cannotDeactivateSystem') }}
          </p>
        </UFormField>

        <p
          v-if="isCreate"
          :class="appFormInfoClass"
        >
          {{ t('setup.roles.createPermissionsHint') }}
        </p>

        <p
          v-if="errorMsg"
          :class="appFormErrorClass"
        >
          {{ errorMsg }}
        </p>
    </form>

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          class="w-full sm:w-auto"
          type="submit"
          form="org-role-form"
          size="lg"
          :loading="saving"
        >
          {{ isCreate ? t('common.create') : t('common.save') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
