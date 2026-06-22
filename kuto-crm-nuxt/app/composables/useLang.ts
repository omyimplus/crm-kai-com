import type { Lang } from '~/utils/i18n'

export const useLang = () => {
  const lang = useState<Lang>('lang', () => 'th')

  const setLang = (value: Lang) => {
    lang.value = value
  }

  return { lang, setLang }
}
