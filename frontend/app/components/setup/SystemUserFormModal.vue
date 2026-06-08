<script setup lang="ts">
import type { OrgRole, OrgRoleCreatedPayload, OrgUser, ProfileRole } from '~/types/crm'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  user: OrgUser | null
  roleOptions: ProfileRole[]
  orgRoleOptions: OrgRole[]
}>()

const emit = defineEmits<{
  saved: []
  openOrgRoleForm: []
}>()

const { t } = useI18n()
const { create, update } = useSystemUsers()
const { profile } = useProfile()

const saving = ref(false)
const errorMsg = ref('')

const fullName = ref('')
const email = ref('')
const username = ref('')
const password = ref('')
const role = ref<ProfileRole>('sales')
const orgRoleId = ref<string | null>(null)
const isActive = ref(true)
const pendingOrgRoles = ref<OrgRole[]>([])

const mergedOrgRoleOptions = computed(() => {
  const byId = new Map<string, OrgRole>()
  for (const role of props.orgRoleOptions) byId.set(role.id, role)
  for (const role of pendingOrgRoles.value) byId.set(role.id, role)
  return [...byId.values()]
})

const orgRoleSelectItems = computed(() => [
  { label: t('setup.systemUsers.noOrgRole'), value: null as string | null },
  ...mergedOrgRoleOptions.value.map(r => ({
    label: r.label,
    value: r.id as string | null
  }))
])

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

function applyCreatedOrgRole(created: OrgRoleCreatedPayload) {
  pendingOrgRoles.value = [
    ...pendingOrgRoles.value.filter(r => r.id !== created.id),
    {
      id: created.id,
      org_id: profile.value?.org_id ?? '',
      code: created.code,
      label: created.label,
      description: null,
      is_active: true,
      is_system: false,
      permissions: {},
      user_count: 0,
      created_at: '',
      updated_at: ''
    }
  ]
  orgRoleId.value = created.id
}

defineExpose({ applyCreatedOrgRole })

function resetForm() {
  pendingOrgRoles.value = []
  if (isCreate.value) {
    fullName.value = ''
    email.value = ''
    username.value = ''
    password.value = ''
    role.value = props.roleOptions[0] ?? 'sales'
    orgRoleId.value = null
    isActive.value = true
  } else if (props.user) {
    fullName.value = props.user.full_name ?? ''
    email.value = props.user.email ?? ''
    username.value = props.user.username ?? ''
    password.value = ''
    role.value = props.user.role
    orgRoleId.value = props.user.org_role_id ?? null
    isActive.value = props.user.is_active
  }
  errorMsg.value = ''
}

watch(open, (isOpen) => {
  if (isOpen) resetForm()
})

async function save() {
  if (isAdminEditingOwner.value) return

  saving.value = true
  errorMsg.value = ''
  try {
    if (isCreate.value) {
      if (!password.value.trim()) {
        errorMsg.value = t('setup.systemUsers.passwordRequired')
        return
      }
      await create({
        full_name: fullName.value.trim(),
        email: email.value.trim(),
        username: username.value.trim(),
        password: password.value,
        role: role.value,
        org_role_id: orgRoleId.value,
        is_active: isActive.value
      })
    } else if (props.user) {
      await update(props.user.id, {
        full_name: fullName.value.trim() || null,
        email: email.value.trim() || null,
        username: username.value.trim() || null,
        password: password.value.trim() || null,
        role: role.value,
        org_role_id: orgRoleId.value,
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
            :label="t('setup.systemUsers.fullName')"
            required
          >
            <UInput
              v-model="fullName"
              :disabled="isAdminEditingOwner"
            />
          </UFormField>

          <UFormField
            :label="t('setup.systemUsers.email')"
            required
          >
            <UInput
              v-model="email"
              type="email"
              autocomplete="off"
              :disabled="isAdminEditingOwner"
            />
          </UFormField>

          <UFormField
            :label="t('setup.systemUsers.username')"
            required
          >
            <UInput
              v-model="username"
              autocomplete="off"
              :disabled="isAdminEditingOwner"
            />
          </UFormField>

          <UFormField
            :label="t('setup.systemUsers.password')"
            :required="isCreate"
          >
            <UInput
              v-model="password"
              type="password"
              autocomplete="new-password"
              :placeholder="isCreate ? '' : t('setup.systemUsers.passwordPlaceholder')"
              :disabled="isAdminEditingOwner"
            />
            <p
              v-if="!isCreate"
              class="mt-1 text-xs text-gray-500"
            >
              {{ t('setup.systemUsers.passwordHint') }}
            </p>
          </UFormField>

          <UFormField :label="t('profile.role')">
            <USelectMenu
              v-model="role"
              :items="roleOptions.map(r => ({
                label: t(`profile.roles.${r}`),
                value: r
              }))"
              value-key="value"
              :disabled="isAdminEditingOwner || roleOptions.length === 0"
            />
            <p class="mt-1 text-xs text-gray-500">
              {{ t('setup.systemUsers.systemRoleHint') }}
            </p>
          </UFormField>

          <UFormField :label="t('setup.systemUsers.orgRole')">
            <div class="flex items-start gap-2">
              <USelectMenu
                v-model="orgRoleId"
                class="min-w-0 flex-1"
                :items="orgRoleSelectItems"
                value-key="value"
                :disabled="isAdminEditingOwner"
              />
              <UButton
                type="button"
                variant="outline"
                color="neutral"
                icon="i-lucide-plus"
                :disabled="isAdminEditingOwner"
                @click="emit('openOrgRoleForm')"
              >
                {{ t('setup.systemUsers.addOrgRole') }}
              </UButton>
            </div>
            <p class="mt-1 text-xs text-gray-500">
              {{ t('setup.systemUsers.orgRoleHint') }}
            </p>
          </UFormField>

          <UFormField :label="t('setup.systemUsers.status')">
            <div class="flex items-center gap-3">
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
              class="mt-1 text-xs text-gray-500"
            >
              {{ t('setup.systemUsers.cannotDeactivateSelf') }}
            </p>
          </UFormField>

          <UAlert
            v-if="isAdminEditingOwner"
            color="warning"
            variant="subtle"
            :title="t('setup.systemUsers.cannotEditOwner')"
          />

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
              :disabled="isAdminEditingOwner"
            >
              {{ isCreate ? t('common.create') : t('common.save') }}
            </UButton>
          </div>
        </form>
      </UCard>
    </template>
  </UModal>
</template>
