<script setup lang="ts" generic="T extends string">
const props = defineProps<{
  modelValue: T[]
  labels: Record<T, string>
  disabled?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: T[]]
}>()

const { t } = useI18n()

function move(index: number, direction: -1 | 1) {
  const nextIndex = index + direction
  if (nextIndex < 0 || nextIndex >= props.modelValue.length) return
  const next = [...props.modelValue]
  const temp = next[index]!
  next[index] = next[nextIndex]!
  next[nextIndex] = temp
  emit('update:modelValue', next)
}
</script>

<template>
  <ul class="space-y-2">
    <li
      v-for="(item, index) in modelValue"
      :key="item"
      class="flex items-center gap-2 rounded-xl border border-gray-200 bg-white px-3 py-2 dark:border-gray-800 dark:bg-gray-900"
    >
      <span class="min-w-0 flex-1 text-sm font-medium">
        {{ labels[item as T] ?? item }}
      </span>
      <div class="flex shrink-0 gap-1">
        <UButton
          type="button"
          size="xs"
          variant="ghost"
          color="neutral"
          icon="i-lucide-arrow-up"
          :disabled="disabled || index === 0"
          :aria-label="t('masterData.jobCode.orderMoveUp')"
          @click="move(index, -1)"
        />
        <UButton
          type="button"
          size="xs"
          variant="ghost"
          color="neutral"
          icon="i-lucide-arrow-down"
          :disabled="disabled || index === modelValue.length - 1"
          :aria-label="t('masterData.jobCode.orderMoveDown')"
          @click="move(index, 1)"
        />
      </div>
    </li>
  </ul>
</template>
