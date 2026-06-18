<script setup lang="ts">
import { appFormFieldClass, appInputUi } from '~/config/appFormUi'

const from = defineModel<string>('from', { default: '' })
const to = defineModel<string>('to', { default: '' })

const props = withDefaults(defineProps<{
  groupAriaLabel?: string
  fromAriaLabel?: string
  toAriaLabel?: string
}>(), {
  groupAriaLabel: undefined,
  fromAriaLabel: undefined,
  toAriaLabel: undefined
})

const { t } = useI18n()

const resolvedGroupLabel = computed(() =>
  props.groupAriaLabel ?? t('tasks.filters.dateRange')
)
const resolvedFromLabel = computed(() =>
  props.fromAriaLabel ?? t('tasks.filters.dateFrom')
)
const resolvedToLabel = computed(() =>
  props.toAriaLabel ?? t('tasks.filters.dateTo')
)

watch(from, (value) => {
  if (value && to.value && value > to.value) to.value = value
})

watch(to, (value) => {
  if (value && from.value && value < from.value) from.value = value
})
</script>

<template>
  <div
    class="flex min-w-0 flex-1 items-center gap-2 rounded-lg border border-gray-200 bg-white px-2 py-1 dark:border-gray-700 dark:bg-gray-900/50 lg:max-w-md lg:flex-none"
    role="group"
    :aria-label="resolvedGroupLabel"
  >
    <UIcon
      name="i-lucide-calendar-range"
      class="size-4 shrink-0 text-gray-400 dark:text-gray-500"
      aria-hidden="true"
    />

    <UInput
      v-model="from"
      type="date"
      :aria-label="resolvedFromLabel"
      :class="[appFormFieldClass, 'min-w-0 flex-1 border-0 bg-transparent shadow-none ring-0']"
      :ui="appInputUi"
    />

    <span
      class="shrink-0 text-xs text-gray-400 dark:text-gray-500"
      aria-hidden="true"
    >
      –
    </span>

    <UInput
      v-model="to"
      type="date"
      :aria-label="resolvedToLabel"
      :class="[appFormFieldClass, 'min-w-0 flex-1 border-0 bg-transparent shadow-none ring-0']"
      :ui="appInputUi"
    />
  </div>
</template>
