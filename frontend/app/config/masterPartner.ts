export const PARTNER_STATUSES = ['active', 'inactive'] as const
export type PartnerStatus = (typeof PARTNER_STATUSES)[number]

export const PARTNER_TYPES = [
  'distributor',
  'reseller',
  'agent',
  'vendor',
  'strategic',
  'other'
] as const
export type PartnerType = (typeof PARTNER_TYPES)[number]

export const PARTNER_TIERS = [
  'platinum',
  'gold',
  'silver',
  'bronze',
  'standard'
] as const
export type PartnerTier = (typeof PARTNER_TIERS)[number]

export const masterPartnerSectionThemes = {
  partnerInfo: {
    icon: 'i-lucide-handshake',
    iconClass: 'bg-violet-100 text-violet-700 dark:bg-violet-950/60 dark:text-violet-300'
  },
  contactDetails: {
    icon: 'i-lucide-contact',
    iconClass: 'bg-sky-100 text-sky-700 dark:bg-sky-950/60 dark:text-sky-300'
  }
} as const
