<script setup lang="ts">
import {
  kutoExpandedKeysForPath,
  kutoNavItems,
  type KutoNavItem,
  type KutoNavNode
} from '~/config/kutoMenu'
import { kutoSubNavIcon } from '~/config/kutoNavSubIcons'
import { KUTO_TEAL, kutoSidebarGrandLinkClass, kutoSidebarSubLinkClass, kutoSidebarTopLinkClass, kutoSidebarWidthClass } from '~/config/kutoTheme'

const { t } = useI18n()
const route = useRoute()
const { open: mobileOpen, close } = useKutoMobileNav()

const expandedKeys = ref<Set<string>>(new Set())

function syncExpandedFromRoute() {
  expandedKeys.value = new Set(kutoExpandedKeysForPath(route.path))
}

watch(() => route.path, syncExpandedFromRoute, { immediate: true })

function toggleExpand(key: string) {
  const next = new Set(expandedKeys.value)
  if (next.has(key)) {
    next.delete(key)
  } else {
    next.add(key)
  }
  expandedKeys.value = next
}

function isExpanded(key: string) {
  return expandedKeys.value.has(key)
}

function isActivePath(to: string) {
  if (to === '/app') {
    return route.path === '/app' || route.path === '/app/'
  }
  return route.path === to || route.path.startsWith(`${to}/`)
}

function isTopActive(item: KutoNavItem) {
  if (item.children?.length) {
    return item.children.some(child => isNodeActive(child))
  }
  return isActivePath(item.to)
}

function isNodeActive(node: KutoNavNode): boolean {
  if (isActivePath(node.to)) {
    return true
  }
  return node.children?.some(child => isNodeActive(child)) ?? false
}

function onNavigate() {
  close()
}

function subItemIcon(parentKey: string, node: KutoNavNode, nestedParent?: string) {
  return node.icon ?? kutoSubNavIcon(parentKey, node.key, nestedParent)
}
</script>

