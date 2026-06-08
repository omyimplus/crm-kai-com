import type { PermissionAction } from '~/config/permissionModules'

export type ProfileRole = 'owner' | 'admin' | 'employee'

export interface Profile {
  id: string
  org_id: string
  full_name: string | null
  username?: string | null
  avatar_url: string | null
  role: ProfileRole
  org_role_ids?: string[]
  is_active: boolean
}

export interface OrgUser extends Profile {
  username: string | null
  email: string | null
  org_role_labels?: string[]
  created_at: string
  updated_at: string
}

export interface OrgUserCreate {
  full_name: string
  email: string
  username: string
  password: string
  role: ProfileRole
  org_role_ids?: string[]
  is_active: boolean
  avatar_url?: string | null
}

export interface OrgUserUpdate {
  full_name?: string | null
  email?: string | null
  username?: string | null
  password?: string | null
  role?: ProfileRole
  org_role_ids?: string[]
  is_active?: boolean
  avatar_url?: string | null
  set_avatar?: boolean
  /** เมื่อ true จะไม่แตะบทบาททีม (ใช้ตอนอัปเดตรูปอย่างเดียว) */
  skip_org_roles?: boolean
}

export type OrgRolePermissions = Record<string, PermissionAction[]>

export interface OrgRole {
  id: string
  org_id: string
  code: string
  label: string
  description: string | null
  permissions: OrgRolePermissions
  is_system: boolean
  is_active: boolean
  user_count: number
  created_at: string
  updated_at: string
}

export interface OrgRoleCreatedPayload {
  id: string
  label: string
  code: string
}

export interface OrgCompanyProfileInput {
  profileName: string
  nameEn: string
  nameTh: string
  taxId: string
  taxBranch: string
  phone: string
  email: string
  website: string
  addressEn: string
  addressTh: string
  isDefault: boolean
  logoUrl?: string | null
  setLogo?: boolean
}

export interface OrgCompanyProfile extends OrgCompanyProfileInput {
  id: string
  logoUrl: string | null
  createdAt: string
  updatedAt: string
}

export interface OrgSettingsRow {
  id: string
  name: string
  slug: string
  logo_url: string | null
  settings: Record<string, unknown>
}

export interface LoginSession {
  id: string
  profile_id: string
  full_name: string | null
  email: string | null
  device_type: 'desktop' | 'mobile' | 'tablet' | 'unknown'
  browser: string
  ip_address: string | null
  logged_in_at: string
  last_seen_at: string
  ended_at: string | null
  is_active: boolean
  is_online: boolean
}

export interface OrgRoleCreate {
  code: string
  label: string
  description?: string | null
  permissions?: OrgRolePermissions
}

export interface OrgRoleUpdate {
  label?: string
  description?: string | null
  permissions?: OrgRolePermissions
  is_active?: boolean
}

export type DataChangeAction = 'create' | 'update' | 'delete'

export interface DataChangeLog {
  id: string
  actor_id: string | null
  actor_name: string | null
  action: DataChangeAction
  entity_type: string
  entity_id: string
  summary: string | null
  old_data: Record<string, unknown> | null
  new_data: Record<string, unknown> | null
  metadata: Record<string, unknown>
  created_at: string
}

export interface Company {
  id: string
  org_id: string
  name: string
  industry: string | null
  website: string | null
  phone: string | null
  address: string | null
  owner_id: string | null
  status: string
  created_at: string
}

export interface Contact {
  id: string
  org_id: string
  company_id: string | null
  first_name: string
  last_name: string | null
  email: string | null
  phone: string | null
  job_title: string | null
  owner_id: string | null
  created_at: string
  companies?: { name: string } | null
}

export interface PipelineStage {
  id: string
  org_id: string
  pipeline_id: string
  name: string
  sort_order: number
  probability: number
  is_won: boolean
  is_lost: boolean
  color: string | null
}

export interface Pipeline {
  id: string
  org_id: string
  name: string
  is_default: boolean
}

export interface Deal {
  id: string
  org_id: string
  title: string
  company_id: string | null
  contact_id: string | null
  pipeline_id: string
  stage_id: string
  owner_id: string | null
  amount: number
  currency: string
  expected_close_date: string | null
  status: string
  created_at: string
  companies?: { name: string } | null
  contacts?: { first_name: string, last_name: string | null } | null
  pipeline_stages?: { name: string, color: string | null } | null
}

export interface DealForm {
  title: string
  company_id: string | null
  contact_id: string | null
  stage_id: string
  amount: number
  expected_close_date: string | null
}
