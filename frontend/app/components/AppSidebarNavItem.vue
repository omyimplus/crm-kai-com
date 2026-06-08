<script setup lang="ts">
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
    class="group flex items-center gap-3 rounded-lg px-2.5 py-2 text-[0.9375rem] font-medium transition-colors"
    :class="[
      active
        ? 'bg-menu-section/10 font-semibold text-menu-section dark:bg-primary/15 dark:text-green-400'
        : 'text-gray-700 hover:bg-gray-100 dark:text-gray-200 dark:hover:bg-gray-800/80'
    ]"
  >
    <span
      class="flex size-8 shrink-0 items-center justify-center rounded-md transition-colors [&_svg]:stroke-[2.25]"
      :class="[
        active
          ? 'bg-menu-section text-white shadow-sm dark:bg-primary dark:text-white'
          : 'bg-gray-100 text-gray-600 group-hover:bg-gray-200 group-hover:text-gray-700 dark:bg-gray-800 dark:text-gray-300 dark:group-hover:bg-gray-700'
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
      class="shrink-0 opacity-70"
    >
      {{ badge }}
    </UBadge>
  </NuxtLink>
</template>
