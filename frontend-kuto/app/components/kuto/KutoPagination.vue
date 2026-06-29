<script setup lang="ts">
const page = defineModel<number>('page', { required: true })

const props = withDefaults(defineProps<{
  totalItems: number
  pageSize?: number
  totalPages: number
  rangeStart: number
  rangeEnd: number
  /** ชิดใต้ตารางใน card เดียวกัน */
  embedded?: boolean
}>(), {
  pageSize: 10,
  embedded: true
})

const { t } = useI18n()

const canGoPrev = computed(() => page.value > 1)
const canGoNext = computed(() => page.value < props.totalPages)

const pageNumbers = computed(() => {
  if (props.totalPages > 10) return []
  return Array.from({ length: props.totalPages }, (_, i) => i + 1)
})

const showPageNumbers = computed(() => props.totalPages > 1 && props.totalPages <= 10)

function goPrev() {
  if (canGoPrev.value) page.value -= 1
}

function goNext() {
  if (canGoNext.value) page.value += 1
}

function goToPage(n: number) {
  if (n >= 1 && n <= props.totalPages) page.value = n
}
</script>

<template>
  <div
    v-if="totalItems > 0"
    class="flex w-full flex-col items-center gap-2 px-4 py-3 text-sm"
    :class="embedded
      ? 'border-t border-shell-border bg-gray-50/80'
      : 'rounded-lg border border-shell-border bg-gray-50/80'"
  >
    <p class="text-center text-shell-muted">
      {{ t('kuto.common.pagination.range', { start: rangeStart, end: rangeEnd, total: totalItems }) }}
    </p>

    <div class="flex flex-wrap items-center justify-center gap-1.5">
      <button
        type="button"
        class="inline-flex items-center gap-1 rounded-lg border border-shell-border bg-white px-2.5 py-1.5 text-xs font-semibold text-shell-fg transition-colors hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-40"
        :disabled="!canGoPrev"
        :aria-label="t('kuto.common.pagination.previous')"
        @click="goPrev"
      >
        <UIcon
          name="i-lucide-chevron-left"
          class="size-3.5"
        />
        <span class="hidden sm:inline">{{ t('kuto.common.pagination.previous') }}</span>
      </button>

      <template v-if="showPageNumbers">
        <button
          v-for="n in pageNumbers"
          :key="n"
          type="button"
          class="inline-flex min-w-8 items-center justify-center rounded-lg border px-2.5 py-1.5 text-xs font-bold transition-colors"
          :class="page === n
            ? 'border-teal-500 bg-teal-500 text-white shadow-sm'
            : 'border-shell-border bg-white text-shell-fg hover:border-teal-300 hover:bg-teal-50'"
          :aria-label="t('kuto.common.pagination.page', { page: n, total: totalPages })"
          :aria-current="page === n ? 'page' : undefined"
          @click="goToPage(n)"
        >
          {{ n }}
        </button>
      </template>

      <span
        v-if="!showPageNumbers && totalPages > 1"
        class="min-w-[4.5rem] px-1 text-center text-xs font-semibold text-shell-fg"
      >
        {{ t('kuto.common.pagination.page', { page, total: totalPages }) }}
      </span>

      <button
        type="button"
        class="inline-flex items-center gap-1 rounded-lg border border-shell-border bg-white px-2.5 py-1.5 text-xs font-semibold text-shell-fg transition-colors hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-40"
        :disabled="!canGoNext"
        :aria-label="t('kuto.common.pagination.next')"
        @click="goNext"
      >
        <span class="hidden sm:inline">{{ t('kuto.common.pagination.next') }}</span>
        <UIcon
          name="i-lucide-chevron-right"
          class="size-3.5"
        />
      </button>
    </div>
  </div>
</template>
