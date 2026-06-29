<script setup lang="ts">
const props = defineProps<{
  label: string
  value: string
  accent: string
  icon: string
  iconBg: string
  subLabel?: string
  trend?: string
  trendDown?: boolean
  interactive?: boolean
  active?: boolean
  class?: string
}>()

const emit = defineEmits<{
  click: []
}>()

function onClick() {
  if (props.interactive) emit('click')
}
</script>

<template>
  <component
    :is="interactive ? 'button' : 'div'"
    :type="interactive ? 'button' : undefined"
    class="relative w-full overflow-hidden rounded-xl bg-white text-left shadow-[0_1px_3px_rgba(15,23,42,0.08)] transition-all"
    :class="[interactive && active ? 'ring-2 ring-teal-500/25' : '', props.class]"
    :style="{ borderLeft: `4px solid ${accent}` }"
    @click="onClick"
  >
    <div class="flex items-start justify-between gap-2 py-3 pl-3.5 pr-3.5">
      <p class="text-xs font-medium text-gray-500">
        {{ label }}
      </p>
      <div
        class="flex size-8 shrink-0 items-center justify-center rounded-full"
        :class="iconBg"
      >
        <UIcon
          :name="icon"
          class="size-4"
        />
      </div>
    </div>
    <div class="px-3.5 pb-3.5">
      <div class="flex items-end gap-2">
        <p
          class="text-2xl font-bold leading-none"
          :style="{ color: accent }"
        >
          {{ value }}
        </p>
        <span
          v-if="trend"
          class="text-[11px] font-semibold"
          :class="trendDown ? 'text-red-500' : 'text-emerald-600'"
        >
          {{ trend }}
        </span>
      </div>
      <p
        v-if="subLabel"
        class="mt-1.5 text-[11px] text-gray-400"
      >
        {{ subLabel }}
      </p>
    </div>
  </component>
</template>
