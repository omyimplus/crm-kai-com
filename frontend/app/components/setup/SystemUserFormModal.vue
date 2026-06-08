<script setup lang="ts">
import type { OrgRole, OrgUser, ProfileRole } from '~/types/crm'
import {
  appFormErrorClass,
  appFormFieldClass,
  appFormHintClass,
  appFormSwitchBoxClass,
  appInputUi,
  appSelectMenuUi
} from '~/config/appFormUi'
import { validateOptionalPasswordPair, validatePasswordPair } from '~/utils/password'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  user: OrgUser | null
  roleOptions: ProfileRole[]
  orgRoleOptions: OrgRole[]
}>()

const emit = defineEmits<{ saved: [] }>()

const { t } = useI18n()
const { create, update } = useSystemUsers()
const { profile, fetchProfile } = useProfile()
const { uploadAvatar, removeStoredAvatar } = useUserAvatar()
const {
  previewUrl: avatarPreviewUrl,
  changed: avatarChanged,
  file: avatarFile,
  removed: avatarRemoved,
  savedUrl: avatarSavedUrl,
  select: onAvatarSelect,
  remove: onAvatarRemove,
  reset: resetAvatarState
} = useImageUploadState()

const saving = ref(false)
const errorMsg = ref('')

const fullName = ref('')
const email = ref('')
const username = ref('')
const password = ref('')
const confirmPassword = ref('')
const role = ref<ProfileRole>('employee')
const orgRoleIds = ref<string[]>([])
const isActive = ref(true)

const isCreate = computed(() => !props.user)

const isSelf = computed(() => props.user?.id === profile.value?.id)
const isTargetOwner = computed(() => props.user?.role === 'owner')
const isAdminEditingOwner = computed(() =>
  !isCreate.value
  && profile.value?.role === 'admin'
  && isTargetOwner.value
  && !isSelf.value
)

const modalTitle = computed(() =>
  isCreate.value ? t('setup.systemUsers.createTitle') : t('setup.systemUsers.editTitle')
)

const modalDescription = computed(() =>
  isCreate.value ? t('setup.systemUsers.createSubtitle') : undefined
)

function resetForm() {
  if (isCreate.value) {
    fullName.value = ''
    email.value = ''
    username.value = ''
    password.value = ''
    confirmPassword.value = ''
    role.value = props.roleOptions.includes('employee') ? 'employee' : (props.roleOptions[0] ?? 'employee')
    orgRoleIds.value = []
    isActive.value = true
    resetAvatarState(null)
  } else if (props.user) {
    fullName.value = props.user.full_name ?? ''
    email.value = props.user.email ?? ''
    username.value = props.user.username ?? ''
    password.value = ''
    confirmPassword.value = ''
    role.value = props.user.role
    orgRoleIds.value = [...(props.user.org_role_ids ?? [])]
    isActive.value = props.user.is_active
    resetAvatarState(props.user.avatar_url)
  }
  errorMsg.value = ''
}

async function applyAvatarChanges(userId: string) {
  if (!avatarChanged.value) return

  if (avatarRemoved.value && !avatarFile.value) {
    await removeStoredAvatar(userId, avatarSavedUrl.value)
    await update(userId, {
      avatar_url: null,
      set_avatar: true,
      skip_org_roles: true
    })
    return
  }

  if (avatarFile.value) {
    const url = await uploadAvatar(userId, avatarFile.value)
    await update(userId, {
      avatar_url: url,
      set_avatar: true,
      skip_org_roles: true
    })
  }
}

watch(open, (isOpen) => {
  if (isOpen) resetForm()
})

function mapPasswordError(err: ReturnType<typeof validatePasswordPair>): string | null {
  if (!err) return null
  if (err === 'mismatch') return t('auth.passwordMismatch')
  if (err === 'tooShort') return t('auth.passwordTooShort', { min: 6 })
  return t('setup.systemUsers.passwordRequired')
}

function passwordErrorMessage(optional: boolean): string | null {
  const err = optional
    ? validateOptionalPasswordPair(password.value, confirmPassword.value)
    : validatePasswordPair(password.value, confirmPassword.value)
  return mapPasswordError(err)
}

