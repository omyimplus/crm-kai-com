<script setup lang="ts">
defineProps<{
  title: string
  icon: string
  iconClass: string
}>()
</script>

<template>
  <UCard class="rounded-2xl">
    <template #header>
      <div class="flex items-center gap-3">
        <div
          class="flex size-9 shrink-0 items-center justify-center rounded-full"
          :class="iconClass"
        >
          <UIcon
            :name="icon"
            class="size-4"
          />
        </div>
        <h2 class="font-semibold font-heading">
          {{ title }}
        </h2>
      </div>
    </template>
    <slot />
  </UCard>
</template>
