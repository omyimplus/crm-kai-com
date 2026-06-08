<script setup lang="ts">
import type { OrgRole } from '~/types/crm'
import { countGrantedPermissions } from '~/utils/orgRolePermissions'

definePageMeta({ middleware: 'auth', layout: 'app' })

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
const search = ref('')

async function refresh() {
  loading.value = true
  try {
    roles.value = await list()
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

function openCreate() {
  editingRole.value = null
  formOpen.value = true
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
          {{ t('masterData.roles.pageTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.roles.pageSubtitle') }}
        </p>
      </div>
      <UButton
        icon="i-lucide-shield-plus"
        @click="openCreate"
      >
        {{ t('masterData.roles.create') }}
      </UButton>
    </div>

    <div
      v-if="!loading && roles.length"
      class="mb-6 grid gap-4 sm:grid-cols-3"
    >
      <UCard>
        <p class="text-xs font-medium uppercase tracking-wide text-gray-500">
          {{ t('masterData.roles.manage.stats.total') }}
        </p>
        <p class="mt-1 text-2xl font-bold font-heading">
          {{ stats.total }}
        </p>
      </UCard>
      <UCard>
        <p class="text-xs font-medium uppercase tracking-wide text-gray-500">
          {{ t('masterData.roles.manage.stats.active') }}
        </p>
        <p class="mt-1 text-2xl font-bold font-heading">
          {{ stats.active }}
        </p>
      </UCard>
      <UCard>
        <p class="text-xs font-medium uppercase tracking-wide text-gray-500">
          {{ t('masterData.roles.manage.stats.assigned') }}
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
      <UInput
        v-model="search"
        icon="i-lucide-search"
        :placeholder="t('masterData.roles.manage.search')"
      />
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
          {{ t('masterData.roles.empty') }}
        </p>
        <p class="mt-1 text-sm text-gray-500">
          {{ t('masterData.roles.manage.emptyHint') }}
        </p>
        <UButton
          class="mt-4"
          icon="i-lucide-shield-plus"
          @click="openCreate"
        >
          {{ t('masterData.roles.createFirst') }}
        </UButton>
      </div>
    </UCard>

    <UCard v-else-if="!filteredRoles.length">
      <p class="text-gray-500">
        {{ t('masterData.roles.manage.noResults') }}
      </p>
    </UCard>

    <div
      v-else
      class="grid gap-4 md:grid-cols-2 xl:grid-cols-3"
    >
      <UCard
        v-for="role in filteredRoles"
        :key="role.id"
        class="transition-shadow hover:shadow-md"
      >
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <div class="flex flex-wrap items-center gap-2">
              <h3 class="font-semibold font-heading">
                {{ role.label }}
              </h3>
              <UBadge
                :color="role.is_active ? 'success' : 'neutral'"
                variant="subtle"
                size="sm"
              >
                {{ role.is_active ? t('masterData.roles.active') : t('masterData.roles.inactive') }}
              </UBadge>
            </div>
            <p class="mt-1 font-mono text-xs text-gray-500">
              {{ role.code }}
            </p>
            <p
              v-if="role.description"
              class="mt-2 line-clamp-2 text-sm text-gray-600 dark:text-gray-400"
            >
              {{ role.description }}
            </p>
          </div>
          <UIcon
            name="i-lucide-shield"
            class="size-5 shrink-0 text-primary"
          />
        </div>

        <div class="mt-4 flex flex-wrap gap-4 text-sm text-gray-500">
          <span>{{ t('masterData.roles.permissions.count') }}: {{ permissionCount(role) }}</span>
          <span>{{ t('masterData.roles.userCount') }}: {{ role.user_count }}</span>
        </div>

        <div class="mt-4 flex gap-2">
          <UButton
            :to="`/app/master-data/roles/${role.id}`"
            size="sm"
            icon="i-lucide-settings-2"
            class="flex-1"
          >
            {{ t('masterData.roles.manage.open') }}
          </UButton>
        </div>
      </UCard>
    </div>

    <OrgRoleFormModal
      v-model:open="formOpen"
      :role="editingRole"
      @saved="refresh"
    />
  </div>
</template>
