import type { ModuleStatus } from '~/types/crm'

/** แสดงชื่อสถานะงาน — ใช้ i18n จาก status_code ก่อน แล้วค่อย fallback ชื่อใน DB (custom status) */
export function useTaskStatusLabel() {
  const { t, te } = useI18n()

  function taskStatusLabel(
    statusCode: string | null | undefined,
    customName?: string | null
  ): string {
    const code = statusCode?.trim().toUpperCase()
    const i18nKey = code ? `tasks.statusCodes.${code}` : ''

    if (code && te(i18nKey)) {
      return t(i18nKey)
    }

    const name = customName?.trim()
    if (name) return name
    if (code) return code
    return t('tasks.emptyCell')
  }

  function moduleStatusLabel(row: Pick<ModuleStatus, 'status_code' | 'name'>) {
    return taskStatusLabel(row.status_code, row.name)
  }

  return { taskStatusLabel, moduleStatusLabel }
}
