import type { MaybeRefOrGetter } from 'vue'
import { DEFAULT_PAGE_SIZE } from '~/config/pagination'

export function usePagination<T>(
  items: MaybeRefOrGetter<T[]>,
  pageSize = DEFAULT_PAGE_SIZE
) {
  const page = ref(1)

  const totalItems = computed(() => toValue(items).length)
  const totalPages = computed(() => Math.max(1, Math.ceil(totalItems.value / pageSize)))

  const pagedItems = computed(() => {
    const all = toValue(items)
    const start = (page.value - 1) * pageSize
    return all.slice(start, start + pageSize)
  })

  const rangeStart = computed(() =>
    totalItems.value === 0 ? 0 : (page.value - 1) * pageSize + 1
  )

  const rangeEnd = computed(() =>
    Math.min(page.value * pageSize, totalItems.value)
  )

  const showPagination = computed(() => totalItems.value > pageSize)

  function resetPage() {
    page.value = 1
  }

  function goPrev() {
    if (page.value > 1) page.value -= 1
  }

  function goNext() {
    if (page.value < totalPages.value) page.value += 1
  }

  watch(() => toValue(items), () => {
    resetPage()
  })

  watch(totalPages, (tp) => {
    if (page.value > tp) page.value = tp
  })

  return {
    page,
    pagedItems,
    totalItems,
    totalPages,
    pageSize,
    rangeStart,
    rangeEnd,
    showPagination,
    resetPage,
    goPrev,
    goNext
  }
}
