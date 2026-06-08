<script setup lang="ts">
import { permissionModuleGroups, permissionModules } from '~/config/permissionModules'
import type { OrgRolePermissions } from '~/types/crm'
import { hasModuleAction, setGroupViewAll, setModuleAction } from '~/utils/orgRolePermissions'

const permissions = defineModel<OrgRolePermissions>('permissions', { required: true })

const { t } = useI18n()

function moduleLabel(group: 'app' | 'master', menuKey: string) {
  if (group === 'app') return t(`appMenu.${menuKey}.nav`)
  return t(`masterData.${menuKey}.nav`)
}

function modulesForGroup(group: 'app' | 'master') {
  return permissionModules.filter(module => module.group === group)
}

function togglePage(moduleKey: string, enabled: boolean) {
  permissions.value = setModuleAction(permissions.value, moduleKey, 'view', enabled)
}
</script>

<template>
  <div class="space-y-5">
    <UAlert
      color="info"
      variant="subtle"
      :title="t('setup.roles.permissions.pagesHint')"
    />

    <div
      v-for="section in permissionModuleGroups"
      :key="section.group"
      class="overflow-hidden rounded-xl border border-gray-200 dark:border-gray-800"
    >
      <div class="flex flex-wrap items-center justify-between gap-3 border-b border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-800 dark:bg-gray-900">
        <h3 class="text-sm font-semibold font-heading text-menu-section">
          {{ t(section.i18nKey) }}
        </h3>
        <div class="flex gap-2">
          <UButton
            size="xs"
            variant="soft"
            color="primary"
            @click="permissions = setGroupViewAll(permissions, section.group, true)"
          >
            {{ t('setup.roles.permissions.enableAllView') }}
          </UButton>
          <UButton
            size="xs"
            variant="ghost"
            color="neutral"
            @click="permissions = setGroupViewAll(permissions, section.group, false)"
          >
            {{ t('setup.roles.permissions.disableAllView') }}
          </UButton>
        </div>
      </div>

      <ul class="divide-y divide-gray-200 dark:divide-gray-800">
        <li
          v-for="module in modulesForGroup(section.group)"
          :key="module.key"
          class="flex items-center justify-between gap-4 px-4 py-3"
        >
          <div class="min-w-0">
            <p class="font-medium">
              {{ moduleLabel(module.group, module.menuKey) }}
            </p>
            <p class="text-xs text-gray-500">
              {{ module.key }}
            </p>
          </div>
          <USwitch
            :model-value="hasModuleAction(permissions, module.key, 'view')"
            :aria-label="moduleLabel(module.group, module.menuKey)"
            @update:model-value="togglePage(module.key, $event)"
          />
        </li>
      </ul>
    </div>
  </div>
</template>
