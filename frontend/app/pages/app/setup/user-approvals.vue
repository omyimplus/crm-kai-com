<script setup lang="ts">
import type { OrgUser } from '~/types/crm'
import {
  appFormErrorClass,
  appFormFieldClass,
  appFormHintClass
} from '~/config/appFormUi'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { ensureProfile } = useProfile()
const { canManage, list, update } = useSystemUsers()
const { list: listOrgRoles, activeRoles } = useOrgRoles()

await ensureProfile()

if (!canManage.value) {
  await navigateTo('/app')
}

const users = ref<OrgUser[]>([])
const orgRoles = ref<Awaited<ReturnType<typeof listOrgRoles>>>([])
const loading = ref(true)
const approving = ref(false)
const approveOpen = ref(false)
const approvingUser = ref<OrgUser | null>(null)
const approveOrgRoleIds = ref<string[]>([])
const errorMsg = ref('')

const pendingUsers = computed(() =>
  users.value.filter(user => !user.is_active)
)

const {
  page,
  pagedItems,
  totalItems: paginationTotal,
  totalPages,
  rangeStart,
  rangeEnd,
  pageSize
} = usePagination(pendingUsers)

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
  return user.full_name?.trim() || user.email || t('common.user')
}

function openApprove(user: OrgUser) {
  approvingUser.value = user
  approveOrgRoleIds.value = []
  errorMsg.value = ''
  approveOpen.value = true
}

async function confirmApprove() {
  if (!approvingUser.value) return
  if (!approveOrgRoleIds.value.length) {
    errorMsg.value = t('setup.userApprovals.orgRoleRequired')
    return
  }

  approving.value = true
  errorMsg.value = ''
  try {
    await update(approvingUser.value.id, {
      is_active: true,
      org_role_ids: approveOrgRoleIds.value
    })
    approveOpen.value = false
    approvingUser.value = null
    await refresh()
  } catch (e: unknown) {
    errorMsg.value = e instanceof Error ? e.message : t('common.saveFailed')
  } finally {
    approving.value = false
  }
}
</script>

<template>
  <div>
    <div class="mb-6">
      <h1 class="text-2xl font-bold font-heading">
        {{ t('setup.userApprovals.title') }}
      </h1>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        {{ t('setup.userApprovals.subtitle') }}
      </p>
    </div>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!pendingUsers.length">
      <p class="text-gray-500">
        {{ t('setup.userApprovals.empty') }}
      </p>
    </UCard>

    <div
      v-else
      class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <AppDataTable embedded>
      <template #head>
        <tr>
          <AppDataTableTh>{{ t('setup.systemUsers.fullName') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('setup.systemUsers.email') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('setup.systemUsers.platformRole') }}</AppDataTableTh>
          <AppDataTableTh>{{ t('setup.systemUsers.status') }}</AppDataTableTh>
          <AppDataTableTh />
        </tr>
      </template>

      <AppDataTableRow
        v-for="user in pagedItems"
        :key="user.id"
      >
        <AppDataTableTd class="font-medium">
          {{ displayName(user) }}
        </AppDataTableTd>
        <AppDataTableTd muted>
          {{ user.email || t('common.empty') }}
        </AppDataTableTd>
        <AppDataTableTd>
          <UBadge
            color="neutral"
            variant="subtle"
          >
            {{ t(`profile.roles.${user.role}`) }}
          </UBadge>
        </AppDataTableTd>
        <AppDataTableTd>
          <UBadge
            color="warning"
            variant="subtle"
          >
            {{ t('setup.userApprovals.pendingBadge') }}
          </UBadge>
        </AppDataTableTd>
        <AppDataTableTd align="right">
          <UButton
            size="sm"
            variant="soft"
            color="primary"
            icon="i-lucide-user-check"
            class="rounded-lg"
            @click="openApprove(user)"
          >
            {{ t('setup.userApprovals.approve') }}
          </UButton>
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

    <AppDialog
      v-model:open="approveOpen"
      :title="t('setup.userApprovals.approveTitle')"
      size="md"
    >
      <div class="space-y-5">
        <p class="text-sm leading-relaxed text-gray-600 dark:text-gray-400">
          {{ t('setup.userApprovals.approveHint', { name: approvingUser ? displayName(approvingUser) : '' }) }}
        </p>
        <UFormField
          :class="appFormFieldClass"
          :label="t('setup.systemUsers.orgRole')"
          required
        >
          <AppOrgRoleChipSelect
            v-model="approveOrgRoleIds"
            :options="orgRoleOptions"
          />
          <p :class="appFormHintClass">
            {{ t('setup.systemUsers.orgRoleHint') }}
          </p>
        </UFormField>
        <p
          v-if="errorMsg"
          :class="appFormErrorClass"
        >
          {{ errorMsg }}
        </p>
      </div>

      <template #footer>
        <AppDialogFooter @cancel="approveOpen = false">
          <UButton
            class="w-full sm:w-auto"
            size="lg"
            icon="i-lucide-check"
            :loading="approving"
            @click="confirmApprove"
          >
            {{ t('setup.userApprovals.approveConfirm') }}
          </UButton>
        </AppDialogFooter>
      </template>
    </AppDialog>
  </div>
</template>
