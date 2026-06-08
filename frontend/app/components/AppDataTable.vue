<script setup lang="ts">
import { appTableTextClass } from '~/config/appFormUi'

withDefaults(defineProps<{
  /** Extra classes on `<table>` — e.g. `min-w-[640px]` */
  tableClass?: string
  /** ใช้ภายใน wrapper ที่มี border ร่วมกับ toolbar/tabs ด้านบน */
  embedded?: boolean
}>(), {
  tableClass: '',
  embedded: false
})
</script>

<template>
  <div
    class="overflow-x-auto"
    :class="embedded ? '' : 'rounded-lg border border-gray-200 dark:border-gray-800'"
  >
    <table
      class="app-data-table w-full"
      :class="[appTableTextClass, tableClass]"
    >
      <thead class="text-white">
        <slot name="head" />
      </thead>
      <tbody>
        <slot />
      </tbody>
    </table>
  </div>
</template>
