<script setup lang="ts">
defineProps<{
  label: string
  icon: string
  active?: boolean
  collapsible?: boolean
  open?: boolean
  /** เว้นระยะใต้หัวข้อเมื่อมีรายการเมนูแสดงอยู่ */
  hasContentBelow?: boolean
}>()

defineEmits<{
  toggle: []
}>()
</script>

<template>
  <component
    :is="collapsible ? 'button' : 'div'"
    :type="collapsible ? 'button' : undefined"
    :class="[
      'flex w-full items-center gap-2.5 rounded-lg px-3 py-2.5 text-left text-[13px] font-semibold uppercase tracking-wider text-white transition-colors',
      'bg-menu-section hover:bg-menu-section-hover dark:bg-primary dark:hover:bg-green-600',
      hasContentBelow ? 'mb-3' : 'mb-0',
      active && collapsible && 'ring-2 ring-menu-section/30 ring-offset-1 ring-offset-white dark:ring-green-700/30 dark:ring-offset-gray-900'
    ]"
    @click="collapsible ? $emit('toggle') : undefined"
  >
    <UIcon
      :name="icon"
      class="size-4 shrink-0 text-white [&_svg]:stroke-[2.25]"
    />
    <span class="flex-1 text-left">{{ label }}</span>
    <UIcon
      v-if="collapsible"
      :name="open ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
      class="size-4 shrink-0 text-white/95 [&_svg]:stroke-[2.5]"
    />
  </component>
</template>