async function save() {
  if (isAdminEditingOwner.value) return

  if (role.value === 'employee' && orgRoleIds.value.length === 0) {
    errorMsg.value = t('setup.systemUsers.orgRoleRequired')
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    if (isCreate.value) {
      const passwordError = passwordErrorMessage(false)
      if (passwordError) {
        errorMsg.value = passwordError
        return
      }
      const userId = await create({
        full_name: fullName.value.trim(),
        email: email.value.trim(),
        username: username.value.trim(),
        password: password.value,
        role: role.value,
        org_role_ids: orgRoleIds.value,
        is_active: isActive.value
      })
      await applyAvatarChanges(userId)
    } else if (props.user) {
      const passwordError = passwordErrorMessage(true)
      if (passwordError) {
        errorMsg.value = passwordError
        return
      }
      await update(props.user.id, {
        full_name: fullName.value.trim() || null,
        email: email.value.trim() || null,
        username: username.value.trim() || null,
        password: password.value.trim() || null,
        role: role.value,
        org_role_ids: orgRoleIds.value,
        is_active: isActive.value
      })
      await applyAvatarChanges(props.user.id)
      if (isSelf.value && avatarChanged.value) {
        await fetchProfile()
      }
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
  <AppDialog
    v-model:open="open"
    :title="modalTitle"
    :description="modalDescription"
    size="2xl"
  >
    <form
      id="system-user-form"
      class="grid grid-cols-1 gap-6 lg:grid-cols-2 lg:gap-8"
      @submit.prevent="save"
    >
      <div class="space-y-5">
        <h3 class="text-sm font-semibold font-heading text-gray-900 dark:text-gray-100">
          {{ t('setup.systemUsers.accountSection') }}
        </h3>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.systemUsers.fullName')"
          required
        >
          <UInput
            v-model="fullName"
            class="w-full"
            size="lg"
            :ui="appInputUi"
            :disabled="isAdminEditingOwner"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.systemUsers.email')"
          required
        >
          <UInput
            v-model="email"
            class="w-full"
            type="email"
            autocomplete="off"
            size="lg"
            :ui="appInputUi"
            :disabled="isAdminEditingOwner"
          />
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.systemUsers.username')"
          required
        >
          <UInput
            v-model="username"
            class="w-full"
            autocomplete="off"
            size="lg"
            :ui="appInputUi"
            :disabled="isAdminEditingOwner"
          />
        </UFormField>

        <AppPasswordFieldGroup
          v-model:password="password"
          v-model:confirm-password="confirmPassword"
          :optional="!isCreate"
          :disabled="isAdminEditingOwner"
          :hint="!isCreate ? t('setup.systemUsers.passwordHint') : undefined"
          :password-placeholder="isCreate ? undefined : t('setup.systemUsers.passwordPlaceholder')"
        />
      </div>

      <div class="space-y-5">
        <AppAvatarUpload
          :preview-url="avatarPreviewUrl"
          :display-name="fullName"
          :disabled="isAdminEditingOwner"
          @select="onAvatarSelect"
          @remove="onAvatarRemove"
        />

        <h3 class="text-sm font-semibold font-heading text-gray-900 dark:text-gray-100">
          {{ t('setup.systemUsers.accessSection') }}
        </h3>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.systemUsers.platformRole')"
        >
          <USelectMenu
            v-model="role"
            class="w-full"
            size="lg"
            :ui="appSelectMenuUi"
            :items="roleOptions.map(r => ({
              label: t(`profile.roles.${r}`),
              value: r
            }))"
            value-key="value"
            :disabled="isAdminEditingOwner || roleOptions.length === 0"
          />
          <p :class="appFormHintClass">
            {{ t('setup.systemUsers.platformRoleHint') }}
          </p>
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.systemUsers.orgRole')"
        >
          <AppOrgRoleChipSelect
            v-model="orgRoleIds"
            :options="orgRoleOptions"
            :disabled="isAdminEditingOwner"
          />
          <p :class="appFormHintClass">
            {{ t('setup.systemUsers.orgRoleHint') }}
          </p>
          <p
            v-if="role === 'employee'"
            class="mt-1 text-xs text-amber-700 dark:text-amber-300"
          >
            {{ t('setup.systemUsers.employeeOrgRoleHint') }}
          </p>
        </UFormField>

        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.systemUsers.status')"
        >
          <div :class="appFormSwitchBoxClass">
            <USwitch
              v-model="isActive"
              :disabled="isSelf || isAdminEditingOwner"
            />
            <span class="text-sm text-gray-600 dark:text-gray-400">
              {{ isActive ? t('setup.systemUsers.active') : t('setup.systemUsers.inactive') }}
            </span>
          </div>
          <p
            v-if="isSelf"
            :class="appFormHintClass"
          >
            {{ t('setup.systemUsers.cannotDeactivateSelf') }}
          </p>
        </UFormField>
      </div>

      <div class="space-y-4 lg:col-span-2">
        <UAlert
          v-if="isAdminEditingOwner"
          color="warning"
          variant="subtle"
          :title="t('setup.systemUsers.cannotEditOwner')"
        />

        <p
          v-if="errorMsg"
          :class="appFormErrorClass"
        >
          {{ errorMsg }}
        </p>
      </div>
    </form>

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          class="w-full sm:w-auto"
          type="submit"
          form="system-user-form"
          size="lg"
          :loading="saving"
          :disabled="isAdminEditingOwner"
        >
          {{ isCreate ? t('common.create') : t('common.save') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
