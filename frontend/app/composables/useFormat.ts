export function useFormat() {
  const { locale } = useI18n()

  function formatCurrency(amount: number, currency = 'THB') {
    const intlLocale = locale.value === 'th' ? 'th-TH' : 'en-US'
    return new Intl.NumberFormat(intlLocale, { style: 'currency', currency }).format(amount)
  }

  function formatDateTime(value: string | null | undefined) {
    if (!value) return '—'
    const intlLocale = locale.value === 'th' ? 'th-TH' : 'en-US'
    return new Intl.DateTimeFormat(intlLocale, {
      dateStyle: 'medium',
      timeStyle: 'short'
    }).format(new Date(value))
  }

  return { formatCurrency, formatDateTime }
}
