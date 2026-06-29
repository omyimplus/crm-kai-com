<script setup lang="ts">
import type { DropdownMenuItem } from '@nuxt/ui'
import { kutoHeaderQuickCreateItems } from '~/config/kutoHeaderQuickCreate'
import { kutoControlClass, kutoInputClass } from '~/config/kutoTheme'

const { t, locale, setLocale } = useI18n()
const { toggle: toggleMobileNav } = useKutoMobileNav()
const { breadcrumb } = useKutoBreadcrumb()

const searchQuery = ref('')
const quickCreateOpen = ref(false)

const breadcrumbModule = computed(() => breadcrumb.value.module)
const breadcrumbPage = computed(() => breadcrumb.value.page)

const quickCreateItems = computed<DropdownMenuItem[][]>(() => [
  kutoHeaderQuickCreateItems.map((item) => {
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
      badge: {
        label: t('kuto.header.comingSoon'),
        color: 'warning' as const,
        variant: 'subtle' as const
      }
    }
  })
])
</script>

<template>
  <header class="relative z-20 flex h-14 shrink-0 items-center gap-2 border-b border-shell-border bg-white px-4 shadow-sm">
    <button
      type="button"
      class="rounded-lg p-1.5 hover:bg-gray-100 lg:hidden"
      :aria-label="t('kuto.header.openMenu')"
      @click="toggleMobileNav"
    >
      <UIcon
        name="i-lucide-menu"
        class="size-5"
      />
    </button>

    <div class="hidden items-center gap-1 text-sm text-shell-muted sm:flex">
      <template v-if="breadcrumbModule">
        <span>{{ breadcrumbModule }}</span>
        <UIcon
          name="i-lucide-chevron-right"
          class="size-3.5 text-gray-300"
        />
      </template>
      <span class="font-semibold text-teal-600">{{ breadcrumbPage }}</span>
    </div>

    <div class="flex-1" />

    <div class="relative hidden w-48 md:block">
      <UIcon
        name="i-lucide-search"
        class="pointer-events-none absolute left-3 top-1/2 size-3.5 -translate-y-1/2 text-shell-muted"
      />
      <input
        v-model="searchQuery"
        type="search"
        :class="[kutoInputClass, 'py-1.5 pl-9 pr-3 text-xs']"
        :placeholder="t('kuto.header.search')"
      >
    </div>

    <UDropdownMenu
      v-model:open="quickCreateOpen"
      :items="quickCreateItems"
      :content="{ align: 'end', side: 'bottom', sideOffset: 6, class: 'z-50 w-56' }"
      :ui="{ content: 'rounded-2xl p-1.5' }"
    >
      <button
        type="button"
        class="inline-flex items-center gap-1 rounded-lg bg-teal-500 px-3 py-1.5 text-xs font-semibold text-white hover:bg-teal-600"
      >
        <UIcon
          name="i-lucide-plus"
          class="size-3.5"
        />
        {{ t('kuto.header.create') }}
      </button>
    </UDropdownMenu>

    <button
      type="button"
      :class="[kutoControlClass, 'hidden items-center gap-1.5 px-2 py-1.5 text-xs sm:inline-flex']"
    >
      <UIcon
        name="i-lucide-circle-check"
        class="size-3.5"
      />
      {{ t('kuto.header.approvals') }}
      <span class="rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">5</span>
    </button>

    <div class="flex overflow-hidden rounded-lg border border-shell-border text-xs font-bold">
      <button
        type="button"
        class="px-3 py-1.5 transition-colors"
        :class="locale === 'th' ? 'bg-teal-500 text-white' : 'text-gray-500'"
        @click="setLocale('th')"
      >
        TH
      </button>
      <button
        type="button"
        class="px-3 py-1.5 transition-colors"
        :class="locale === 'en' ? 'bg-teal-500 text-white' : 'text-gray-500'"
        @click="setLocale('en')"
      >
        EN
      </button>
    </div>

    <button
      type="button"
      class="relative rounded-lg p-1.5 hover:bg-gray-100"
      :aria-label="t('kuto.header.notifications')"
    >
      <UIcon
        name="i-lucide-bell"
        class="size-[18px] text-gray-500"
      />
      <span class="absolute right-1 top-1 size-2 rounded-full bg-red-500" />
    </button>

    <div class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-teal-500 text-xs font-bold text-white">
      NS
    </div>
  </header>
</template>