<template>
  <div class="contents">
    <div
      v-if="mobileOpen"
      class="fixed inset-0 z-30 bg-black/40 lg:hidden"
      @click="close"
    />

    <aside
      class="fixed inset-y-0 left-0 z-40 flex h-full shrink-0 flex-col overflow-hidden transition-transform duration-300 lg:static lg:z-auto lg:translate-x-0"
      :class="[kutoSidebarWidthClass, mobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0']"
      :style="{ backgroundColor: KUTO_TEAL }"
    >
      <div
        class="border-b px-3 py-2.5"
        style="border-color: rgba(255,255,255,0.22)"
      >
        <div class="inline-flex items-center rounded-xl bg-white px-2.5 py-1.5">
          <img
            src="/images/logo/logo-kai-com-crm.webp"
            alt="KC KuTo CRM"
            class="h-7 w-auto object-contain"
          >
        </div>
      </div>

      <nav class="flex-1 overflow-y-auto py-1.5">
        <div
          v-for="item in kutoNavItems"
          :key="item.key"
          class="px-1"
        >
          <div
            class="flex w-full items-center gap-0.5"
            :class="isTopActive(item) ? 'text-white' : 'text-white/78'"
          >
            <NuxtLink
              v-if="!item.children?.length"
              :to="item.to"
              class="flex min-w-0 flex-1 items-center gap-2 px-2.5 py-2.5 transition-colors hover:text-white"
              :class="[kutoSidebarTopLinkClass, isActivePath(item.to) ? 'rounded-lg' : '']"
              :style="isActivePath(item.to) ? { backgroundColor: 'rgba(0,0,0,0.18)' } : undefined"
              @click="onNavigate"
            >
              <UIcon
                :name="item.icon"
                class="size-[18px] shrink-0"
              />
              <span class="min-w-0 flex-1 truncate text-left">{{ t(item.labelKey) }}</span>
              <span
                v-if="item.badge"
                class="shrink-0 rounded-full px-1.5 py-0.5 text-[11px] font-semibold leading-none text-white"
                style="background-color: rgba(0,0,0,0.25)"
              >
                {{ item.badge }}
              </span>
            </NuxtLink>

            <template v-else>
              <NuxtLink
                :to="item.to"
                class="flex min-w-0 flex-1 items-center gap-2 px-2.5 py-2.5 transition-colors hover:text-white"
                :class="[kutoSidebarTopLinkClass, isTopActive(item) ? 'rounded-lg' : '']"
                :style="isTopActive(item) ? { backgroundColor: 'rgba(0,0,0,0.18)' } : undefined"
                @click="onNavigate"
              >
                <UIcon
                  :name="item.icon"
                  class="size-[18px] shrink-0"
                />
                <span class="min-w-0 flex-1 truncate text-left">{{ t(item.labelKey) }}</span>
                <span
                  v-if="item.badge"
                  class="shrink-0 rounded-full px-1.5 py-0.5 text-[11px] font-semibold leading-none text-white"
                  style="background-color: rgba(0,0,0,0.25)"
                >
                  {{ item.badge }}
                </span>
              </NuxtLink>
              <button
                type="button"
                class="mr-1 flex size-7 shrink-0 items-center justify-center rounded-md text-white/70 transition-colors hover:bg-black/10 hover:text-white"
                :aria-expanded="isExpanded(item.key)"
                :aria-label="t('kuto.sidebar.toggleSubmenu', { label: t(item.labelKey) })"
                @click.stop="toggleExpand(item.key)"
              >
                <UIcon
                  name="i-lucide-chevron-down"
                  class="size-3.5 transition-transform duration-200"
                  :class="isExpanded(item.key) ? 'rotate-180' : ''"
                />
              </button>
            </template>
          </div>

          <div
            v-if="item.children?.length && isExpanded(item.key)"
            class="pb-1"
          >
            <template
              v-for="child in item.children"
              :key="child.key"
            >
              <div v-if="child.children?.length">
                <button
                  type="button"
                  class="flex w-full items-center gap-2 py-2 pl-6 pr-2.5 transition-colors"
                  :class="[kutoSidebarSubLinkClass, isNodeActive(child) ? 'text-white' : 'text-white/72 hover:text-white']"
                  @click="toggleExpand(`${item.key}.${child.key}`)"
                >
                  <UIcon
                    v-if="subItemIcon(item.key, child)"
                    :name="subItemIcon(item.key, child)!"
                    class="size-4 shrink-0 opacity-85"
                  />
                  <span class="min-w-0 flex-1 truncate text-left">{{ t(child.labelKey) }}</span>
                  <UIcon
                    name="i-lucide-chevron-down"
                    class="size-3 shrink-0 transition-transform duration-200"
                    :class="isExpanded(`${item.key}.${child.key}`) ? 'rotate-180' : ''"
                  />
                </button>
                <div v-if="isExpanded(`${item.key}.${child.key}`)">
                  <NuxtLink
                    v-for="grand in child.children"
                    :key="grand.key"
                    :to="grand.to"
                    class="flex items-center gap-2 py-2 pl-9 pr-3 transition-colors"
                    :class="[kutoSidebarGrandLinkClass, isActivePath(grand.to) ? 'text-white' : 'text-white/65 hover:text-white']"
                    :style="isActivePath(grand.to) ? { backgroundColor: 'rgba(0,0,0,0.14)' } : undefined"
                    @click="onNavigate"
                  >
                    <UIcon
                      v-if="subItemIcon(child.key, grand, item.key)"
                      :name="subItemIcon(child.key, grand, item.key)!"
                      class="size-3.5 shrink-0 opacity-80"
                    />
                    <span class="truncate">{{ t(grand.labelKey) }}</span>
                  </NuxtLink>
                </div>
              </div>

              <NuxtLink
                v-else
                :to="child.to"
                class="flex items-center gap-2 py-2 pl-6 pr-3 transition-colors"
                :class="[kutoSidebarSubLinkClass, isActivePath(child.to) ? 'text-white' : 'text-white/72 hover:text-white']"
                :style="isActivePath(child.to) ? { backgroundColor: 'rgba(0,0,0,0.14)' } : undefined"
                @click="onNavigate"
              >
                <UIcon
                  v-if="subItemIcon(item.key, child)"
                  :name="subItemIcon(item.key, child)!"
                  class="size-4 shrink-0 opacity-85"
                />
                <span class="min-w-0 flex-1 truncate">{{ t(child.labelKey) }}</span>
                <span
                  v-if="child.badge"
                  class="shrink-0 rounded-full px-1.5 py-0.5 text-[11px] font-semibold leading-none text-white"
                  style="background-color: rgba(0,0,0,0.22)"
                >
                  {{ child.badge }}
                </span>
              </NuxtLink>
            </template>
          </div>
        </div>
      </nav>

      <div
        class="border-t p-2.5"
        style="border-color: rgba(255,255,255,0.22)"
      >
        <div
          class="flex items-center gap-2 rounded-xl px-2.5 py-2"
          style="background-color: rgba(0,0,0,0.12)"
        >
          <div
            class="flex size-7 shrink-0 items-center justify-center rounded-lg text-[11px] font-bold text-white"
            style="background-color: rgba(255,255,255,0.25)"
          >
            NS
          </div>
          <div class="min-w-0 flex-1">
            <div class="truncate text-xs font-semibold leading-tight text-white">
              {{ t('kuto.sidebar.userName') }}
            </div>
            <div
              class="truncate text-[11px] leading-tight"
              style="color: rgba(255,255,255,0.7)"
            >
              {{ t('kuto.sidebar.userRole') }}
            </div>
          </div>
          <UIcon
            name="i-lucide-settings"
            class="size-3.5 shrink-0 text-white/60"
          />
        </div>
      </div>
    </aside>
  </div>
</template>
