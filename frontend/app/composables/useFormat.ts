export function useFormat() {
  const { locale } = useI18n()

  function formatCurrency(amount: number, currency = 'THB') {
    const intlLocale = locale.value === 'th' ? 'th-TH' : 'en-US'
    return new Intl.NumberFormat(intlLocale, { style: 'currency', currency }).format(amount)
  }

  return { formatCurrency }
}
