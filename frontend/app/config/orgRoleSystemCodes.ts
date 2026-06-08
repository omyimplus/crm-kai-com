/** System-seeded org role codes — reserved at create time; seeded by DB on org setup */
export const ORG_SYSTEM_ROLE_CODES = ['manager', 'sales', 'cs', 'engineer'] as const
export type OrgSystemRoleCode = typeof ORG_SYSTEM_ROLE_CODES[number]

export function isSystemOrgRoleCode(code: string): code is OrgSystemRoleCode {
  return (ORG_SYSTEM_ROLE_CODES as readonly string[]).includes(code)
}
