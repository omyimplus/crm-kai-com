<script setup lang="ts">
import {
  MODULE_STATUS_MODULE_KEYS,
  type ModuleStatusModuleKey
} from '~/config/masterModuleStatus'
import {
  appTableRoleTabActiveClass,
  appTableRoleTabBaseClass,
  appTableRoleTabInactiveClass
} from '~/config/appFormUi'
import {
  isModuleStatusModuleKey,
  moduleStatusModuleLabel
} from '~/utils/masterModuleStatus'

definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const { ensureProfile } = useProfile()
const { list } = useModuleStatuses()

await ensureProfile()

const navLoading = ref(true)
const countsByModule = ref<Record<string, number>>({})

async function refreshModuleCounts() {
  try {
    const rows = await list()
    const counts: Record<string, number> = {}
    for (const key of MODULE_STATUS_MODULE_KEYS) {
      counts[key] = 0
    }
    for (const row of rows) {
      counts[row.module_key] = (counts[row.module_key] ?? 0) + 1
    }
    countsByModule.value = counts
  } catch (e) {
    console.error(e)
  }
}

try {
  await refreshModuleCounts()
} finally {
  navLoading.value = false
}

const activeModuleKey = computed<ModuleStatusModuleKey>(() => {
  const queryModule = typeof route.query.module === 'string' ? route.query.module : null
  if (queryModule && isModuleStatusModuleKey(queryModule)) {
    return queryModule
  }
  return MODULE_STATUS_MODULE_KEYS[0]
})

watch(
  () => route.query.module,
  (value) => {
    if (typeof value === 'string' && isModuleStatusModuleKey(value)) return
    router.replace({ path: '/app/module-status', query: { module: activeModuleKey.value } })
  },
  { immediate: true }
)

function selectModule(moduleKey: ModuleStatusModuleKey) {
  if (moduleKey === activeModuleKey.value) return
  router.replace({ path: '/app/module-status', query: { module: moduleKey } })
}

function moduleNavClass(moduleKey: ModuleStatusModuleKey) {
  return [
    appTableRoleTabBaseClass,
    'w-full shrink-0 text-left lg:w-full',
    activeModuleKey.value === moduleKey ? appTableRoleTabActiveClass : appTableRoleTabInactiveClass
  ]
}

async function onModuleListChanged() {
  await refreshModuleCounts()
}
</script>

<template>
  <div>
    <div class="mb-6">
      <h1 class="text-2xl font-bold font-heading">
        {{ t('masterData.moduleStatuses.hubTitle') }}
      </h1>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        {{ t('masterData.moduleStatuses.hubSubtitle') }}
      </p>
    </div>

    <div class="flex flex-col gap-6 lg:grid lg:grid-cols-[15rem_minmax(0,1fr)] lg:items-start">
      <aside class="min-w-0">
        <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-500">
          {{ t('masterData.moduleStatuses.moduleNavTitle') }}
        </p>
        <UCard
          v-if="navLoading"
          class="rounded-2xl"
        >
          <p class="text-sm text-gray-500">
            {{ t('common.loading') }}
          </p>
        </UCard>
        <nav
          v-else
          class="flex gap-2 overflow-x-auto pb-1 lg:flex-col lg:gap-1 lg:overflow-visible lg:pb-0"
          :aria-label="t('masterData.moduleStatuses.moduleNavTitle')"
        >
          <button
            v-for="moduleKey in MODULE_STATUS_MODULE_KEYS"
            :key="moduleKey"
            type="button"
            :class="moduleNavClass(moduleKey)"
            @click="selectModule(moduleKey)"
          >
            <span class="flex items-center justify-between gap-2">
              <span>{{ moduleStatusModuleLabel(moduleKey, t) }}</span>
              <span
                v-if="(countsByModule[moduleKey] ?? 0) > 0"
                class="shrink-0 text-xs font-normal opacity-80"
              >
                {{ countsByModule[moduleKey] }}
              </span>
            </span>
          </button>
        </nav>
      </aside>

      <div class="min-w-0">
        <MasterDataModuleStatusModuleList
          :key="activeModuleKey"
          :module-key="activeModuleKey"
          embedded
          @changed="onModuleListChanged"
        />
      </div>
    </div>
  </div>
</template>
