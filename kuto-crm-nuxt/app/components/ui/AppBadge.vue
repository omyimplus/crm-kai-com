<script setup lang="ts">
type Tone = 'emerald' | 'amber' | 'red' | 'blue'

const props = withDefaults(
  defineProps<{
    tone?: Tone
  }>(),
  { tone: 'emerald' },
)

const toneClass: Record<Tone, string> = {
  emerald: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  amber: 'bg-amber-50 text-amber-700 ring-amber-200',
  red: 'bg-red-50 text-red-700 ring-red-200',
  blue: 'bg-blue-50 text-blue-700 ring-blue-200',
}
</script>

<template>
  <span
    :class="[
      'whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-semibold ring-1',
      toneClass[props.tone],
    ]"
  >
    <slot />
  </span>
</template>
