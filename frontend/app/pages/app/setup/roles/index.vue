<script setup lang="ts">
import type { OrgRole } from '~/types/crm'
import { ORG_SYSTEM_ROLE_CODES } from '~/config/orgRoleSystemCodes'
import { countGrantedPermissions } from '~/utils/orgRolePermissions'

definePageMeta({ middleware: 'auth', layout: 'app' })

type RolesViewMode = 'table' | 'grid'

const { t } = useI18n()
const { ensureProfile } = useProfile()
const { canManage, list } = useOrgRoles()

await ensureProfile()

if (!canManage.value) {
  await navigateTo('/app')
}

const roles = ref<OrgRole[]>([])
const loading = ref(true)
const formOpen = ref(false)
const editingRole = ref<OrgRole | null>(null)
const deleteOpen = ref(false)
const deletingRole = ref<OrgRole | null>(null)
const search = ref('')
const viewMode = ref<RolesViewMode>('table')

async function refresh() {
  loading.value = true
  try {
    const rows = await list()
    const systemOrder = new Map(ORG_SYSTEM_ROLE_CODES.map((code, index) => [code, index]))
    roles.value = rows.sort((a, b) => {
      if (a.is_system !== b.is_system) return a.is_system ? -1 : 1
      const ai = systemOrder.get(a.code as typeof ORG_SYSTEM_ROLE_CODES[number]) ?? 99
      const bi = systemOrder.get(b.code as typeof ORG_SYSTEM_ROLE_CODES[number]) ?? 99
      if (ai !== bi) return ai - bi
      return a.label.localeCompare(b.label, undefined, { sensitivity: 'base' })
    })
  } catch (e) {
    console.error(e)
    roles.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

const filteredRoles = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return roles.value
  return roles.value.filter(role =>
    role.label.toLowerCase().includes(q)
    || role.code.toLowerCase().includes(q)
    || (role.description?.toLowerCase().includes(q) ?? false)
  )
})

const stats = computed(() => ({
  total: roles.value.length,
  active: roles.value.filter(role => role.is_active).length,
  users: roles.value.reduce((sum, role) => sum + role.user_count, 0)
}))

const {
  page,
  pagedItems,
  totalItems: paginationTotal,
  totalPages,
  rangeStart,
  rangeEnd,
  pageSize
} = usePagination(filteredRoles)

function openCreate() {
  editingRole.value = null
  formOpen.value = true
}

function openEdit(role: OrgRole) {
  editingRole.value = role
  formOpen.value = true
}

function onFormSaved() {
  refresh()
  editingRole.value = null
}

function openDelete(role: OrgRole) {
  deletingRole.value = role
  deleteOpen.value = true
}

function onDeleted() {
  deleteOpen.value = false
  deletingRole.value = null
  refresh()
}

function canDeleteRole(role: OrgRole) {
  return !role.is_system && role.user_count === 0
}

function permissionCount(role: OrgRole) {
  return countGrantedPermissions(role.permissions)
}
</script>

