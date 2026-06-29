<script setup lang="ts">
import type { DropdownMenuItem } from '@nuxt/ui'
import { appHeaderControlClass } from '~/config/appHeaderUi'

const { t } = useI18n()
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const { profile } = useProfile()
const { endSession } = useLoginSession()

const displayName = computed(() => profile.value?.full_name || t('common.user'))
const userEmail = computed(() => user.value?.email ?? '')

const { resolveAvatarUrl } = useUserAvatar()

const roleLabel = computed(() => {
  const role = profile.value?.role
  if (!role) {
    return ''
  }
  return t(`profile.roles.${role}`)
})

const isAdmin = computed(() =>
  profile.value?.role === 'owner' || profile.value?.role === 'admin'
)

const initials = computed(() => {
  const parts = displayName.value.trim().split(/\s+/).filter(Boolean)
  if (!parts.length) {
    return '?'
  }
  if (parts.length === 1) {
    return parts[0]!.slice(0, 2).toUpperCase()
  }
  return `${parts[0]![0] ?? ''}${parts[parts.length - 1]![0] ?? ''}`.toUpperCase()
})

const hasCustomAvatar = computed(() => Boolean(profile.value?.avatar_url?.trim()))

async function logout() {
  await endSession()
  await supabase.auth.signOut()
  await navigateTo('/login')
}

const items = computed<DropdownMenuItem[][]>(() => [
  [
    {
      type: 'label',
      label: displayName.value,
      description: userEmail.value,
      avatar: { src: resolveAvatarUrl(profile.value?.avatar_url), alt: displayName.value }
    }
  ],
  ...(roleLabel.value
    ? [[{
        type: 'label',
        label: t('profile.role'),
        description: isAdmin.value
          ? roleLabel.value
          : `${roleLabel.value} — ${t('profile.notAdminHint')}`,
        icon: 'i-lucide-shield'
      }]]
    : []),
  [
    {
      label: t('auth.logout'),
      icon: 'i-lucide-log-out',
      color: 'error',
      onSelect: logout
    }
  ]
])
</script>

<template>
  <UDropdownMenu
    :items="items"
    :ui="{ content: 'w-64 rounded-2xl' }"
  >
    <button
      type="button"
      :class="[appHeaderControlClass, 'flex max-w-[12rem] items-center gap-2 px-2 py-2 transition hover:bg-shell-input']"
      :aria-label="displayName"
    >
      <div
        v-if="hasCustomAvatar"
        class="size-8 shrink-0 overflow-hidden rounded-xl ring-1 ring-gray-200 dark:ring-gray-700"
      >
        <img
          :src="resolveAvatarUrl(profile?.avatar_url)"
          :alt="displayName"
          class="size-full object-cover"
          decoding="async"
        >
      </div>
      <div
        v-else
        class="grid size-8 shrink-0 place-items-center rounded-xl bg-green-100 text-xs font-bold text-green-700 dark:bg-green-950/50 dark:text-green-300"
      >
        {{ initials }}
      </div>
      <div class="hidden min-w-0 text-left xl:block">
        <p class="truncate text-xs font-bold text-shell-fg">
          {{ displayName }}
        </p>
        <p
          v-if="roleLabel"
          class="truncate text-[10px] text-shell-muted"
        >
          {{ roleLabel }}
        </p>
      </div>
    </button>
  </UDropdownMenu>
</template>
