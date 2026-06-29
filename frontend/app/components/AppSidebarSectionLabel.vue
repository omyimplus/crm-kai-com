<script setup lang="ts">
import { appSidebarSectionTextClass } from '~/config/appFormUi'

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
      'flex w-full items-center gap-2.5 rounded-2xl px-3 py-2.5 text-left font-sans transition-colors',
      appSidebarSectionTextClass,
      active
        ? 'bg-sidebar-accent text-sidebar-accent-fg'
        : 'text-slate-600 hover:bg-slate-50 dark:text-gray-300 dark:hover:bg-gray-800/80',
      hasContentBelow ? 'mb-3' : 'mb-0',
      active && collapsible && 'ring-1 ring-shell-border'
    ]"
    @click="collapsible ? $emit('toggle') : undefined"
  >
    <UIcon
      :name="icon"
      class="size-4 shrink-0 [&_svg]:stroke-[2.25]"
      :class="active ? 'text-sidebar-accent-fg' : 'text-slate-500 dark:text-gray-400'"
    />
    <span class="flex-1 text-left normal-case tracking-normal">{{ label }}</span>
    <UIcon
      v-if="collapsible"
      :name="open ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
      class="size-4 shrink-0 [&_svg]:stroke-[2.5]"
      :class="active ? 'text-sidebar-accent-fg' : 'text-slate-500 dark:text-gray-400'"
    />
  </component>
</template>
