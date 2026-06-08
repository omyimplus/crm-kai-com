<script setup lang="ts">
import type { SetupMenuKey } from '~/config/setupMenu'
import { setupMenuItems } from '~/config/setupMenu'

const props = defineProps<{
  menuKey: SetupMenuKey
}>()

const { t, tm } = useI18n()

const item = computed(() => setupMenuItems.find(i => i.key === props.menuKey)!)
const title = computed(() => t(`setup.${props.menuKey}.title`))
const description = computed(() => t(`setup.${props.menuKey}.description`))
const features = computed(() => {
  const raw = tm(`setup.${props.menuKey}.features`) as string[] | string
  return Array.isArray(raw) ? raw : []
})
</script>

<template>
  <div class="mx-auto max-w-2xl">
    <UCard class="overflow-hidden">
      <div class="flex flex-col items-center px-6 py-10 text-center sm:px-10 sm:py-12">
        <div
          class="mb-5 flex h-16 w-16 items-center justify-center rounded-2xl bg-green-500/10 text-green-600 dark:text-green-400"
        >
          <UIcon
            :name="item.icon"
            class="h-8 w-8"
          />
        </div>

        <UBadge
          color="warning"
          variant="subtle"
          class="mb-4"
        >
          {{ t('setup.comingSoon') }}
        </UBadge>

        <h1 class="font-heading text-2xl font-semibold">
          {{ title }}
        </h1>
        <p class="mt-3 text-sm leading-relaxed text-gray-500 dark:text-gray-400">
          {{ description }}
        </p>
      </div>

      <div
        v-if="features.length"
        class="border-t border-gray-200 bg-gray-50/80 px-6 py-6 dark:border-gray-800 dark:bg-gray-900/50 sm:px-10"
      >
        <p class="mb-3 text-xs font-medium uppercase tracking-wide text-gray-500">
          {{ t('setup.plannedFeatures') }}
        </p>
        <ul class="space-y-2 text-left text-sm text-gray-600 dark:text-gray-300">
          <li
            v-for="(feature, index) in features"
            :key="index"
            class="flex items-start gap-2"
          >
            <UIcon
              name="i-lucide-circle-dot"
              class="mt-0.5 h-4 w-4 shrink-0 text-green-500"
            />
            <span>{{ feature }}</span>
          </li>
        </ul>
      </div>
    </UCard>
  </div>
</template>
