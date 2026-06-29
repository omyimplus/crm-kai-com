<script setup lang="ts">
import { appSidebarNavTextClass } from '~/config/appFormUi'

defineProps<{
  to: string
  icon: string
  label: string
  active?: boolean
  badge?: string
}>()
</script>

<template>
  <NuxtLink
    :to="to"
    class="group flex items-center gap-3 rounded-2xl px-2.5 py-2 font-sans transition-colors"
    :class="[
      appSidebarNavTextClass,
      active
        ? 'bg-sidebar-accent font-semibold text-sidebar-accent-fg dark:bg-primary/15 dark:text-blue-300'
        : 'text-slate-600 hover:bg-slate-50 dark:text-gray-200 dark:hover:bg-gray-800/80'
    ]"
  >
    <span
      class="flex size-8 shrink-0 items-center justify-center rounded-xl transition-colors [&_svg]:stroke-[2.25]"
      :class="[
        active
          ? 'bg-primary/10 text-primary dark:bg-primary dark:text-white'
          : 'bg-slate-100 text-slate-500 group-hover:bg-slate-200 group-hover:text-slate-700 dark:bg-gray-800 dark:text-gray-300 dark:group-hover:bg-gray-700'
      ]"
    >
      <UIcon
        :name="icon"
        class="size-[1.125rem]"
      />
    </span>
    <span class="min-w-0 flex-1 truncate">{{ label }}</span>
    <UBadge
      v-if="badge"
      color="neutral"
      variant="subtle"
      size="xs"
      class="shrink-0 font-sans font-normal opacity-70"
    >
      {{ badge }}
    </UBadge>
  </NuxtLink>
</template>
