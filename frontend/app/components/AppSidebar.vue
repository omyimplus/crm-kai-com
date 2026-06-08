<script setup lang="ts">
import { appMenuItems } from '~/config/appMenu'
import { masterDataMenuItems } from '~/config/masterDataMenu'
import { setupMenuItems } from '~/config/setupMenu'

const { t } = useI18n()
const route = useRoute()
const { canViewAppMenu, canViewMasterData, canAccessSetup } = usePermissions()

const menuOpen = ref(true)
// เปิด section ที่เกี่ยวข้อง — คนใหม่มักไม่รู้ว่าต้องคลิกขยาย
const masterDataOpen = ref(true)
const setupOpen = ref(route.path.startsWith('/app/setup'))

watch(() => route.path, (path) => {
  if (path.startsWith('/app/master-data')) {
    masterDataOpen.value = true
  }
  if (path.startsWith('/app/setup')) {
    setupOpen.value = true
  }
})

const menuLinks = computed(() =>
  appMenuItems
    .filter(item => canViewAppMenu(item.key))
    .map(item => ({
      key: item.key,
      label: t(`appMenu.${item.key}.nav`),
      to: item.to,
      icon: item.icon
    }))
)

const masterDataLinks = computed(() =>
  masterDataMenuItems
    .filter(item => canViewMasterData(item.key))
    .map(item => ({
      key: item.key,
      label: t(`masterData.${item.key}.nav`),
      to: item.to,
      icon: item.icon,
      ready: item.ready
    }))
)

const setupLinks = computed(() =>
  setupMenuItems.map(item => ({
    key: item.key,
    label: t(`setup.${item.key}.nav`),
    to: item.to,
    icon: item.icon,
    ready: item.ready
  }))
)

const showMasterData = computed(() => masterDataLinks.value.length > 0)
const showSetup = computed(() => canAccessSetup.value)

const comingSoonBadge = computed(() => t('common.comingSoonBadge'))

function isMenuActive(path: string) {
  if (path === '/app') {
    return route.path === '/app'
  }
  return route.path.startsWith(path)
}

function isMasterDataActive(path: string) {
  if (path === '/app/master-data/roles') {
    return route.path.startsWith('/app/master-data/roles')
  }
  return route.path === path || route.path.startsWith(`${path}/`)
}

const isMenuSectionActive = computed(() =>
  appMenuItems.some(item => canViewAppMenu(item.key) && isMenuActive(item.to))
)
const isMasterDataSectionActive = computed(() => route.path.startsWith('/app/master-data'))
const isSetupSectionActive = computed(() => route.path.startsWith('/app/setup'))
</script>

<template>
  <aside class="flex w-72 shrink-0 flex-col border-r border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900">
    <div class="border-b border-gray-200 px-5 py-5 dark:border-gray-800">
      <NuxtLink
        to="/app"
        class="block rounded-lg transition-opacity hover:opacity-90"
        :aria-label="t('common.appName')"
      >
        <AppLogo
          variant="full"
          size="md"
        />
      </NuxtLink>
    </div>

    <nav class="flex flex-1 flex-col overflow-y-auto px-3 py-5">
      <div v-if="menuLinks.length">
        <AppSidebarSectionLabel
          :label="t('appMenu.section')"
          icon="i-lucide-menu"
          :active="isMenuSectionActive"
          collapsible
          :open="menuOpen"
          :has-content-below="menuOpen"
          @toggle="menuOpen = !menuOpen"
        />

        <div
          v-show="menuOpen"
          class="space-y-1.5"
        >
          <AppSidebarNavItem
            v-for="link in menuLinks"
            :key="link.key"
            :to="link.to"
            :icon="link.icon"
            :label="link.label"
            :active="isMenuActive(link.to)"
            :badge="link.key === 'dashboard' ? undefined : comingSoonBadge"
          />
        </div>
      </div>

      <div
        v-if="showMasterData || showSetup"
        class="mt-5 space-y-2 border-t border-gray-200 pt-5 dark:border-gray-700"
      >
        <div v-if="showMasterData">
          <AppSidebarSectionLabel
            :label="t('masterData.section')"
            icon="i-lucide-database"
            :active="isMasterDataSectionActive"
            collapsible
            :open="masterDataOpen"
            :has-content-below="masterDataOpen"
            @toggle="masterDataOpen = !masterDataOpen"
          />

          <div
            v-show="masterDataOpen"
            class="space-y-1.5"
          >
            <AppSidebarNavItem
              v-for="link in masterDataLinks"
              :key="link.key"
              :to="link.to"
              :icon="link.icon"
              :label="link.label"
              :active="isMasterDataActive(link.to)"
              :badge="link.ready ? undefined : comingSoonBadge"
            />
          </div>
        </div>

        <div v-if="showSetup">
          <AppSidebarSectionLabel
            :label="t('setup.section')"
            icon="i-lucide-sliders-horizontal"
            :active="isSetupSectionActive"
            collapsible
            :open="setupOpen"
            :has-content-below="setupOpen"
            @toggle="setupOpen = !setupOpen"
          />

          <div
            v-show="setupOpen"
            class="space-y-1.5"
          >
            <AppSidebarNavItem
              v-for="link in setupLinks"
              :key="link.key"
              :to="link.to"
              :icon="link.icon"
              :label="link.label"
              :active="isMenuActive(link.to)"
              :badge="link.ready ? undefined : comingSoonBadge"
            />
          </div>
        </div>
      </div>
    </nav>

    <AppSidebarVersion />
  </aside>
</template>
