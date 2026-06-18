/** แท็บ Active / Deleted — owner + admin เท่านั้น (ใช้ทุก master-data list ปัจจุบันและอนาคต) */
export type ArchiveTab = 'active' | 'deleted'

export function useArchiveTabs() {
  const { canViewDeletedRecords, ensurePermissions } = usePermissions()

  const archiveTab = ref<ArchiveTab>('active')

  const isActiveArchive = computed(
    () => !canViewDeletedRecords.value || archiveTab.value === 'active'
  )

  watch(canViewDeletedRecords, (allowed) => {
    if (!allowed) {
      archiveTab.value = 'active'
    }
  })

  async function ensureArchiveAccess() {
    await ensurePermissions()
    if (!canViewDeletedRecords.value) {
      archiveTab.value = 'active'
    }
  }

  return {
    archiveTab,
    canViewDeletedRecords,
    isActiveArchive,
    ensureArchiveAccess
  }
}
