<script setup lang="ts">
import type { DropdownMenuItem } from '@nuxt/ui'
import {
  appHeaderControlClass,
  appHeaderIconBtnClass,
  appHeaderInnerClass,
  appHeaderQuickCreateBtnClass,
  appHeaderSearchClass,
  appHeaderShellClass
} from '~/config/appHeaderUi'
import { appHeaderQuickCreateItems } from '~/config/appHeaderQuickCreate'

const { t } = useI18n()
const route = useRoute()
const { toggle: toggleMobileNav } = useMobileNav()
const { canManage, list } = useSystemUsers()

const searchQuery = ref('')
const quickCreateOpen = ref(false)

const quickCreateItems = computed<DropdownMenuItem[][]>(() => [
  appHeaderQuickCreateItems.map((item) => {
    if (item.ready && item.to) {
      return {
        label: t(item.labelKey),
        icon: 'i-lucide-plus',
        to: item.to,
        onSelect: () => { quickCreateOpen.value = false }
      }
    }
    return {
      label: t(item.labelKey),
      icon: 'i-lucide-clock',
      disabled: true,
      badge: { label: t('common.comingSoonBadge'), color: 'warning' as const, variant: 'subtle' as const }
    }
  })
])

const pendingApprovalCount = ref(0)

async function loadPendingApprovalCount() {
  if (!canManage.value) {
    pendingApprovalCount.value = 0
    return
  }
  try {
    const users = await list()
    pendingApprovalCount.value = users.filter(user => !user.is_active).length
  } catch {
    pendingApprovalCount.value = 0
  }
}

onMounted(() => {
  void loadPendingApprovalCount()
})

watch(() => route.path, () => {
  if (route.path.startsWith('/app/setup/user-approvals')) {
    void loadPendingApprovalCount()
  }
})
</script>

<template>
  <header :class="appHeaderShellClass">
    <div :class="appHeaderInnerClass">
      <button
        type="button"
        :class="[appHeaderIconBtnClass, 'lg:hidden']"
        :aria-label="t('appHeader.openMenu')"
        @click="toggleMobileNav"
      >
        <UIcon
          name="i-lucide-menu"
          class="size-5"
        />
      </button>

      <div class="relative min-w-0 flex-1">
        <UIcon
          name="i-lucide-search"
          class="pointer-events-none absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-shell-muted"
        />
        <input
          v-model="searchQuery"
          type="search"
          :class="appHeaderSearchClass"
          :placeholder="t('appHeader.search')"
          :aria-label="t('appHeader.search')"
        >
      </div>

      <UDropdownMenu
        v-model:open="quickCreateOpen"
        :items="quickCreateItems"
        :content="{ align: 'end', class: 'w-64' }"
        :ui="{ content: 'rounded-2xl p-2' }"
      >
        <button
          type="button"
          :class="[appHeaderQuickCreateBtnClass, 'hidden md:inline-flex']"
        >
          <UIcon
            name="i-lucide-plus"
            class="mr-1.5 size-4 shrink-0 sm:mr-2"
          />
          {{ t('appHeader.quickCreate.label') }}
        </button>
      </UDropdownMenu>

      <NuxtLink
        v-if="canManage"
        to="/app/setup/user-approvals"
        :class="[
          appHeaderControlClass,
          'hidden items-center px-3 py-2 text-sm font-bold text-shell-fg transition hover:bg-shell-input xl:inline-flex'
        ]"
      >
        {{ t('appHeader.approvalTasks') }}
        <span
          v-if="pendingApprovalCount > 0"
          class="ml-1.5 rounded-full bg-amber-100 px-2 py-0.5 text-xs font-bold text-amber-700 dark:bg-amber-950/60 dark:text-amber-300"
        >
          {{ pendingApprovalCount }}
        </span>
      </NuxtLink>

      <LocaleSwitcher />

      <ThemeToggle />

      <button
        type="button"
        :class="[appHeaderIconBtnClass, 'hidden sm:inline-flex']"
        :title="t('appHeader.notifications')"
        :aria-label="t('appHeader.notifications')"
        disabled
      >
        <UIcon
          name="i-lucide-bell"
          class="size-5"
        />
        <span
          class="absolute right-2 top-2 size-2 rounded-full bg-red-500"
          aria-hidden="true"
        />
      </button>

      <UserMenu />
    </div>
  </header>
</template>
