<script setup lang="ts">
import type { OrgCompanyProfile } from '~/types/crm'
import { appTableBadgeClass, appTableTextClass } from '~/config/appFormUi'
import {
  localizedOrgCompanyAddress,
  localizedOrgCompanyName
} from '~/utils/orgCompanyProfile'

type CompanyProfilesViewMode = 'table' | 'grid'

const { t, locale } = useI18n()
const { list, remove } = useOrgCompanyProfiles()

const profiles = ref<OrgCompanyProfile[]>([])
const loading = ref(true)
const viewMode = ref<CompanyProfilesViewMode>('table')
const formOpen = ref(false)
const editingProfile = ref<OrgCompanyProfile | null>(null)
const deleteOpen = ref(false)
const deletingProfile = ref<OrgCompanyProfile | null>(null)
const deleting = ref(false)
const deleteError = ref('')

async function refresh() {
  loading.value = true
  try {
    profiles.value = await list()
  } catch (e) {
    console.error(e)
    profiles.value = []
  } finally {
    loading.value = false
  }
}

await refresh()

function openCreate() {
  editingProfile.value = null
  formOpen.value = true
}

function openEdit(profile: OrgCompanyProfile) {
  editingProfile.value = profile
  formOpen.value = true
}

function openDelete(profile: OrgCompanyProfile) {
  deletingProfile.value = profile
  deleteError.value = ''
  deleteOpen.value = true
}

async function confirmDelete() {
  if (!deletingProfile.value) return
  deleting.value = true
  deleteError.value = ''
  try {
    await remove(deletingProfile.value.id, deletingProfile.value.logoUrl)
    deleteOpen.value = false
    deletingProfile.value = null
    await refresh()
  } catch (e) {
    deleteError.value = e instanceof Error ? e.message : t('common.deleteFailed')
  } finally {
    deleting.value = false
  }
}

function displayAddress(profile: OrgCompanyProfile) {
  return localizedOrgCompanyAddress(profile, locale.value)
}

function displayCompany(profile: OrgCompanyProfile) {
  return localizedOrgCompanyName(profile, locale.value)
}
</script>