<template>
  <div>
    <div class="mb-6 flex flex-wrap items-center justify-between gap-4">
      <div>
        <h1 class="text-2xl font-bold font-heading">
          {{ t('setup.roles.pageTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('setup.roles.pageSubtitle') }}
        </p>
      </div>
      <UButton
        icon="i-lucide-shield-plus"
        @click="openCreate"
      >
        {{ t('setup.roles.create') }}
      </UButton>
    </div>

    <div
      v-if="!loading && roles.length"
      class="mb-6 grid gap-4 sm:grid-cols-3"
    >
      <UCard>
        <p class="text-xs font-medium uppercase tracking-wide text-gray-500">
          {{ t('setup.roles.manage.stats.total') }}
        </p>
        <p class="mt-1 text-2xl font-bold font-heading">
          {{ stats.total }}
        </p>
      </UCard>
      <UCard>
        <p class="text-xs font-medium uppercase tracking-wide text-gray-500">
          {{ t('setup.roles.manage.stats.active') }}
        </p>
        <p class="mt-1 text-2xl font-bold font-heading">
          {{ stats.active }}
        </p>
      </UCard>
      <UCard>
        <p class="text-xs font-medium uppercase tracking-wide text-gray-500">
          {{ t('setup.roles.manage.stats.assigned') }}
        </p>
        <p class="mt-1 text-2xl font-bold font-heading">
          {{ stats.users }}
        </p>
      </UCard>
    </div>

    <UCard
      v-if="!loading && roles.length"
      class="mb-4"
    >
      <div class="flex flex-wrap items-center gap-3">
        <UInput
          v-model="search"
          class="min-w-0 flex-1"
          icon="i-lucide-search"
          :placeholder="t('setup.roles.manage.search')"
        />
        <div
          class="inline-flex shrink-0 rounded-lg border border-gray-200 p-0.5 dark:border-gray-700"
          role="group"
          :aria-label="t('setup.roles.manage.viewTable')"
        >
          <UButton
            size="sm"
            :variant="viewMode === 'table' ? 'solid' : 'soft'"
            :color="viewMode === 'table' ? 'primary' : 'neutral'"
            icon="i-lucide-list"
            square
            class="rounded-md"
            :aria-label="t('setup.roles.manage.viewTable')"
            :aria-pressed="viewMode === 'table'"
            @click="viewMode = 'table'"
          />
          <UButton
            size="sm"
            :variant="viewMode === 'grid' ? 'solid' : 'soft'"
            :color="viewMode === 'grid' ? 'primary' : 'neutral'"
            icon="i-lucide-layout-grid"
            square
            class="rounded-md"
            :aria-label="t('setup.roles.manage.viewGrid')"
            :aria-pressed="viewMode === 'grid'"
            @click="viewMode = 'grid'"
          />
        </div>
      </div>
    </UCard>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!roles.length">
      <div class="py-6 text-center">
        <div class="mx-auto mb-4 flex size-14 items-center justify-center rounded-full bg-primary/10 text-primary">
          <UIcon
            name="i-lucide-shield-check"
            class="size-7"
          />
        </div>
        <p class="text-gray-600 dark:text-gray-300">
          {{ t('setup.roles.empty') }}
        </p>
        <p class="mt-1 text-sm text-gray-500">
          {{ t('setup.roles.manage.emptyHint') }}
        </p>
        <UButton
          class="mt-4"
          icon="i-lucide-shield-plus"
          @click="openCreate"
        >
          {{ t('setup.roles.createFirst') }}
        </UButton>
      </div>
    </UCard>

    <UCard v-else-if="!filteredRoles.length">
      <p class="text-gray-500">
        {{ t('setup.roles.manage.noResults') }}
      </p>
    </UCard>

    <div
      v-else-if="viewMode === 'table'"
      class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <AppDataTable embedded>
      <template #head>
        <tr>
          <AppDataTableTh>{{ t('setup.roles.label') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('setup.roles.code') }}</AppDataTableTh>
          <AppDataTableTh class="hidden md:table-cell">
            {{ t('setup.roles.descriptionLabel') }}
          </AppDataTableTh>
          <AppDataTableTh>{{ t('setup.roles.permissions.count') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('setup.roles.userCount') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('setup.roles.status') }}</AppDataTableTh>
          <AppDataTableTh />
        </tr>
      </template>

      <AppDataTableRow
        v-for="role in pagedItems"
        :key="role.id"
      >
        <AppDataTableTd>
          <div class="flex flex-wrap items-center gap-2">
            <span class="font-medium">
              {{ role.label }}
            </span>
            <UBadge
              v-if="role.is_system"
              color="info"
              variant="subtle"
              size="sm"
            >
              {{ t('setup.roles.manage.systemBadge') }}
            </UBadge>
          </div>
        </AppDataTableTd>
        <AppDataTableTd class="font-mono text-xs text-gray-500">
          {{ role.code }}
        </AppDataTableTd>
        <AppDataTableTd
          muted
          class="hidden max-w-xs md:table-cell"
        >
          <span class="line-clamp-2">
            {{ role.description || t('common.empty') }}
          </span>
        </AppDataTableTd>
        <AppDataTableTd>{{ permissionCount(role) }}</AppDataTableTd>
        <AppDataTableTd>{{ role.user_count }}</AppDataTableTd>
        <AppDataTableTd>
          <UBadge
            :color="role.is_active ? 'success' : 'neutral'"
            variant="subtle"
            size="sm"
          >
            {{ role.is_active ? t('setup.roles.active') : t('setup.roles.inactive') }}
          </UBadge>
        </AppDataTableTd>
        <AppDataTableTd>
          <div class="flex items-center justify-end gap-1.5">
            <AppIconButton
              icon="i-lucide-pencil"
              :aria-label="t('setup.roles.edit')"
              @click="openEdit(role)"
            />
            <UButton
              :to="`/app/setup/roles/${role.id}`"
              size="xs"
              variant="soft"
              color="primary"
              icon="i-lucide-sliders-horizontal"
              class="rounded-lg"
            >
              {{ t('setup.roles.card.configure') }}
            </UButton>
            <AppIconButton
              v-if="canDeleteRole(role)"
              icon="i-lucide-trash-2"
              color="error"
              :aria-label="t('setup.roles.delete')"
              @click="openDelete(role)"
            />
          </div>
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

    <div v-else>
      <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4">
        <SetupOrgRoleCard
          v-for="role in pagedItems"
          :key="role.id"
          :role="role"
          @edit="openEdit"
          @delete="openDelete"
        />
      </div>

      <AppPagination
        v-model:page="page"
        class="mt-4"
        :total-items="paginationTotal"
        :total-pages="totalPages"
        :range-start="rangeStart"
        :range-end="rangeEnd"
        :page-size="pageSize"
      />
    </div>

    <SetupOrgRoleFormModal
      v-model:open="formOpen"
      :role="editingRole"
      :navigate-on-create="true"
      @saved="onFormSaved"
    />

    <SetupOrgRoleDeleteModal
      v-model:open="deleteOpen"
      :role="deletingRole"
      @deleted="onDeleted"
    />
  </div>
</template>
