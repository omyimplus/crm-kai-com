<script setup lang="ts">
import type { OrgRole } from '~/types/crm'
import { countGrantedPermissions } from '~/utils/orgRolePermissions'

const props = defineProps<{
  role: OrgRole
}>()

const emit = defineEmits<{
  edit: [role: OrgRole]
  delete: [role: OrgRole]
}>()

const { t } = useI18n()

const permissionTotal = computed(() => countGrantedPermissions(props.role.permissions))
const canDelete = computed(() => !props.role.is_system && props.role.user_count === 0)

const manageUrl = computed(() => `/app/setup/roles/${props.role.id}`)
</script>

<template>
  <article
    class="group relative flex flex-col overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm transition-shadow duration-200 hover:shadow-md dark:border-gray-800 dark:bg-gray-900"
  >
    <div
      class="absolute inset-x-0 top-0 h-1"
      :class="role.is_active
        ? 'bg-menu-section dark:bg-green-400'
        : 'bg-gray-200 dark:bg-gray-700'"
    />

    <div class="flex flex-1 flex-col p-4 pt-5">
      <div class="mb-3 flex items-start justify-between gap-2">
        <div
          class="flex size-9 shrink-0 items-center justify-center rounded-lg"
          :class="role.is_active
            ? 'bg-primary/10 text-primary'
            : 'bg-gray-100 text-gray-400 dark:bg-gray-800 dark:text-gray-500'"
        >
          <UIcon
            name="i-lucide-shield-check"
            class="size-4"
          />
        </div>

        <div class="flex flex-wrap items-center justify-end gap-1">
          <UBadge
            v-if="role.is_system"
            color="info"
            variant="subtle"
            size="sm"
          >
            {{ t('setup.roles.manage.systemBadge') }}
          </UBadge>
          <UBadge
            :color="role.is_active ? 'success' : 'neutral'"
            variant="subtle"
            size="sm"
          >
            {{ role.is_active ? t('setup.roles.active') : t('setup.roles.inactive') }}
          </UBadge>
        </div>
      </div>

      <div class="min-w-0 flex-1">
        <h3 class="truncate text-base font-semibold font-heading text-gray-900 dark:text-gray-100">
          {{ role.label }}
        </h3>

        <p class="mt-1 inline-flex items-center rounded bg-gray-100 px-1.5 py-0.5 font-mono text-[11px] text-gray-600 dark:bg-gray-800 dark:text-gray-400">
          {{ role.code }}
        </p>

        <p
          class="mt-2 line-clamp-2 text-sm leading-snug"
          :class="role.description
            ? 'text-gray-600 dark:text-gray-400'
            : 'text-gray-400 italic dark:text-gray-500'"
        >
          {{ role.description || t('setup.roles.card.noDescription') }}
        </p>
      </div>

      <div class="mt-3 grid grid-cols-2 gap-2">
        <div class="rounded-lg border border-gray-100 bg-gray-50/80 px-2.5 py-2 dark:border-gray-800 dark:bg-gray-800/50">
          <div class="flex items-center gap-1 text-[11px] text-gray-500">
            <UIcon
              name="i-lucide-key-round"
              class="size-3 shrink-0"
            />
            {{ t('setup.roles.permissions.count') }}
          </div>
          <p class="mt-0.5 text-lg font-bold font-heading tabular-nums text-gray-900 dark:text-gray-100">
            {{ permissionTotal }}
          </p>
        </div>
        <div class="rounded-lg border border-gray-100 bg-gray-50/80 px-2.5 py-2 dark:border-gray-800 dark:bg-gray-800/50">
          <div class="flex items-center gap-1 text-[11px] text-gray-500">
            <UIcon
              name="i-lucide-users-round"
              class="size-3 shrink-0"
            />
            {{ t('setup.roles.userCount') }}
          </div>
          <p class="mt-0.5 text-lg font-bold font-heading tabular-nums text-gray-900 dark:text-gray-100">
            {{ role.user_count }}
          </p>
        </div>
      </div>
    </div>

    <div
      class="grid gap-2 border-t border-gray-100 px-3 py-2.5 dark:border-gray-800"
      :class="canDelete ? 'grid-cols-3' : 'grid-cols-2'"
    >
      <UButton
        size="sm"
        variant="soft"
        color="neutral"
        icon="i-lucide-pencil"
        class="justify-center rounded-lg"
        @click="emit('edit', role)"
      >
        {{ t('setup.roles.card.edit') }}
      </UButton>
      <UButton
        :to="manageUrl"
        size="sm"
        variant="soft"
        color="primary"
        icon="i-lucide-sliders-horizontal"
        class="justify-center rounded-lg"
      >
        {{ t('setup.roles.card.configure') }}
      </UButton>
      <AppIconButton
        v-if="canDelete"
        size="sm"
        icon="i-lucide-trash-2"
        color="error"
        :aria-label="t('setup.roles.delete')"
        @click="emit('delete', role)"
      />
    </div>
  </article>
</template>
