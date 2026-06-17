export const CONTACT_ROLES = [
  'decision_maker',
  'influencer',
  'user',
  'gatekeeper',
  'other'
] as const
export type ContactRole = (typeof CONTACT_ROLES)[number]

export const masterContactSectionThemes = {
  contactInfo: {
    icon: 'i-lucide-user-round',
    iconClass: 'bg-violet-100 text-violet-700 dark:bg-violet-950/60 dark:text-violet-300'
  },
  workDetails: {
    icon: 'i-lucide-briefcase',
    iconClass: 'bg-teal-100 text-teal-700 dark:bg-teal-950/60 dark:text-teal-300'
  }
} as const
