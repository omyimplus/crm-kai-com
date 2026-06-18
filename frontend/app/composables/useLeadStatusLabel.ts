import type { ModuleStatus } from '~/types/crm'

export function useLeadStatusLabel() {
  const { t, te } = useI18n()

  function leadStatusLabel(
    statusCode: string | null | undefined,
    customName?: string | null
  ): string {
    const code = statusCode?.trim().toUpperCase()
    const i18nKey = code ? `leads.statusCodes.${code}` : ''

    if (code && te(i18nKey)) {
      return t(i18nKey)
    }

    const name = customName?.trim()
    if (name) return name
    if (code) return code
    return t('leads.emptyCell')
  }

  function moduleStatusLabel(row: Pick<ModuleStatus, 'status_code' | 'name'>) {
    return leadStatusLabel(row.status_code, row.name)
  }

  return { leadStatusLabel, moduleStatusLabel }
}
