export const MIN_PASSWORD_LENGTH = 6

const UPPER = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
const LOWER = 'abcdefghjkmnpqrstuvwxyz'
const DIGITS = '23456789'
const SYMBOLS = '!@#$%&*'

function pickChar(chars: string): string {
  const index = crypto.getRandomValues(new Uint32Array(1))[0]! % chars.length
  return chars.charAt(index)
}

function shuffle<T>(items: T[]): T[] {
  const arr = [...items]
  for (let i = arr.length - 1; i > 0; i--) {
    const j = crypto.getRandomValues(new Uint32Array(1))[0]! % (i + 1)
    const tmp = arr[i]!
    arr[i] = arr[j]!
    arr[j] = tmp
  }
  return arr
}

export function generateStrongPassword(length = 14): string {
  const size = Math.max(length, 8)
  const all = UPPER + LOWER + DIGITS + SYMBOLS
  const required = [
    pickChar(UPPER),
    pickChar(LOWER),
    pickChar(DIGITS),
    pickChar(SYMBOLS)
  ]
  const rest = Array.from({ length: size - required.length }, () => pickChar(all))
  return shuffle([...required, ...rest]).join('')
}

export type PasswordStrengthLevel = 'empty' | 'weak' | 'fair' | 'good' | 'strong'

export interface PasswordStrengthRule {
  id: 'length' | 'upper' | 'lower' | 'digit' | 'symbol'
  passed: boolean
}

export interface PasswordStrengthResult {
  rules: PasswordStrengthRule[]
  passedCount: number
  totalCount: number
  level: PasswordStrengthLevel
  /** 0–4 segments for strength bar */
  segments: number
}

export function analyzePasswordStrength(password: string): PasswordStrengthResult {
  const rules: PasswordStrengthRule[] = [
    { id: 'length', passed: password.length >= MIN_PASSWORD_LENGTH },
    { id: 'upper', passed: /[A-Z]/.test(password) },
    { id: 'lower', passed: /[a-z]/.test(password) },
    { id: 'digit', passed: /\d/.test(password) },
    { id: 'symbol', passed: /[^A-Za-z0-9]/.test(password) }
  ]

  const passedCount = rules.filter(r => r.passed).length
  const totalCount = rules.length

  if (!password) {
    return { rules, passedCount: 0, totalCount, level: 'empty', segments: 0 }
  }

  let level: PasswordStrengthLevel = 'weak'
  if (passedCount >= 5) level = 'strong'
  else if (passedCount >= 4) level = 'good'
  else if (passedCount >= 2) level = 'fair'

  const segments = passedCount >= 5 ? 4 : passedCount >= 4 ? 3 : passedCount >= 3 ? 2 : passedCount >= 1 ? 1 : 0

  return { rules, passedCount, totalCount, level, segments }
}

export function passwordsMatch(password: string, confirm: string): boolean {
  return password.length > 0 && password === confirm
}


export function validatePasswordPair(
  password: string,
  confirm: string,
  options: { requireConfirm?: boolean, minLength?: number } = {}
): PasswordPairError | null {
  const minLength = options.minLength ?? MIN_PASSWORD_LENGTH
  const requireConfirm = options.requireConfirm ?? true
  const trimmed = password.trim()

  if (!trimmed) {
    return 'required'
  }
  if (trimmed.length < minLength) {
    return 'tooShort'
  }
  if (requireConfirm && trimmed !== confirm) {
    return 'mismatch'
  }
  return null
}

/** แก้ไข user — เว้นว่างได้; ถ้ากรอกต้องครบและตรงกัน */
export function validateOptionalPasswordPair(
  password: string,
  confirm: string,
  minLength = MIN_PASSWORD_LENGTH
): PasswordPairError | null {
  const trimmed = password.trim()
  const confirmTrimmed = confirm.trim()

  if (!trimmed && !confirmTrimmed) {
    return null
  }

  return validatePasswordPair(trimmed, confirmTrimmed, {
    requireConfirm: true,
    minLength
  })
}