<template>
  <div>
    <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
      <p class="text-sm text-gray-500 dark:text-gray-400">
        {{ t('setup.settings.companyInfo.listHint') }}
      </p>
      <div class="flex flex-wrap items-center gap-2">
        <div
          v-if="profiles.length"
          class="inline-flex shrink-0 rounded-lg border border-gray-200 p-0.5 dark:border-gray-700"
          role="group"
          :aria-label="t('setup.settings.companyInfo.viewTable')"
        >
          <UButton
            size="sm"
            :variant="viewMode === 'table' ? 'solid' : 'soft'"
            :color="viewMode === 'table' ? 'primary' : 'neutral'"
            icon="i-lucide-list"
            square
            class="rounded-md"
            :aria-label="t('setup.settings.companyInfo.viewTable')"
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
            :aria-label="t('setup.settings.companyInfo.viewGrid')"
            :aria-pressed="viewMode === 'grid'"
            @click="viewMode = 'grid'"
          />
        </div>
        <UButton
          icon="i-lucide-plus"
          @click="openCreate"
        >
          {{ t('setup.settings.companyInfo.add') }}
        </UButton>
      </div>
    </div>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!profiles.length">
      <p class="text-gray-500">
        {{ t('setup.settings.companyInfo.empty') }}
      </p>
      <UButton
        class="mt-4"
        size="sm"
        icon="i-lucide-plus"
        @click="openCreate"
      >
        {{ t('setup.settings.companyInfo.addFirst') }}
      </UButton>
    </UCard>

    <div
      v-else-if="viewMode === 'table'"
      class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <AppDataTable embedded>
        <template #head>
          <tr>
            <AppDataTableTh>{{ t('setup.settings.companyInfo.columns.profile') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('setup.settings.companyInfo.columns.company') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('setup.settings.companyInfo.columns.taxId') }}</AppDataTableTh>
            <AppDataTableTh>{{ t('setup.settings.companyInfo.columns.branch') }}</AppDataTableTh>
            <AppDataTableTh class="min-w-[12rem]">
              {{ t('setup.settings.companyInfo.columns.address') }}
            </AppDataTableTh>
            <AppDataTableTh>{{ t('setup.settings.companyInfo.columns.default') }}</AppDataTableTh>
            <AppDataTableTh />
          </tr>
        </template>

        <AppDataTableRow
          v-for="profile in profiles"
          :key="profile.id"
        >
          <AppDataTableTd
            :class="appTableTextClass"
            class="font-semibold"
          >
            {{ profile.profileName }}
          </AppDataTableTd>
          <AppDataTableTd :class="appTableTextClass">
            <div>{{ displayCompany(profile).primary }}</div>
            <div
              v-if="displayCompany(profile).secondary"
              class="mt-0.5 text-sm text-gray-500 dark:text-gray-400"
            >
              {{ displayCompany(profile).secondary }}
            </div>
          </AppDataTableTd>
          <AppDataTableTd
            :class="appTableTextClass"
            muted
          >
            {{ profile.taxId || t('common.empty') }}
          </AppDataTableTd>
          <AppDataTableTd
            :class="appTableTextClass"
            muted
          >
            {{ profile.taxBranch || t('common.empty') }}
          </AppDataTableTd>
          <AppDataTableTd
            :class="appTableTextClass"
            muted
          >
            <span
              v-if="displayAddress(profile)"
              class="line-clamp-2"
            >{{ displayAddress(profile) }}</span>
            <span v-else>{{ t('common.empty') }}</span>
          </AppDataTableTd>
          <AppDataTableTd :class="appTableTextClass">
            <UBadge
              v-if="profile.isDefault"
              color="success"
              variant="subtle"
              :class="appTableBadgeClass"
            >
              {{ t('setup.settings.companyInfo.defaultBadge') }}
            </UBadge>
            <span
              v-else
              class="text-gray-400"
            >{{ t('common.empty') }}</span>
          </AppDataTableTd>
          <AppDataTableTd :class="appTableTextClass">
            <div class="flex justify-end gap-1">
              <AppIconButton
                icon="i-lucide-pencil"
                :aria-label="t('common.edit')"
                @click="openEdit(profile)"
              />
              <AppIconButton
                icon="i-lucide-trash-2"
                color="error"
                :aria-label="t('common.delete')"
                @click="openDelete(profile)"
              />
            </div>
          </AppDataTableTd>
        </AppDataTableRow>
      </AppDataTable>
    </div>

    <div
      v-else
      class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4"
    >
      <SetupSettingsCompanyProfileCard
        v-for="profile in profiles"
        :key="profile.id"
        :profile="profile"
        @edit="openEdit"
        @delete="openDelete"
      />
    </div>

    <SetupSettingsCompanyProfileFormModal
      v-model:open="formOpen"
      :profile="editingProfile"
      :is-first-profile="!profiles.length"
      @saved="refresh"
    />

    <AppDialog
      v-model:open="deleteOpen"
      :title="t('setup.settings.companyInfo.deleteTitle')"
      size="sm"
    >
      <p class="text-sm text-gray-600 dark:text-gray-300">
        {{ t('setup.settings.companyInfo.deleteConfirm', { name: deletingProfile?.profileName ?? '' }) }}
      </p>
      <p
        v-if="deleteError"
        class="mt-3 text-sm text-red-600 dark:text-red-300"
      >
        {{ deleteError }}
      </p>

      <template #footer>
        <AppDialogFooter @cancel="deleteOpen = false">
          <UButton
            color="error"
            size="lg"
            :loading="deleting"
            @click="confirmDelete"
          >
            {{ t('common.delete') }}
          </UButton>
        </AppDialogFooter>
      </template>
    </AppDialog>
  </div>
</template>
