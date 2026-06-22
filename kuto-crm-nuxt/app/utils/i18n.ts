export type Lang = 'th' | 'en'

export type Label = { th: string; en: string }

export const tx = (label: Label, lang: Lang) => label[lang]
