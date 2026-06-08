export const ORG_AUTH_PROVIDER_IDS = [
  'microsoft365',
  'google',
  'azureAd',
  'usernamePassword'
] as const

export type OrgAuthProviderId = (typeof ORG_AUTH_PROVIDER_IDS)[number]

export interface OrgOAuthProviderSettings {
  enabled: boolean
  clientId: string
  tenantId: string
  allowedDomains: string
  hasClientSecret: boolean
}

export interface OrgUsernamePasswordProviderSettings {
  enabled: boolean
}

export type OrgAuthProviders = {
  microsoft365: OrgOAuthProviderSettings
  google: OrgOAuthProviderSettings
  azureAd: OrgOAuthProviderSettings
  usernamePassword: OrgUsernamePasswordProviderSettings
}

export interface OrgOAuthProviderForm {
  clientId: string
  clientSecret: string
  tenantId: string
  allowedDomains: string
}

export const ORG_AUTH_PROVIDER_ICONS: Record<OrgAuthProviderId, string> = {
  microsoft365: 'i-lucide-app-window',
  google: 'i-lucide-chrome',
  azureAd: 'i-lucide-cloud',
  usernamePassword: 'i-lucide-key-round'
}

export const DEFAULT_ORG_AUTH_PROVIDERS: OrgAuthProviders = {
  microsoft365: {
    enabled: false,
    clientId: '',
    tenantId: 'common',
    allowedDomains: '',
    hasClientSecret: false
  },
  google: {
    enabled: false,
    clientId: '',
    tenantId: '',
    allowedDomains: '',
    hasClientSecret: false
  },
  azureAd: {
    enabled: false,
    clientId: '',
    tenantId: '',
    allowedDomains: '',
    hasClientSecret: false
  },
  usernamePassword: {
    enabled: true
  }
}

export function isOAuthProvider(id: OrgAuthProviderId): boolean {
  return id !== 'usernamePassword'
}
