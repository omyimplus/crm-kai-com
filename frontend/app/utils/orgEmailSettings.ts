import {
  DEFAULT_ORG_EMAIL_SETTINGS,
  type OrgEmailSettings,
  type OrgEmailSettingsForm
} from '~/config/orgEmailSettings'

function readString(value: unknown): string {
  return typeof value === 'string' ? value : ''
}

function readPort(value: unknown): number {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.trunc(value)
  }
  const parsed = Number.parseInt(readString(value), 10)
  return Number.isFinite(parsed) ? parsed : DEFAULT_ORG_EMAIL_SETTINGS.port
}

export function mergeOrgEmailSettings(
  stored: Record<string, unknown> | null | undefined,
  hasPassword = false
): OrgEmailSettings {
  if (!stored || typeof stored !== 'object') {
    return { ...DEFAULT_ORG_EMAIL_SETTINGS, hasPassword }
  }

  return {
    enabled: typeof stored.enabled === 'boolean' ? stored.enabled : DEFAULT_ORG_EMAIL_SETTINGS.enabled,
    host: readString(stored.host),
    port: readPort(stored.port),
    username: readString(stored.username),
    fromName: readString(stored.fromName),
    fromEmail: readString(stored.fromEmail),
    useSslTls: typeof stored.useSslTls === 'boolean'
      ? stored.useSslTls
      : DEFAULT_ORG_EMAIL_SETTINGS.useSslTls,
    hasPassword: hasPassword || Boolean(readString(stored.password))
  }
}

export function trimOrgEmailSettingsForm(
  form: OrgEmailSettingsForm
): OrgEmailSettingsForm {
  return {
    ...form,
    host: form.host.trim(),
    username: form.username.trim(),
    password: form.password,
    fromName: form.fromName.trim(),
    fromEmail: form.fromEmail.trim()
  }
}

export function orgEmailSettingsToPayload(form: OrgEmailSettingsForm) {
  return {
    enabled: form.enabled,
    host: form.host,
    port: form.port,
    username: form.username,
    password: form.password,
    fromName: form.fromName,
    fromEmail: form.fromEmail,
    useSslTls: form.useSslTls
  }
}

export function validateOrgEmailSettingsForm(
  form: OrgEmailSettingsForm,
  options: { requirePassword: boolean }
): 'host' | 'port' | 'username' | 'password' | 'fromName' | 'fromEmail' | null {
  if (!form.enabled) return null

  if (!form.host) return 'host'
  if (!form.port || form.port < 1 || form.port > 65535) return 'port'
  if (!form.username) return 'username'
  if (options.requirePassword && !form.password) return 'password'
  if (!form.fromName) return 'fromName'
  if (!form.fromEmail) return 'fromEmail'

  return null
}

export function settingsToForm(
  settings: OrgEmailSettings,
  password = ''
): OrgEmailSettingsForm {
  return {
    enabled: settings.enabled,
    host: settings.host,
    port: settings.port,
    username: settings.username,
    password,
    fromName: settings.fromName,
    fromEmail: settings.fromEmail,
    useSslTls: settings.useSslTls
  }
}
