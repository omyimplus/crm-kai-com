<script setup lang="ts">
import {
  JOB_CODE_MODULE_KEYS,
  type JobCodeModuleKey
} from '~/config/masterJobCode'
import {
  appTableRoleTabActiveClass,
  appTableRoleTabBaseClass,
  appTableRoleTabInactiveClass
} from '~/config/appFormUi'
import {
  isJobCodeModuleKey,
  jobCodeModuleLabel
} from '~/utils/masterJobCode'

definePageMeta({ middleware: 'auth', layout: 'app' })

const route = useRoute()
const router = useRouter()
const { t } = useI18n()
const { ensureProfile } = useProfile()
const { list } = useJobCodes()

await ensureProfile()

const navLoading = ref(true)
const configuredModules = ref<Set<string>>(new Set())

async function refreshConfiguredModules() {
  try {
    const rows = await list()
    configuredModules.value = new Set(rows.map(row => row.module_key))
  } catch (e) {
    console.error(e)
  }
}

try {
  await refreshConfiguredModules()
} finally {
  navLoading.value = false
}

const activeModuleKey = computed<JobCodeModuleKey>(() => {
  const queryModule = typeof route.query.module === 'string' ? route.query.module : null
  if (queryModule && isJobCodeModuleKey(queryModule)) {
    return queryModule
  }
  return JOB_CODE_MODULE_KEYS[0]
})

watch(
  () => route.query.module,
  (value) => {
    if (typeof value === 'string' && isJobCodeModuleKey(value)) return
    router.replace({ path: '/app/job-code', query: { module: activeModuleKey.value } })
  },
  { immediate: true }
)

function selectModule(moduleKey: JobCodeModuleKey) {
  if (moduleKey === activeModuleKey.value) return
  router.replace({ path: '/app/job-code', query: { module: moduleKey } })
}

function moduleNavClass(moduleKey: JobCodeModuleKey) {
  return [
    appTableRoleTabBaseClass,
    'w-full shrink-0 text-left lg:w-full',
    activeModuleKey.value === moduleKey ? appTableRoleTabActiveClass : appTableRoleTabInactiveClass
  ]
}

async function onModuleSaved(moduleKey: JobCodeModuleKey) {
  configuredModules.value = new Set([...configuredModules.value, moduleKey])
}
</script>

<template>
  <div>
    <div class="mb-6">
      <h1 class="text-2xl font-bold font-heading">
        {{ t('masterData.jobCode.hubTitle') }}
      </h1>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        {{ t('masterData.jobCode.hubSubtitle') }}
      </p>
    </div>

    <div class="flex flex-col gap-6 lg:grid lg:grid-cols-[15rem_minmax(0,1fr)] lg:items-start">
      <aside class="min-w-0">
        <p class="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-500">
          {{ t('masterData.jobCode.moduleNavTitle') }}
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
          :aria-label="t('masterData.jobCode.moduleNavTitle')"
        >
          <button
            v-for="moduleKey in JOB_CODE_MODULE_KEYS"
            :key="moduleKey"
            type="button"
            :class="moduleNavClass(moduleKey)"
            @click="selectModule(moduleKey)"
          >
            <span class="flex items-center justify-between gap-2">
              <span>{{ jobCodeModuleLabel(moduleKey, t) }}</span>
              <span
                v-if="configuredModules.has(moduleKey)"
                class="size-2 shrink-0 rounded-full bg-emerald-500"
                :title="t('masterData.jobCode.hubConfigured')"
              />
            </span>
          </button>
        </nav>
      </aside>

      <div class="min-w-0">
        <MasterDataJobCodePage
          :key="activeModuleKey"
          :module-key="activeModuleKey"
          embedded
          @saved="onModuleSaved"
        />
      </div>
    </div>
  </div>
</template>
