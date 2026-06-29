/** Client-side pagination — รอ wire API ภายหลัง */
export function useKutoPagination<T>(source: Ref<T[]>, pageSize = 10) {
  const page = ref(1)

  const totalItems = computed(() => source.value.length)
  const totalPages = computed(() =>
    Math.max(1, Math.ceil(totalItems.value / pageSize))
  )

  const rangeStart = computed(() =>
    totalItems.value === 0 ? 0 : (page.value - 1) * pageSize + 1
  )

  const rangeEnd = computed(() =>
    Math.min(page.value * pageSize, totalItems.value)
  )

  const pagedItems = computed(() => {
    const start = (page.value - 1) * pageSize
    return source.value.slice(start, start + pageSize)
  })

  watch(source, () => {
    page.value = 1
  })

  watch(totalPages, (pages) => {
    if (page.value > pages) page.value = pages
  })

  return {
    page,
    pagedItems,
    totalItems,
    totalPages,
    rangeStart,
    rangeEnd,
    pageSize
  }
}
