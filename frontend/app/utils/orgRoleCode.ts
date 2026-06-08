import { ORG_SYSTEM_ROLE_CODES } from '~/config/orgRoleSystemCodes'

/** Matches `org_roles_code_format` in DB: ^[a-z][a-z0-9_]{1,48}$ */
export const ORG_ROLE_CODE_MIN_LENGTH = 2
export const ORG_ROLE_CODE_MAX_LENGTH = 49
export const ORG_ROLE_CODE_PATTERN = /^[a-z][a-z0-9_]{1,48}$/

export type OrgRoleCodeErrorId =
  | 'required'
  | 'noSpaces'
  | 'noUppercase'
  | 'noHyphen'
  | 'invalidChars'
  | 'mustStartLetter'
  | 'tooShort'
  | 'tooLong'
  | 'reserved'

export interface OrgRoleCodeValidation {
  ok: boolean
  errorId?: OrgRoleCodeErrorId
}

export function validateOrgRoleCode(
  raw: string,
  options?: { reservedCodes?: readonly string[] }
): OrgRoleCodeValidation {
  if (!raw.trim()) {
    return { ok: false, errorId: 'required' }
  }

  if (/\s/.test(raw)) {
    return { ok: false, errorId: 'noSpaces' }
  }

  if (/[A-Z]/.test(raw)) {
    return { ok: false, errorId: 'noUppercase' }
  }

  if (/-/.test(raw)) {
    return { ok: false, errorId: 'noHyphen' }
  }

  const code = raw.trim().toLowerCase()

  if (!/^[a-z]/.test(code)) {
    return { ok: false, errorId: 'mustStartLetter' }
  }

  if (!/^[a-z0-9_]+$/.test(code)) {
    return { ok: false, errorId: 'invalidChars' }
  }

  if (code.length < ORG_ROLE_CODE_MIN_LENGTH) {
    return { ok: false, errorId: 'tooShort' }
  }

  if (code.length > ORG_ROLE_CODE_MAX_LENGTH) {
    return { ok: false, errorId: 'tooLong' }
  }

  if (!ORG_ROLE_CODE_PATTERN.test(code)) {
    return { ok: false, errorId: 'invalidChars' }
  }

  const reserved = options?.reservedCodes ?? ORG_SYSTEM_ROLE_CODES
  if ((reserved as readonly string[]).includes(code)) {
    return { ok: false, errorId: 'reserved' }
  }

  return { ok: true }
}

export function normalizeOrgRoleCode(raw: string): string {
  return raw.trim().toLowerCase()
}
