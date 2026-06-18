import type { CustomerType } from '~/config/masterCustomer'
import type { LeadType } from '~/config/masterLeads'
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
  customer_type: string
  email: string | null
  mobile: string | null
  notes: string | null
  industry: string | null
  industry_segment: string | null
  sales_grade: string | null
  website: string | null
  phone: string | null
  address: string | null
  owner_id: string | null
  status: string
  tax_id: string | null
  tax_branch: string | null
  tax_vat: string | null
  vat_currency: string
  payment_code: string | null
  credit_term_days: number
  credit_limit: number
  credit_balance: number
  created_at: string
  deleted_at?: string | null
}

export interface CompanyBillAddress {
  id: string
  org_id: string
  company_id: string
  label: string | null
  address: string
  is_default: boolean
  sort_order: number
  created_at: string
  updated_at: string
}

export interface CompanyShipAddress {
  id: string
  org_id: string
  company_id: string
  label: string | null
  address: string
  is_default: boolean
  sort_order: number
  created_at: string
  updated_at: string
}

export interface Contact {
  id: string
  org_id: string
  company_id: string | null
  first_name: string
  last_name: string | null
  email: string | null
  phone: string | null
  mobile: string | null
  job_title: string | null
  department: string | null
  contact_role: string | null
  is_main_contact: boolean
  notes: string | null
  owner_id: string | null
  created_at: string
  deleted_at?: string | null
  companies?: { name: string, deleted_at?: string | null } | null
}

export type CategoryStatus = 'active' | 'inactive'

export interface Category {
  id: string
  org_id: string
  module_key: string
  category_code: string
  name: string
  description: string | null
  parent_id: string | null
  sort_order: number
  color: string | null
  status: CategoryStatus
  notes: string | null
  image_url: string | null
  created_at: string
  updated_at: string
  deleted_at?: string | null
  parent?: {
    id: string
    category_code: string
    name: string
    deleted_at?: string | null
  } | null
}

export type UnitStatus = 'active' | 'inactive'

export interface Unit {
  id: string
  org_id: string
  unit_code: string
  name: string
  description: string | null
  sort_order: number
  status: UnitStatus
  notes: string | null
  created_at: string
  updated_at: string
  deleted_at?: string | null
}

export type LeadSourceStatus = 'active' | 'inactive'

export interface LeadSource {
  id: string
  org_id: string
  source_code: string
  name: string
  description: string | null
  sort_order: number
  status: LeadSourceStatus
  notes: string | null
  created_at: string
  updated_at: string
  deleted_at?: string | null
}

export type PartnerStatus = 'active' | 'inactive'

export type PartnerType =
  | 'distributor'
  | 'reseller'
  | 'agent'
  | 'vendor'
  | 'strategic'
  | 'other'

export type PartnerTier =
  | 'platinum'
  | 'gold'
  | 'silver'
  | 'bronze'
  | 'standard'

export interface Partner {
  id: string
  org_id: string
  partner_code: string
  name: string
  partner_type: PartnerType
  tier: PartnerTier
  partner_since: string | null
  status: PartnerStatus
  contact_person: string
  email: string
  phone: string
  website: string | null
  commission_rate: number
  description?: string | null
  sort_order?: number
  notes?: string | null
  created_at: string
  updated_at: string
  deleted_at?: string | null
}

export type SalesTeamStatus = 'active' | 'inactive'

export interface SalesTeamProfileSummary {
  id: string
  full_name: string | null
  username?: string | null
  avatar_url?: string | null
}

export interface SalesTeamMember {
  profile_id: string
  profiles?: SalesTeamProfileSummary | null
}

export interface SalesTeam {
  id: string
  org_id: string
  team_code: string
  name: string
  description: string | null
  team_lead_id: string | null
  team_lead?: SalesTeamProfileSummary | null
  sales_team_members?: SalesTeamMember[]
  sort_order: number
  status: SalesTeamStatus
  notes: string | null
  created_at: string
  updated_at: string
  deleted_at?: string | null
}

export type ModuleStatusRecordStatus = 'active' | 'inactive'

export interface ModuleStatus {
  id: string
  org_id: string
  module_key: string
  status_code: string
  name: string
  description: string | null
  color: string | null
  sort_order: number
  is_default: boolean
  status: ModuleStatusRecordStatus
  notes: string | null
  created_at: string
  updated_at: string
  deleted_at?: string | null
}

export type JobCodeRecordStatus = 'active' | 'inactive'

export interface JobCodeSequence {
  id: string
  org_id: string
  module_key: string
  prefix: string
  date_enabled: boolean
  date_include_year: boolean
  date_include_month: boolean
  date_include_day: boolean
  date_part_order: string[]
  date_style: string
  segment_order: string[]
  separator_enabled: boolean
  segment_separator: string
  pad_length: number
  start_number: number
  last_number: number
  reset_rule: string
  status: JobCodeRecordStatus
  notes: string | null
  created_at: string
  updated_at: string
  deleted_at?: string | null
}

export type ProductStatus = 'active' | 'inactive'

export interface Product {
  id: string
  org_id: string
  product_code: string
  name: string
  description: string | null
  category_id: string | null
  unit_id: string | null
  list_price: number
  cost_price: number | null
  currency: string
  barcode: string | null
  status: ProductStatus
  is_sellable: boolean
  notes: string | null
  image_url: string | null
  created_at: string
  updated_at: string
  deleted_at?: string | null
}

export interface ProductGalleryImage {
  id: string
  org_id: string
  product_id: string
  image_url: string
  sort_order: number
  created_at: string
  updated_at: string
}

