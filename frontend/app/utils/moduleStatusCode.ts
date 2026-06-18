/** Matches `module_statuses_code_format` in DB: ^[A-Z][A-Z0-9_]{1,48}$ */
export const MODULE_STATUS_CODE_MIN_LENGTH = 2
export const MODULE_STATUS_CODE_MAX_LENGTH = 49
export const MODULE_STATUS_CODE_PATTERN = /^[A-Z][A-Z0-9_]{1,48}$/

export type ModuleStatusCodeErrorId =
  | 'required'
  | 'noSpaces'
  | 'invalidChars'
  | 'mustStartLetter'
  | 'tooShort'
  | 'tooLong'

export interface ModuleStatusCodeValidation {
  ok: boolean
  errorId?: ModuleStatusCodeErrorId
}

/** Live input — uppercase only; user still sees invalid chars until blur validation */
export function normalizeModuleStatusCodeInput(raw: string): string {
  return raw.toUpperCase()
}

/** On save — trim + uppercase */
export function normalizeModuleStatusCode(raw: string): string {
  return raw.trim().toUpperCase()
}

export function validateModuleStatusCode(raw: string): ModuleStatusCodeValidation {
  if (!raw.trim()) {
    return { ok: false, errorId: 'required' }
  }

  if (/\s/.test(raw)) {
    return { ok: false, errorId: 'noSpaces' }
  }

  const code = normalizeModuleStatusCode(raw)

  if (!/^[A-Z]/.test(code)) {
    return { ok: false, errorId: 'mustStartLetter' }
  }

  if (!/^[A-Z0-9_]+$/.test(code)) {
    return { ok: false, errorId: 'invalidChars' }
  }

  if (code.length < MODULE_STATUS_CODE_MIN_LENGTH) {
    return { ok: false, errorId: 'tooShort' }
  }

  if (code.length > MODULE_STATUS_CODE_MAX_LENGTH) {
    return { ok: false, errorId: 'tooLong' }
  }

  if (!MODULE_STATUS_CODE_PATTERN.test(code)) {
    return { ok: false, errorId: 'invalidChars' }
  }

  return { ok: true }
}

export type ModuleStatusCodeValidationKey =
  | 'codeRequired'
  | 'codeNoSpaces'
  | 'codeInvalidChars'
  | 'codeMustStartLetter'
  | 'codeTooShort'
  | 'codeTooLong'

export function moduleStatusCodeValidationKey(
  errorId: ModuleStatusCodeErrorId
): ModuleStatusCodeValidationKey {
  const map: Record<ModuleStatusCodeErrorId, ModuleStatusCodeValidationKey> = {
    required: 'codeRequired',
    noSpaces: 'codeNoSpaces',
    invalidChars: 'codeInvalidChars',
    mustStartLetter: 'codeMustStartLetter',
    tooShort: 'codeTooShort',
    tooLong: 'codeTooLong'
  }
  return map[errorId]
}
