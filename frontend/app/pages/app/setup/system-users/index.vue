<script setup lang="ts">
import type { OrgUser, ProfileRole } from '~/types/crm'
import {
  appPlatformRoleBadgeClass,
  appTableBadgeClass,
  appTableRoleTabActiveClass,
  appTableRoleTabBaseClass,
  appTableRoleTabInactiveClass,
  appTableTextClass
} from '~/config/appFormUi'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { ensureProfile, profile, fetchProfile } = useProfile()
const { canManage, list, assignableRoles } = useSystemUsers()
const { reloadPermissions } = usePermissions()
const { list: listOrgRoles, activeRoles } = useOrgRoles()

await ensureProfile()

if (!canManage.value) {
  await navigateTo('/app')
}

type UserSearchField = 'all' | 'name' | 'email' | 'username'
type RoleTab = 'all' | ProfileRole

const users = ref<OrgUser[]>([])
const orgRoles = ref<Awaited<ReturnType<typeof listOrgRoles>>>([])
const loading = ref(true)
const formOpen = ref(false)
const editingUser = ref<OrgUser | null>(null)
const search = ref('')
const searchField = ref<UserSearchField>('all')
const roleTab = ref<RoleTab>('all')

const roleOptions = computed(() => assignableRoles(profile.value?.role))
const orgRoleOptions = computed(() => activeRoles(orgRoles.value))

const searchFieldOptions = computed(() => [
  { label: t('setup.systemUsers.filters.viewAll'), value: 'all' as const },
  { label: t('setup.systemUsers.filters.byName'), value: 'name' as const },
  { label: t('setup.systemUsers.filters.byEmail'), value: 'email' as const },
  { label: t('setup.systemUsers.filters.byUsername'), value: 'username' as const }
])

const roleTabs = computed(() => [
  { label: t('setup.systemUsers.filters.viewAll'), value: 'all' as const },
  { label: t('profile.roles.owner'), value: 'owner' as const },
  { label: t('profile.roles.admin'), value: 'admin' as const },
  { label: t('profile.roles.employee'), value: 'employee' as const }
])

const filteredUsers = computed(() => {
  let rows = users.value
  if (roleTab.value !== 'all') {
    rows = rows.filter(user => user.role === roleTab.value)
  }

  const q = search.value.trim().toLowerCase()
  if (!q) return rows

  return rows.filter((user) => {
    const name = (user.full_name ?? '').toLowerCase()
    const email = (user.email ?? '').toLowerCase()
    const username = (user.username ?? '').toLowerCase()

    if (searchField.value === 'name') return name.includes(q)
    if (searchField.value === 'email') return email.includes(q)
    if (searchField.value === 'username') return username.includes(q)
    return name.includes(q) || email.includes(q) || username.includes(q)
  })
})

const {
  page,
  pagedItems,
  totalItems: paginationTotal,
  totalPages,
  rangeStart,
  rangeEnd,
  pageSize,
  resetPage: resetPagination
} = usePagination(filteredUsers)

const hasActiveFilters = computed(() =>
  search.value.trim().length > 0
  || searchField.value !== 'all'
  || roleTab.value !== 'all'
)

function clearFilters() {
  search.value = ''
  searchField.value = 'all'
  roleTab.value = 'all'
  resetPagination()
}

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

