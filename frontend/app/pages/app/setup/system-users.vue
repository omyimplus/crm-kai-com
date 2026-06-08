<script setup lang="ts">
import type { OrgUser } from '~/types/crm'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { ensureProfile, profile } = useProfile()
const { canManage, list, assignableRoles } = useSystemUsers()
const { list: listOrgRoles, activeRoles } = useOrgRoles()

await ensureProfile()

if (!canManage.value) {
  await navigateTo('/app')
}

const users = ref<OrgUser[]>([])
const orgRoles = ref<Awaited<ReturnType<typeof listOrgRoles>>>([])
const loading = ref(true)
const formOpen = ref(false)
const editingUser = ref<OrgUser | null>(null)

const roleOptions = computed(() => assignableRoles(profile.value?.role))
const orgRoleOptions = computed(() => activeRoles(orgRoles.value))

async function refresh() {
  loading.value = true
  try {
    const [userRows, roleRows] = await Promise.all([list(), listOrgRoles()])
    users.value = userRows
    orgRoles.value = roleRows
  } catch (e) {
    console.error(e)
    users.value = []
    orgRoles.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

function displayName(user: OrgUser) {
  return user.full_name?.trim() || user.username || user.email || t('common.user')
}

function openCreate() {
  editingUser.value = null
  formOpen.value = true
}

function openEdit(user: OrgUser) {
  editingUser.value = user
  formOpen.value = true
}

function roleBadgeColor(role: OrgUser['role']) {
  if (role === 'owner') return 'primary'
  if (role === 'admin') return 'info'
  if (role === 'readonly') return 'neutral'
  return 'success'
}
</script>

<template>
  <div>
    <div class="mb-6 flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold font-heading">
          {{ t('setup.systemUsers.title') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('setup.systemUsers.subtitle') }}
        </p>
      </div>
      <UButton
        icon="i-lucide-user-plus"
        @click="openCreate"
      >
        {{ t('setup.systemUsers.create') }}
      </UButton>
    </div>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!users.length">
      <p class="text-gray-500">
        {{ t('setup.systemUsers.empty') }}
      </p>
      <UButton
        class="mt-4"
        size="sm"
        icon="i-lucide-user-plus"
        @click="openCreate"
      >
        {{ t('setup.systemUsers.createFirst') }}
      </UButton>
    </UCard>

    <div
      v-else
      class="overflow-x-auto rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <table class="w-full text-sm">
        <thead class="bg-gray-50 dark:bg-gray-900">
          <tr>
            <th class="p-3 text-left font-medium">
              {{ t('setup.systemUsers.fullName') }}
            </th>
            <th class="p-3 text-left font-medium">
              {{ t('setup.systemUsers.email') }}
            </th>
            <th class="p-3 text-left font-medium">
              {{ t('setup.systemUsers.username') }}
            </th>
            <th class="p-3 text-left font-medium">
              {{ t('profile.role') }}
            </th>
            <th class="p-3 text-left font-medium">
              {{ t('setup.systemUsers.orgRole') }}
            </th>
            <th class="p-3 text-left font-medium">
              {{ t('setup.systemUsers.status') }}
            </th>
            <th class="p-3" />
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="user in users"
            :key="user.id"
            class="border-t border-gray-200 dark:border-gray-800"
          >
            <td class="p-3">
              <div class="flex items-center gap-3">
                <UAvatar
                  :src="user.avatar_url ?? undefined"
                  :alt="displayName(user)"
                  :text="displayName(user).slice(0, 2).toUpperCase()"
                  size="sm"
                />
                <span class="font-medium">
                  {{ displayName(user) }}
                </span>
              </div>
            </td>
            <td class="p-3 text-gray-600 dark:text-gray-400">
              {{ user.email || t('common.empty') }}
            </td>
            <td class="p-3 text-gray-600 dark:text-gray-400">
              {{ user.username || t('common.empty') }}
            </td>
            <td class="p-3">
              <UBadge
                :color="roleBadgeColor(user.role)"
                variant="subtle"
              >
                {{ t(`profile.roles.${user.role}`) }}
              </UBadge>
            </td>
            <td class="p-3 text-gray-600 dark:text-gray-400">
              {{ user.org_role_label || t('common.empty') }}
            </td>
            <td class="p-3">
              <UBadge
                :color="user.is_active ? 'success' : 'neutral'"
                variant="subtle"
              >
                {{ user.is_active ? t('setup.systemUsers.active') : t('setup.systemUsers.inactive') }}
              </UBadge>
            </td>
            <td class="p-3 text-right">
              <UButton
                size="xs"
                variant="ghost"
                color="neutral"
                icon="i-lucide-pencil"
                :aria-label="t('setup.systemUsers.edit')"
                @click="openEdit(user)"
              />
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <SystemUserFormModal
      v-model:open="formOpen"
      :user="editingUser"
      :role-options="roleOptions"
      :org-role-options="orgRoleOptions"
      @saved="refresh"
    />
  </div>
</template>
