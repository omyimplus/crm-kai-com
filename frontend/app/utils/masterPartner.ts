import type { Partner } from '~/types/crm'
import {
  PARTNER_STATUSES,
  PARTNER_TIERS,
  PARTNER_TYPES,
  type PartnerStatus,
  type PartnerTier,
  type PartnerType
} from '~/config/masterPartner'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'
import { normalizeWebsiteUrl } from '~/utils/websiteUrl'

export interface MasterPartnerFormInput {
  partner_code: string
  name: string
  partner_type: PartnerType
  tier: PartnerTier
  partner_since: string
  status: PartnerStatus
  contact_person: string
  email: string
  phone: string
  website: string
  commission_rate: number
}

export function defaultMasterPartnerFormInput(): MasterPartnerFormInput {
  return {
    partner_code: '',
    name: '',
    partner_type: 'distributor',
    tier: 'silver',
    partner_since: '',
    status: 'active',
    contact_person: '',
    email: '',
    phone: '',
    website: '',
    commission_rate: 0
  }
}

function parseStatus(value: string | null | undefined): PartnerStatus {
  if (value && (PARTNER_STATUSES as readonly string[]).includes(value)) {
    return value as PartnerStatus
  }
  return 'active'
}

function parseType(value: string | null | undefined): PartnerType {
  if (value && (PARTNER_TYPES as readonly string[]).includes(value)) {
    return value as PartnerType
  }
  return 'distributor'
}

function parseTier(value: string | null | undefined): PartnerTier {
  if (value && (PARTNER_TIERS as readonly string[]).includes(value)) {
    return value as PartnerTier
  }
  return 'silver'
}

function formatPartnerSince(value: string | null | undefined): string {
  if (!value) return ''
  return value.slice(0, 10)
}

export function partnerToFormInput(partner: Partner): MasterPartnerFormInput {
  return {
    partner_code: partner.partner_code,
    name: partner.name,
    partner_type: parseType(partner.partner_type),
    tier: parseTier(partner.tier),
    partner_since: formatPartnerSince(partner.partner_since),
    status: parseStatus(partner.status),
    contact_person: partner.contact_person,
    email: partner.email,
    phone: partner.phone,
    website: partner.website ?? '',
    commission_rate: Number(partner.commission_rate ?? 0)
  }
}

export function formToPartnerPayload(form: MasterPartnerFormInput) {
  return {
    partner_code: form.partner_code.trim(),
    name: form.name.trim(),
    partner_type: form.partner_type,
    tier: form.tier,
    partner_since: form.partner_since.trim() || null,
    status: form.status,
    contact_person: form.contact_person.trim(),
    email: form.email.trim(),
    phone: form.phone.trim(),
    website: normalizeWebsiteUrl(form.website) || null,
    commission_rate: form.commission_rate ?? 0
  }
}

export type MasterPartnerValidationKey =
  | 'codeRequired'
  | 'companyNameRequired'
  | 'contactPersonRequired'
  | 'emailRequired'
  | 'phoneRequired'
  | 'commissionRateInvalid'

export function validateMasterPartnerForm(
  form: MasterPartnerFormInput
): MasterPartnerValidationKey | null {
  if (!form.partner_code.trim()) return 'codeRequired'
  if (!form.name.trim()) return 'companyNameRequired'
  if (!form.contact_person.trim()) return 'contactPersonRequired'
  if (!form.email.trim()) return 'emailRequired'
  if (!form.phone.trim()) return 'phoneRequired'
  if (form.commission_rate < 0 || form.commission_rate > 100) return 'commissionRateInvalid'
  return null
}

export function partnerDisplayLabel(partner: Pick<Partner, 'name'>) {
  return partner.name
}

export function partnerSaveErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.saveFailed'))
  if (message.includes('Duplicate partner code')) {
    return t('masterData.partner.validation.duplicateCode')
  }
  if (message.includes('Invalid partner type')) {
    return t('masterData.partner.validation.typeInvalid')
  }
  if (message.includes('Invalid partner tier')) {
    return t('masterData.partner.validation.tierInvalid')
  }
  if (message.includes('Invalid partner commission rate')) {
    return t('masterData.partner.validation.commissionRateInvalid')
  }
  return message || t('common.saveFailed')
}

export function partnerDeleteErrorMessage(error: unknown, t: (key: string) => string): string {
  const message = getSupabaseErrorMessage(error, t('common.deleteFailed'))
  return message || t('common.deleteFailed')
}