async function onSaved() {
  await refresh()
  await fetchProfile()
  await reloadPermissions()
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

    <div v-else>
      <UCard class="mb-4">
        <div class="flex flex-wrap items-end gap-3">
          <UFormField
            :label="t('setup.systemUsers.filters.searchBy')"
            class="min-w-44"
          >
            <USelectMenu
              v-model="searchField"
              :items="searchFieldOptions"
              value-key="value"
              class="w-full"
            />
          </UFormField>

          <UInput
            v-model="search"
            class="min-w-0 flex-1"
            icon="i-lucide-search"
            :placeholder="t('setup.systemUsers.filters.search')"
          />

          <UButton
            v-if="hasActiveFilters"
            variant="soft"
            color="neutral"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('setup.systemUsers.filters.viewAll') }}
          </UButton>
        </div>
      </UCard>

      <div class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800">
        <div
          class="flex flex-wrap gap-2 border-b border-gray-200 bg-gray-50/90 px-3 py-2.5 dark:border-gray-800 dark:bg-gray-900/60"
          role="tablist"
          :aria-label="t('setup.systemUsers.filters.roleTabs')"
        >
          <button
            v-for="tab in roleTabs"
            :key="tab.value"
            type="button"
            role="tab"
            :aria-selected="roleTab === tab.value"
            :class="[
              appTableRoleTabBaseClass,
              appTableTextClass,
              roleTab === tab.value ? appTableRoleTabActiveClass : appTableRoleTabInactiveClass
            ]"
            @click="roleTab = tab.value"
          >
            {{ tab.label }}
          </button>
        </div>

        <p
          class="border-b border-gray-200 px-3 py-2 text-gray-600 dark:border-gray-800 dark:text-gray-400"
          :class="appTableTextClass"
        >
          {{ t('setup.systemUsers.filters.displayCount', { count: paginationTotal }) }}
        </p>

        <div
          v-if="!filteredUsers.length"
          class="px-4 py-8 text-center"
        >
          <p class="text-gray-500">
            {{ t('setup.systemUsers.filters.noResults') }}
          </p>
          <UButton
            class="mt-4"
            size="sm"
            variant="soft"
            icon="i-lucide-rotate-ccw"
            @click="clearFilters"
          >
            {{ t('setup.systemUsers.filters.viewAll') }}
          </UButton>
        </div>

        <AppDataTable
          v-else
          embedded
        >
      <template #head>
        <tr>
          <AppDataTableTh>{{ t('setup.systemUsers.fullName') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('setup.systemUsers.email') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('setup.systemUsers.username') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('profile.role') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('setup.systemUsers.orgRole') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('setup.systemUsers.status') }}</AppDataTableTh>
          <AppDataTableTh />
        </tr>
      </template>

      <AppDataTableRow
        v-for="user in pagedItems"
        :key="user.id"
      >
        <AppDataTableTd>
          <div class="flex items-center gap-3">
            <AppUserAvatar
              :src="user.avatar_url"
              :alt="displayName(user)"
              size="sm"
            />
            <span class="font-medium">
              {{ displayName(user) }}
            </span>
          </div>
        </AppDataTableTd>
        <AppDataTableTd muted>
          {{ user.email || t('common.empty') }}
        </AppDataTableTd>
        <AppDataTableTd muted>
          {{ user.username || t('common.empty') }}
        </AppDataTableTd>
        <AppDataTableTd>
          <UBadge
            variant="subtle"
            :class="[appTableBadgeClass, appPlatformRoleBadgeClass[user.role]]"
          >
            {{ t(`profile.roles.${user.role}`) }}
          </UBadge>
        </AppDataTableTd>
        <AppDataTableTd>
          <div
            v-if="user.org_role_labels?.length"
            class="flex flex-wrap gap-1"
          >
            <UBadge
              v-for="label in user.org_role_labels"
              :key="label"
              color="primary"
              variant="subtle"
              size="sm"
              :class="['rounded-full', appTableBadgeClass]"
            >
              {{ label }}
            </UBadge>
          </div>
          <span
            v-else
            class="text-gray-400"
          >
            {{ t('common.empty') }}
          </span>
        </AppDataTableTd>
        <AppDataTableTd>
          <UBadge
            :color="user.is_active ? 'success' : 'neutral'"
            variant="subtle"
            :class="appTableBadgeClass"
          >
            {{ user.is_active ? t('setup.systemUsers.active') : t('setup.systemUsers.inactive') }}
          </UBadge>
        </AppDataTableTd>
        <AppDataTableTd align="right">
          <AppIconButton
            icon="i-lucide-pencil"
            :aria-label="t('setup.systemUsers.edit')"
            @click="openEdit(user)"
          />
        </AppDataTableTd>
      </AppDataTableRow>
        </AppDataTable>

        <AppPagination
          v-model:page="page"
          embedded
          :total-items="paginationTotal"
          :total-pages="totalPages"
          :range-start="rangeStart"
          :range-end="rangeEnd"
          :page-size="pageSize"
        />
      </div>
    </div>

    <SetupSystemUserFormModal
      v-model:open="formOpen"
      :user="editingUser"
      :role-options="roleOptions"
      :org-role-options="orgRoleOptions"
      @saved="onSaved"
    />
  </div>
</template>
