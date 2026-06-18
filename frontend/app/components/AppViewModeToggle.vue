<script setup lang="ts">
import type { AppViewModeOption } from '~/config/appViewMode'

const model = defineModel<string>({ required: true })

const props = withDefaults(defineProps<{
  options: AppViewModeOption[]
  groupAriaLabel?: string
  /** Show text beside icon (default: icon-only like Setup → Roles) */
  showLabels?: boolean
}>(), {
  showLabels: false
})

const { t } = useI18n()

const ariaGroup = computed(() =>
  props.groupAriaLabel ?? t('common.viewMode.groupLabel')
)
</script>

<template>
  <div
    class="inline-flex shrink-0 rounded-lg border border-gray-200 p-0.5 dark:border-gray-700"
    role="group"
    :aria-label="ariaGroup"
  >
    <UButton
      v-for="option in options"
      :key="option.value"
      size="sm"
      :variant="model === option.value ? 'solid' : 'soft'"
      :color="model === option.value ? 'primary' : 'neutral'"
      :icon="option.icon"
      :square="!showLabels"
      class="rounded-md"
      :class="showLabels ? 'px-2.5' : undefined"
      :aria-label="option.label"
      :aria-pressed="model === option.value"
      @click="model = option.value"
    >
      <span v-if="showLabels">{{ option.label }}</span>
    </UButton>
  </div>
</template>
