import type { OrgCompanyProfile, OrgCompanyProfileInput } from '~/types/crm'

export function defaultOrgCompanyProfileInput(
  isFirst = false
): OrgCompanyProfileInput {
  return {
    profileName: '',
    nameEn: '',
    nameTh: '',
    taxId: '',
    taxBranch: '',
    phone: '',
    email: '',
    website: '',
    addressEn: '',
    addressTh: '',
    isDefault: isFirst
  }
}

function readString(value: unknown): string {
  return typeof value === 'string' ? value : ''
}

export function mapOrgCompanyProfile(row: Record<string, unknown>): OrgCompanyProfile {
  return {
    id: String(row.id),
    profileName: readString(row.profile_name),
    nameEn: readString(row.name_en),
    nameTh: readString(row.name_th),
    taxId: readString(row.tax_id),
    taxBranch: readString(row.tax_branch),
    phone: readString(row.phone),
    email: readString(row.email),
    website: readString(row.website),
    logoUrl: readString(row.logo_url) || null,
    addressEn: readString(row.address_en),
    addressTh: readString(row.address_th),
    isDefault: Boolean(row.is_default),
    createdAt: readString(row.created_at),
    updatedAt: readString(row.updated_at)
  }
}

export function localizedOrgCompanyAddress(
  profile: Pick<OrgCompanyProfile, 'addressEn' | 'addressTh'>,
  locale: string
): string {
  const isTh = locale === 'th' || locale.startsWith('th-')
  const primary = isTh ? profile.addressTh : profile.addressEn
  const fallback = isTh ? profile.addressEn : profile.addressTh
  return (primary || fallback || '').trim()
}

export function localizedOrgCompanyName(
  profile: Pick<OrgCompanyProfile, 'nameEn' | 'nameTh'>,
  locale: string
): { primary: string, secondary: string | null } {
  const isTh = locale === 'th' || locale.startsWith('th-')
  const primary = (isTh ? profile.nameTh || profile.nameEn : profile.nameEn || profile.nameTh).trim()
  const secondaryRaw = isTh ? profile.nameEn : profile.nameTh
  const secondary = secondaryRaw.trim() && secondaryRaw.trim() !== primary
    ? secondaryRaw.trim()
    : null
  return { primary, secondary }
}

export function trimOrgCompanyProfileInput(
  input: OrgCompanyProfileInput
): OrgCompanyProfileInput {
  return {
    ...input,
    profileName: input.profileName.trim(),
    nameEn: input.nameEn.trim(),
    nameTh: input.nameTh.trim(),
    taxId: input.taxId.trim(),
    taxBranch: input.taxBranch.trim(),
    phone: input.phone.trim(),
    email: input.email.trim(),
    website: input.website.trim(),
    addressEn: input.addressEn.trim(),
    addressTh: input.addressTh.trim()
  }
}
