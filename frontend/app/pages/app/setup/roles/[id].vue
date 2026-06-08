<script setup lang="ts">
import { permissionModules } from '~/config/permissionModules'
import type { OrgRole, OrgRolePermissions } from '~/types/crm'
import { countGrantedPermissions, normalizePermissions } from '~/utils/orgRolePermissions'

definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const { t } = useI18n()
const { ensureProfile } = useProfile()
const { canManage, get, update } = useOrgRoles()

await ensureProfile()

if (!canManage.value) {
  await navigateTo('/app')
}

const roleId = computed(() => route.params.id as string)
const role = ref<OrgRole | null>(null)
const label = ref('')
const description = ref('')
const isActive = ref(true)
const permissions = ref<OrgRolePermissions>({})
const loading = ref(true)
const saving = ref(false)
const deleteOpen = ref(false)
const errorMsg = ref('')
const savedMsg = ref('')

async function load() {
  loading.value = true
  errorMsg.value = ''
  try {
    role.value = await get(roleId.value)
    if (!role.value) {
      await navigateTo('/app/setup/roles')
      return
    }
    label.value = role.value.label
    description.value = role.value.description ?? ''
    isActive.value = role.value.is_active
    permissions.value = normalizePermissions(role.value.permissions)
  } catch (e) {
    console.error(e)
    errorMsg.value = e instanceof Error ? e.message : t('common.loadFailed')
  } finally {
    loading.value = false
  }
}

await load()

const grantedCount = computed(() => countGrantedPermissions(permissions.value))

const canDelete = computed(() =>
  role.value && !role.value.is_system && role.value.user_count === 0
)

async function save() {
  if (!role.value) return

  saving.value = true
  errorMsg.value = ''
  savedMsg.value = ''
  try {
    await update(role.value.id, {
      label: label.value.trim(),
      description: description.value.trim() || null,
      is_active: isActive.value,
      permissions: permissions.value
    })
    savedMsg.value = t('setup.roles.manage.saved')
    await load()
  } catch (e) {
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    saving.value = false
  }
}

async function onDeleted() {
  await navigateTo('/app/setup/roles')
}
</script>

<template>
  <div>
    <UButton
      to="/app/setup/roles"
      variant="ghost"
      color="neutral"
      icon="i-lucide-arrow-left"
      size="sm"
      class="mb-4"
    >
      {{ t('setup.roles.manage.back') }}
    </UButton>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <template v-else-if="role">
      <div class="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div>
          <div class="flex flex-wrap items-center gap-2">
            <h1 class="text-2xl font-bold font-heading">
              {{ role.label }}
            </h1>
            <UBadge
              color="neutral"
              variant="outline"
              class="font-mono text-xs"
            >
              {{ role.code }}
            </UBadge>
            <UBadge
              :color="role.is_active ? 'success' : 'neutral'"
              variant="subtle"
            >
              {{ role.is_active ? t('setup.roles.active') : t('setup.roles.inactive') }}
            </UBadge>
          </div>
          <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
            {{ t('setup.roles.manage.subtitle') }}
          </p>
        </div>

        <div class="flex flex-wrap gap-2">
          <UButton
            variant="outline"
            color="neutral"
            icon="i-lucide-users-round"
            to="/app/setup/system-users"
          >
            {{ t('setup.roles.manage.assignUsers') }}
          </UButton>
          <UButton
            :loading="saving"
            icon="i-lucide-save"
            @click="save"
          >
            {{ t('common.save') }}
          </UButton>
        </div>
      </div>

      <div class="mb-6 grid gap-4 sm:grid-cols-3">
        <UCard>
          <p class="text-xs font-medium uppercase tracking-wide text-gray-500">
            {{ t('setup.roles.permissions.count') }}
          </p>
          <p class="mt-1 text-2xl font-bold font-heading">
            {{ grantedCount }}
          </p>
        </UCard>
        <UCard>
          <p class="text-xs font-medium uppercase tracking-wide text-gray-500">
            {{ t('setup.roles.userCount') }}
          </p>
          <p class="mt-1 text-2xl font-bold font-heading">
            {{ role.user_count }}
          </p>
        </UCard>
        <UCard>
          <p class="text-xs font-medium uppercase tracking-wide text-gray-500">
            {{ t('setup.roles.manage.modules') }}
          </p>
          <p class="mt-1 text-2xl font-bold font-heading">
            {{ permissionModules.length }}
          </p>
        </UCard>
      </div>

      <UCard class="mb-6">
        <template #header>
          <h2 class="font-semibold font-heading">
            {{ t('setup.roles.manage.details') }}
          </h2>
        </template>

        <form
          class="grid gap-4 md:grid-cols-2"
          @submit.prevent="save"
        >
          <UFormField
            :label="t('setup.roles.label')"
            required
            class="md:col-span-1"
          >
            <UInput v-model="label" />
          </UFormField>

          <UFormField
            :label="t('setup.roles.code')"
            class="md:col-span-1"
          >
            <UInput
              :model-value="role.code"
              disabled
            />
          </UFormField>

          <UFormField
            :label="t('setup.roles.descriptionLabel')"
            class="md:col-span-2"
          >
            <UTextarea
              v-model="description"
              :rows="2"
            />
          </UFormField>

          <UFormField
            :label="t('setup.roles.status')"
            class="md:col-span-2"
          >
            <div class="flex items-center gap-3">
              <USwitch
                v-model="isActive"
                :disabled="role.is_system"
              />
              <span class="text-sm text-gray-600 dark:text-gray-400">
                {{ isActive ? t('setup.roles.active') : t('setup.roles.inactive') }}
              </span>
            </div>
          </UFormField>
        </form>
      </UCard>

      <UCard>
        <template #header>
          <div class="flex flex-wrap items-center justify-between gap-2">
            <h2 class="font-semibold font-heading">
              {{ t('setup.roles.permissions.title') }}
            </h2>
            <p class="text-sm text-gray-500">
              {{ t('setup.roles.permissions.granted', { count: grantedCount }) }}
            </p>
          </div>
        </template>

        <OrgRolePermissionsEditor v-model:permissions="permissions" />
      </UCard>

      <p
        v-if="savedMsg"
        class="mt-4 text-sm text-green-600"
      >
        {{ savedMsg }}
      </p>
      <p
        v-if="errorMsg"
        class="mt-4 text-sm text-red-500"
      >
        {{ errorMsg }}
      </p>

      <div class="mt-6 flex flex-wrap items-center justify-between gap-4 border-t border-gray-200 pt-6 dark:border-gray-800">
        <UButton
          color="error"
          variant="outline"
          icon="i-lucide-trash-2"
          :disabled="!canDelete"
          @click="deleteOpen = true"
        >
          {{ t('setup.roles.delete') }}
        </UButton>

        <UButton
          :loading="saving"
          icon="i-lucide-save"
          @click="save"
        >
          {{ t('common.save') }}
        </UButton>
      </div>

      <OrgRoleDeleteModal
        v-model:open="deleteOpen"
        :role="role"
        @deleted="onDeleted"
      />
    </template>
  </div>
</template>
