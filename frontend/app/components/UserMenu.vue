<script setup lang="ts">
import type { DropdownMenuItem } from '@nuxt/ui'

const { t } = useI18n()
const supabase = useSupabaseClient()
const user = useSupabaseUser()
const { profile } = useProfile()

const displayName = computed(() => profile.value?.full_name || t('common.user'))
const userEmail = computed(() => user.value?.email ?? '')

const initials = computed(() => {
  const name = displayName.value.trim()
  if (!name) {
    return '?'
  }
  const parts = name.split(/\s+/).filter(Boolean)
  if (parts.length >= 2) {
    return `${parts[0]![0]}${parts[1]![0]}`.toUpperCase()
  }
  return name.slice(0, 2).toUpperCase()
})

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

async function logout() {
  await supabase.auth.signOut()
  await navigateTo('/login')
}

const items = computed<DropdownMenuItem[][]>(() => [
  [
    {
      type: 'label',
      label: displayName.value,
      description: userEmail.value,
      avatar: profile.value?.avatar_url
        ? { src: profile.value.avatar_url, alt: displayName.value }
        : { text: initials.value, alt: displayName.value }
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
    :ui="{ content: 'w-64' }"
  >
    <UButton
      variant="ghost"
      color="neutral"
      class="gap-1.5 rounded-full py-1 pl-1 pr-2"
      :aria-label="displayName"
    >
      <UAvatar
        :src="profile?.avatar_url ?? undefined"
        :alt="displayName"
        :text="initials"
        size="sm"
        class="ring-2 ring-green-500/20"
      />
      <span class="hidden max-w-[8rem] truncate text-sm font-medium sm:inline">
        {{ displayName }}
      </span>
      <UIcon
        name="i-lucide-chevron-down"
        class="size-4 shrink-0 text-gray-400"
      />
    </UButton>
  </UDropdownMenu>
</template>
