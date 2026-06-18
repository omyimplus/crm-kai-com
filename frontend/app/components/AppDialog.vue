<script setup lang="ts">
type DialogSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl'

const open = defineModel<boolean>('open', { required: true })

const props = withDefaults(defineProps<{
  title: string
  description?: string
  size?: DialogSize
}>(), {
  size: 'md'
})

/** Full literal classes — Tailwind ต้องเห็น max-w-* แบบ static ไม่ใช่ interpolate */
const contentBySize: Record<DialogSize, string> = {
  sm: 'crm-dialog w-[calc(100vw-2rem)] !max-w-md rounded-2xl shadow-xl ring-1 ring-gray-200 dark:ring-gray-800',
  md: 'crm-dialog w-[calc(100vw-2rem)] !max-w-lg rounded-2xl shadow-xl ring-1 ring-gray-200 dark:ring-gray-800',
  lg: 'crm-dialog w-[calc(100vw-2rem)] !max-w-xl rounded-2xl shadow-xl ring-1 ring-gray-200 dark:ring-gray-800',
  xl: 'crm-dialog w-[calc(100vw-2rem)] !max-w-2xl rounded-2xl shadow-xl ring-1 ring-gray-200 dark:ring-gray-800',
  '2xl': 'crm-dialog w-[calc(100vw-2rem)] !max-w-4xl rounded-2xl shadow-xl ring-1 ring-gray-200 dark:ring-gray-800'
}

const modalUi = computed(() => ({
  overlay: 'bg-black/60',
  content: contentBySize[props.size],
  header: 'px-6 pt-6 pb-4 border-b border-gray-200 dark:border-gray-800',
  body: 'px-6 py-5',
  footer: 'px-6 py-4 border-t border-gray-200 dark:border-gray-800 bg-gray-50/80 dark:bg-gray-900/50 rounded-b-2xl',
  title: 'text-lg font-semibold font-heading text-gray-900 dark:text-gray-100',
  description: 'mt-1 text-sm leading-relaxed text-gray-500 dark:text-gray-400'
}))
</script>

<template>
  <UModal
    v-model:open="open"
    :title="title"
    :description="description"
    :ui="modalUi"
  >
    <template #body>
      <slot v-if="$slots.body" name="body" />
      <slot v-else />
    </template>
    <template
      v-if="$slots.footer"
      #footer
    >
      <slot name="footer" />
    </template>
  </UModal>
</template>
