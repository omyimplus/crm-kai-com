export interface OrgEmailSettingsForm {
  enabled: boolean
  host: string
  port: number
  username: string
  password: string
  fromName: string
  fromEmail: string
  useSslTls: boolean
}

export interface OrgEmailSettings extends Omit<OrgEmailSettingsForm, 'password'> {
  hasPassword: boolean
}

export const DEFAULT_ORG_EMAIL_SETTINGS: OrgEmailSettings = {
  enabled: false,
  host: '',
  port: 587,
  username: '',
  fromName: '',
  fromEmail: '',
  useSslTls: false,
  hasPassword: false
}
