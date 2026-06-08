import {
  DEFAULT_ORG_AUTH_PROVIDERS,
  ORG_AUTH_PROVIDER_IDS,
  type OrgAuthProviderId,
  type OrgAuthProviders,
  type OrgOAuthProviderForm,
  type OrgOAuthProviderSettings
} from '~/config/orgAuthProviders'

function readString(value: unknown): string {
  return typeof value === 'string' ? value : ''
}

function mergeOAuthProvider(
  defaults: OrgOAuthProviderSettings,
  stored: Record<string, unknown> | undefined
): OrgOAuthProviderSettings {
  const clientSecret = readString(stored?.clientSecret)
  return {
    enabled: typeof stored?.enabled === 'boolean' ? stored.enabled : defaults.enabled,
    clientId: readString(stored?.clientId) || defaults.clientId,
    tenantId: readString(stored?.tenantId) || defaults.tenantId,
    allowedDomains: readString(stored?.allowedDomains),
    hasClientSecret: Boolean(clientSecret)
  }
}

export function mergeOrgAuthProviders(
  stored: Record<string, unknown> | null | undefined
): OrgAuthProviders {
  const root = (stored && typeof stored === 'object') ? stored : {}

  return {
    microsoft365: mergeOAuthProvider(
      DEFAULT_ORG_AUTH_PROVIDERS.microsoft365,
      root.microsoft365 as Record<string, unknown> | undefined
    ),
    google: mergeOAuthProvider(
      DEFAULT_ORG_AUTH_PROVIDERS.google,
      root.google as Record<string, unknown> | undefined
    ),
    azureAd: mergeOAuthProvider(
      DEFAULT_ORG_AUTH_PROVIDERS.azureAd,
      root.azureAd as Record<string, unknown> | undefined
    ),
    usernamePassword: {
      enabled: typeof (root.usernamePassword as Record<string, unknown> | undefined)?.enabled === 'boolean'
        ? Boolean((root.usernamePassword as Record<string, unknown>).enabled)
        : DEFAULT_ORG_AUTH_PROVIDERS.usernamePassword.enabled
    }
  }
}

export function oauthSettingsToForm(
  settings: OrgOAuthProviderSettings,
  clientSecret = ''
): OrgOAuthProviderForm {
  return {
    clientId: settings.clientId,
    clientSecret,
    tenantId: settings.tenantId,
    allowedDomains: settings.allowedDomains
  }
}

export function trimOAuthForm(form: OrgOAuthProviderForm): OrgOAuthProviderForm {
  return {
    clientId: form.clientId.trim(),
    clientSecret: form.clientSecret,
    tenantId: form.tenantId.trim(),
    allowedDomains: form.allowedDomains.trim()
  }
}

export function buildProviderUpdatePayload(
  providers: OrgAuthProviders,
  providerId: OrgAuthProviderId,
  patch: Record<string, unknown>
) {
  const payload: Record<string, unknown> = {}

  for (const id of ORG_AUTH_PROVIDER_IDS) {
    const current = providers[id]
    if (id === providerId) {
      payload[id] = { ...current, ...patch }
    } else if (id === 'usernamePassword') {
      payload[id] = { enabled: current.enabled }
    } else {
      const oauth = current as OrgOAuthProviderSettings
      payload[id] = {
        enabled: oauth.enabled,
        clientId: oauth.clientId,
        tenantId: oauth.tenantId,
        allowedDomains: oauth.allowedDomains,
        clientSecret: oauth.hasClientSecret ? '__keep__' : ''
      }
    }
  }

  return payload
}

export function hasAnyAuthProviderEnabled(providers: OrgAuthProviders): boolean {
  return ORG_AUTH_PROVIDER_IDS.some(id => providers[id].enabled)
}
