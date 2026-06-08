/** State สำหรับฟอร์มที่มีเลือก/ลบรูปก่อนบันทึก */

export function useImageUploadState(initialUrl: string | null = null) {
  const savedUrl = ref<string | null>(initialUrl)
  const file = ref<File | null>(null)
  const objectUrl = ref<string | null>(null)
  const removed = ref(false)

  const previewUrl = computed(() => {
    if (objectUrl.value) return objectUrl.value
    if (removed.value) return null
    return savedUrl.value
  })

  const changed = computed(() => removed.value || file.value !== null)

  function revokeObjectUrl() {
    if (objectUrl.value) {
      URL.revokeObjectURL(objectUrl.value)
      objectUrl.value = null
    }
  }

  function select(selected: File) {
    revokeObjectUrl()
    file.value = selected
    objectUrl.value = URL.createObjectURL(selected)
    removed.value = false
  }

  function remove() {
    revokeObjectUrl()
    file.value = null
    removed.value = true
  }

  function reset(url: string | null = null) {
    revokeObjectUrl()
    file.value = null
    removed.value = false
    savedUrl.value = url
  }

  onBeforeUnmount(() => {
    revokeObjectUrl()
  })

  return {
    savedUrl,
    file,
    removed,
    previewUrl,
    changed,
    select,
    remove,
    reset
  }
}
