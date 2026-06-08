<script setup lang="ts">
import { DEFAULT_PAGE_SIZE } from '~/config/pagination'
import { appTableTextClass } from '~/config/appFormUi'

const page = defineModel<number>('page', { required: true })

const props = withDefaults(defineProps<{
  totalItems: number
  pageSize?: number
  totalPages: number
  rangeStart: number
  rangeEnd: number
  /** ชิดใน wrapper ตาราง (border-top ร่วมกับ AppDataTable embedded) */
  embedded?: boolean
}>(), {
  pageSize: DEFAULT_PAGE_SIZE,
  embedded: false
})

const { t } = useI18n()

const canGoPrev = computed(() => page.value > 1)
const canGoNext = computed(() => page.value < props.totalPages)
const showControls = computed(() => props.totalItems > props.pageSize)

function goPrev() {
  if (canGoPrev.value) page.value -= 1
}

function goNext() {
  if (canGoNext.value) page.value += 1
}
</script>

<template>
  <div
    v-if="totalItems > 0"
    class="flex flex-wrap items-center justify-between gap-3 px-3 py-2.5"
    :class="[
      appTableTextClass,
      embedded
        ? 'border-t border-gray-200 bg-gray-50/90 dark:border-gray-800 dark:bg-gray-900/60'
        : 'rounded-lg border border-gray-200 bg-gray-50/90 dark:border-gray-800 dark:bg-gray-900/60'
    ]"
  >
    <p class="text-gray-600 dark:text-gray-400">
      {{ t('common.pagination.range', { start: rangeStart, end: rangeEnd, total: totalItems }) }}
    </p>

    <div
      v-if="showControls"
      class="flex items-center gap-2"
    >
      <UButton
        type="button"
        size="sm"
        variant="outline"
        color="neutral"
        class="rounded-lg"
        icon="i-lucide-chevron-left"
        :disabled="!canGoPrev"
        :aria-label="t('common.pagination.previous')"
        @click="goPrev"
      >
        {{ t('common.pagination.previous') }}
      </UButton>

      <span class="min-w-[5rem] text-center font-medium text-gray-700 dark:text-gray-300">
        {{ t('common.pagination.page', { page, total: totalPages }) }}
      </span>

      <UButton
        type="button"
        size="sm"
        variant="outline"
        color="neutral"
        class="rounded-lg"
        trailing-icon="i-lucide-chevron-right"
        :disabled="!canGoNext"
        :aria-label="t('common.pagination.next')"
        @click="goNext"
      >
        {{ t('common.pagination.next') }}
      </UButton>
    </div>
  </div>
</template>