export type SalesTargetPeriodType = 'month' | 'quarter' | 'year'

export interface SalesTarget {
  id: string
  org_id: string
  profile_id: string
  period_type: SalesTargetPeriodType
  period_year: number
  period_month: number | null
  period_quarter: number | null
  target_amount: number
  current_amount: number
  currency: string
  notes: string | null
  created_at: string
  updated_at: string
  deleted_at?: string | null
  profiles?: { full_name: string | null, username: string | null } | null
  achievement_pct?: number
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

export interface TaskAssignee {
  id: string
  full_name: string | null
  username: string | null
  avatar_url: string | null
  role: ProfileRole
  is_active: boolean
}

export interface Task {
  id: string
  org_id: string
  task_code: string
  subject: string
  task_type: 'task' | 'call' | 'email' | 'meeting' | 'visit'
  module_status_id: string
  status_code: string
  status_name: string
  status_color: string | null
  priority: 'high' | 'medium' | 'low'
  start_at: string | null
  end_at: string | null
  assigned_by: string | null
  assigned_by_name: string | null
  assigned_to: string | null
  assigned_to_name: string | null
  sales_team_id: string | null
  sales_team_name: string | null
  company_id: string | null
  company_name: string | null
  contact_id: string | null
  contact_name: string | null
  description: string | null
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface TaskFormInput {
  subject: string
  task_type: Task['task_type']
  module_status_id: string | null
  priority: Task['priority']
  start_at: string
  end_at: string
  assigned_by: string | null
  assigned_to: string | null
  sales_team_id: string | null
  company_id: string | null
  contact_id: string | null
  description: string
  status_history: TaskStatusHistoryInput[]
}

export interface TaskStatusHistoryEntry {
  id: string
  module_status_id: string
  status_code: string
  status_name: string
  status_color: string | null
  sort_order: number
  status_at: string
  changed_by: string | null
  changed_by_name: string | null
}

export interface TaskStatusHistoryInput {
  id?: string
  module_status_id: string
  status_at: string
  status_code?: string
  status_name?: string
  status_color?: string | null
  changed_by?: string | null
  changed_by_name?: string | null
}

export type { LeadType } from '~/config/masterLeads'
export type LeadPriority = 'high' | 'medium' | 'low'

export interface Lead {
  id: string
  org_id: string
  lead_code: string
  full_name: string | null
  lead_type: LeadType
  owner_id: string | null
  owner_name: string | null
  tele_sale_id: string | null
  tele_sale_name: string | null
  company_id: string | null
  contact_id: string | null
  contact_name: string | null
  company_name: string | null
  email: string
  phone: string | null
  mobile: string
  tax_id: string | null
  lead_value: number
  customer_type: CustomerType
  industry_segment: string | null
  sales_grade: string | null
  lead_source_id: string | null
  lead_source_name: string | null
  module_status_id: string
  status_code: string
  status_name: string
  status_color: string | null
  priority: LeadPriority
  next_action_at: string | null
  next_action: string | null
  lead_score: number
  requirement: string | null
  address_street: string | null
  address_sub_district: string | null
  address_district: string | null
  address_province: string | null
  address_postal_code: string | null
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface LeadFormInput {
  full_name: string
  lead_type: LeadType
  owner_id: string | null
  tele_sale_id: string | null
  company_id: string | null
  contact_id: string | null
  company_name: string
  email: string
  phone: string
  mobile: string
  tax_id: string
  lead_value: string
  customer_type: CustomerType
  industry_segment: string | null
  sales_grade: string | null
  lead_source_id: string | null
  module_status_id: string | null
  priority: LeadPriority
  next_action_at: string
  next_action: string
  lead_score: number
  requirement: string
  address_street: string
  address_sub_district: string
  address_district: string
  address_province: string
  address_postal_code: string
}

export type OpportunityStatus = 'open' | 'won' | 'lost'

export interface Opportunity {
  id: string
  org_id: string
  opportunity_code: string
  title: string
  lead_id: string
  lead_code: string
  company_id: string | null
  company_name: string | null
  contact_id: string | null
  contact_name: string | null
  pipeline_id: string
  stage_id: string
  stage_name: string
  stage_color: string | null
  stage_probability: number
  stage_is_won: boolean
  stage_is_lost: boolean
  probability: number
  estimated_value: number
  close_date: string | null
  description: string | null
  project_name: string | null
  project_type: string | null
  project_sub_type: string | null
  products_group: string | null
  project_costs: number
  owner_id: string | null
  owner_name: string | null
  sales_owner_id: string | null
  sales_owner_name: string | null
  sales_designer_id: string | null
  sales_designer_name: string | null
  sales_team_id: string | null
  sales_team_name: string | null
  address_bill_to: string | null
  currency: string
  status: OpportunityStatus
  closed_at: string | null
  created_by: string | null
  created_at: string
  updated_at: string
}

export interface OpportunityProject {
  id: string
  opportunity_id: string
  project_name: string | null
  project_type: string | null
  project_sub_type: string | null
  products_group: string | null
  estimated_value: number
  project_costs: number
  sort_order: number
  created_at: string
  updated_at: string
}

export interface OpportunityProjectDraft {
  id: string
  project_name: string
  project_type: string
  project_sub_type: string
  products_group: string
  estimated_value: string
  project_costs: string
}

export interface OpportunityFormInput {
  title: string
  company_id: string | null
  contact_id: string | null
  stage_id: string | null
  probability: number
  close_date: string
  description: string
  owner_id: string | null
  sales_owner_id: string | null
  sales_designer_id: string | null
  sales_team_id: string | null
  address_bill_to: string
}
