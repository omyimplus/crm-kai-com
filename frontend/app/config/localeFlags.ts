/** ธงภาษา — แทนที่ไฟล์ใน public/images/flags/ แล้วอัปเดต path ตรงนี้ */
export const localeFlagByCode = {
  th: '/images/flags/th.svg',
  en: '/images/flags/en.svg'
} as const

export type LocaleFlagCode = keyof typeof localeFlagByCode
