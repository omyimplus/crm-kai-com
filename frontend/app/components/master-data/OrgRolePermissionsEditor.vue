<script setup lang="ts">
import {
  PERMISSION_ACTIONS,
  permissionModuleGroups,
  permissionModules,
  type PermissionAction
} from '~/config/permissionModules'
import type { OrgRolePermissions } from '~/types/crm'
import { hasModuleAction, setGroupViewAll, setModuleAction } from '~/utils/orgRolePermissions'

const permissions = defineModel<OrgRolePermissions>('permissions', { required: true })

const { t } = useI18n()

const actionColumns = computed(() =>
  PERMISSION_ACTIONS.map(action => ({
    action,
    label: t(`masterData.roles.permissions.actions.${action}`)
  }))
)

function moduleLabel(group: 'app' | 'master', menuKey: string) {
  if (group === 'app') {
    return t(`appMenu.${menuKey}.nav`)
  }
  return t(`masterData.${menuKey}.nav`)
}

function isActionAvailable(moduleKey: string, action: PermissionAction) {
  const module = permissionModules.find(item => item.key === moduleKey)
  return module?.actions.includes(action) ?? false
}

function toggle(moduleKey: string, action: PermissionAction, enabled: boolean) {
  permissions.value = setModuleAction(permissions.value, moduleKey, action, enabled)
}

function modulesForGroup(group: 'app' | 'master') {
  return permissionModules.filter(module => module.group === group)
}
</script>

<template>
  <div class="space-y-6">
    <div
      v-for="section in permissionModuleGroups"
      :key="section.group"
      class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
    >
      <div class="flex flex-wrap items-center justify-between gap-3 border-b border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-800 dark:bg-gray-900">
        <h3 class="text-sm font-semibold font-heading text-menu-section">
          {{ t(section.i18nKey) }}
        </h3>
        <div class="flex gap-2">
          <UButton
            size="xs"
            variant="soft"
            color="neutral"
            @click="permissions = setGroupViewAll(permissions, section.group, true)"
          >
            {{ t('masterData.roles.permissions.enableAllView') }}
          </UButton>
          <UButton
            size="xs"
            variant="ghost"
            color="neutral"
            @click="permissions = setGroupViewAll(permissions, section.group, false)"
          >
            {{ t('masterData.roles.permissions.disableAllView') }}
          </UButton>
        </div>
      </div>

      <div class="overflow-x-auto">
        <table class="w-full min-w-[640px] text-sm">
          <thead>
            <tr class="border-b border-gray-200 dark:border-gray-800">
              <th class="p-3 text-left font-medium">
                {{ t('masterData.roles.permissions.module') }}
              </th>
              <th
                v-for="column in actionColumns"
                :key="column.action"
                class="p-3 text-center font-medium"
              >
                {{ column.label }}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="module in modulesForGroup(section.group)"
              :key="module.key"
              class="border-t border-gray-200 dark:border-gray-800"
            >
              <td class="p-3 font-medium">
                {{ moduleLabel(module.group, module.menuKey) }}
              </td>
              <td
                v-for="column in actionColumns"
                :key="`${module.key}-${column.action}`"
                class="p-3 text-center"
              >
                <input
                  v-if="isActionAvailable(module.key, column.action)"
                  type="checkbox"
                  class="size-4 rounded border-gray-300 text-primary focus:ring-primary"
                  :checked="hasModuleAction(permissions, module.key, column.action)"
                  :aria-label="`${moduleLabel(module.group, module.menuKey)} — ${column.label}`"
                  @change="toggle(
                    module.key,
                    column.action,
                    ($event.target as HTMLInputElement).checked
                  )"
                >
                <span
                  v-else
                  class="text-gray-300"
                >—</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <p class="text-xs text-gray-500">
      {{ t('masterData.roles.permissions.hint') }}
    </p>
  </div>
</template>
