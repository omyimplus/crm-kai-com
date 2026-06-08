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

const inputUi = { base: 'w-full rounded-xl' }

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

  const trimmedLabel = label.value.trim()
  if (!trimmedLabel) {
    errorMsg.value = t('setup.roles.labelRequired')
    return
  }

  saving.value = true
  errorMsg.value = ''
  savedMsg.value = ''
  try {
    await update(role.value.id, {
      label: trimmedLabel,
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
        <div class="min-w-0 flex-1">
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
              v-if="role.is_system"
              color="info"
              variant="subtle"
            >
              {{ t('setup.roles.manage.systemBadge') }}
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

        <div class="flex w-full flex-wrap gap-2 sm:w-auto">
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
            size="lg"
            @click="save"
          >
            {{ t('common.save') }}
          </UButton>
        </div>
      </div>

      <UAlert
        v-if="savedMsg"
        class="mb-4"
        color="success"
        variant="subtle"
        :title="savedMsg"
      />

      <UAlert
        v-if="errorMsg"
        class="mb-4"
        color="error"
        variant="subtle"
        :title="errorMsg"
      />

      <div class="mb-6 grid gap-4 sm:grid-cols-3">
        <UCard class="rounded-2xl">
          <p class="text-xs font-medium uppercase tracking-wide text-gray-500">
            {{ t('setup.roles.permissions.count') }}
          </p>
          <p class="mt-1 text-2xl font-bold font-heading">
            {{ grantedCount }}
          </p>
        </UCard>
        <UCard class="rounded-2xl">
          <p class="text-xs font-medium uppercase tracking-wide text-gray-500">
            {{ t('setup.roles.userCount') }}
          </p>
          <p class="mt-1 text-2xl font-bold font-heading">
            {{ role.user_count }}
          </p>
        </UCard>
        <UCard class="rounded-2xl">
          <p class="text-xs font-medium uppercase tracking-wide text-gray-500">
            {{ t('setup.roles.manage.modules') }}
          </p>
          <p class="mt-1 text-2xl font-bold font-heading">
            {{ permissionModules.length }}
          </p>
        </UCard>
      </div>

      <UCard class="mb-6 rounded-2xl">
        <template #header>
          <h2 class="font-semibold font-heading">
            {{ t('setup.roles.manage.details') }}
          </h2>
        </template>

        <form
          class="space-y-5"
          @submit.prevent="save"
        >
          <UFormField
            class="w-full"
            :label="t('setup.roles.label')"
            required
          >
            <UInput
              v-model="label"
              class="w-full"
              size="lg"
              :ui="inputUi"
            />
          </UFormField>

          <UFormField
            class="w-full"
            :label="t('setup.roles.code')"
          >
            <UInput
              :model-value="role.code"
              class="w-full"
              size="lg"
              disabled
              :ui="inputUi"
            />
            <p class="mt-1.5 text-xs text-gray-500 dark:text-gray-400">
              {{ t('setup.roles.manage.codeReadonly') }}
            </p>
          </UFormField>

          <UFormField
            class="w-full"
            :label="t('setup.roles.descriptionLabel')"
          >
            <UTextarea
              v-model="description"
              class="w-full"
              :rows="3"
              :ui="inputUi"
            />
          </UFormField>

          <UFormField
            class="w-full"
            :label="t('setup.roles.status')"
          >
            <div class="flex w-full items-center gap-3 rounded-xl border border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-700 dark:bg-gray-800/50">
              <USwitch
                v-model="isActive"
                :disabled="role.is_system"
              />
              <span class="text-sm text-gray-600 dark:text-gray-400">
                {{ isActive ? t('setup.roles.active') : t('setup.roles.inactive') }}
              </span>
            </div>
            <p
              v-if="role.is_system"
              class="mt-1.5 text-xs text-gray-500"
            >
              {{ t('setup.roles.cannotDeactivateSystem') }}
            </p>
          </UFormField>
        </form>
      </UCard>

      <UCard class="mb-6 rounded-2xl">
        <template #header>
          <div class="flex flex-wrap items-center justify-between gap-2">
            <h2 class="font-semibold font-heading">
              {{ t('setup.roles.permissions.pagesTitle') }}
            </h2>
            <p class="text-sm text-gray-500">
              {{ t('setup.roles.permissions.granted', { count: grantedCount }) }}
            </p>
          </div>
        </template>

        <SetupOrgRolePagesEditor v-model:permissions="permissions" />
      </UCard>

      <UCard
        v-if="canDelete"
        class="rounded-2xl border-red-200 dark:border-red-900/40"
      >
        <template #header>
          <h2 class="font-semibold font-heading text-red-600 dark:text-red-400">
            {{ t('setup.roles.manage.dangerZone') }}
          </h2>
        </template>

        <p class="text-sm text-gray-600 dark:text-gray-400">
          {{ t('setup.roles.manage.deleteHint') }}
        </p>

        <UButton
          class="mt-4"
          color="error"
          variant="outline"
          icon="i-lucide-trash-2"
          @click="deleteOpen = true"
        >
          {{ t('setup.roles.delete') }}
        </UButton>
      </UCard>

      <UAlert
        v-else-if="role.is_system"
        class="rounded-2xl"
        color="info"
        variant="subtle"
        :title="t('setup.roles.cannotDeleteSystem')"
      />

      <UAlert
        v-else-if="role.user_count > 0"
        class="rounded-2xl"
        color="warning"
        variant="subtle"
        :title="t('setup.roles.cannotDeleteAssigned')"
      />

      <div class="sticky bottom-0 z-10 -mx-4 mt-6 border-t border-gray-200 bg-white/95 px-4 py-4 backdrop-blur dark:border-gray-800 dark:bg-gray-900/95 sm:-mx-6 sm:px-6">
        <div class="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
          <UButton
            class="w-full sm:w-auto"
            variant="outline"
            color="neutral"
            size="lg"
            to="/app/setup/roles"
          >
            {{ t('common.cancel') }}
          </UButton>
          <UButton
            class="w-full sm:w-auto"
            :loading="saving"
            icon="i-lucide-save"
            size="lg"
            @click="save"
          >
            {{ t('common.save') }}
          </UButton>
        </div>
      </div>

      <SetupOrgRoleDeleteModal
        v-model:open="deleteOpen"
        :role="role"
        @deleted="onDeleted"
      />
    </template>
  </div>
</template>
