/** Mock — นำเข้าข้อมูลลูกค้า `/app/customers/import` (ยังไม่ต่อ API) */

export type KutoCustomerImportStepId =
  | 'upload'
  | 'mapping'
  | 'preview'
  | 'duplicates'
  | 'owner'
  | 'confirm'
  | 'result'

export type KutoCustomerImportPreviewStatus = 'valid' | 'warning' | 'error'

export type KutoCustomerImportSheetId = 'companies' | 'contacts'

export interface KutoCustomerImportFieldDef {
  key: string
  labelKey: string
  required?: boolean
  sheet: KutoCustomerImportSheetId
}

export interface KutoCustomerImportFileColumn {
  key: string
  header: string
  sheet: KutoCustomerImportSheetId
}

export interface KutoCustomerImportPreviewRow {
  id: string
  rowNo: number
  company: string
  taxId: string
  customerTypeKey: string
  tierKey: string
  owner: string
  statusKey: string
  status: KutoCustomerImportPreviewStatus
  errorKey?: string
}

export interface KutoCustomerImportHistoryRow {
  id: string
  fileName: string
  importedAt: string
  importedBy: string
  totalRows: number
  successRows: number
  failedRows: number
  contactRows?: number
  statusKey:
    | 'kuto.customers.import.history.status.completed'
    | 'kuto.customers.import.history.status.partial'
    | 'kuto.customers.import.history.status.failed'
}

export interface KutoCustomerImportDuplicateRow {
  id: string
  rowNo: number
  company: string
  taxId: string
  matchCode: string
  matchCompany: string
}

export type KutoCustomerImportDuplicateAction = 'skip' | 'import' | 'merge'

export type KutoCustomerImportOwnerMode = 'single' | 'roundRobin' | 'byTier'

export const kutoCustomerImportSteps: { id: KutoCustomerImportStepId, labelKey: string }[] = [
  { id: 'upload', labelKey: 'kuto.customers.import.steps.upload' },
  { id: 'mapping', labelKey: 'kuto.customers.import.steps.mapping' },
  { id: 'preview', labelKey: 'kuto.customers.import.steps.preview' },
  { id: 'duplicates', labelKey: 'kuto.customers.import.steps.duplicates' },
  { id: 'owner', labelKey: 'kuto.customers.import.steps.owner' },
  { id: 'confirm', labelKey: 'kuto.customers.import.steps.confirm' },
  { id: 'result', labelKey: 'kuto.customers.import.steps.result' }
]

export const kutoCustomerImportSheets: { id: KutoCustomerImportSheetId, labelKey: string }[] = [
  { id: 'companies', labelKey: 'kuto.customers.import.sheets.companies' },
  { id: 'contacts', labelKey: 'kuto.customers.import.sheets.contacts' }
]

export const kutoCustomerImportSummaryMeta = [
  {
    key: 'month',
    labelKey: 'kuto.customers.import.summary.month',
    subKey: 'kuto.customers.import.summary.monthSub',
    value: '8',
    accent: '#17A8A3',
    icon: 'i-lucide-upload-cloud',
    iconBg: 'bg-teal-50 text-teal-600'
  },
  {
    key: 'success',
    labelKey: 'kuto.customers.import.summary.success',
    subKey: 'kuto.customers.import.summary.successSub',
    value: '96%',
    accent: '#14B8A6',
    icon: 'i-lucide-circle-check',
    iconBg: 'bg-emerald-50 text-emerald-600'
  },
  {
    key: 'rows',
    labelKey: 'kuto.customers.import.summary.rows',
    subKey: 'kuto.customers.import.summary.rowsSub',
    value: '412',
    accent: '#3B82F6',
    icon: 'i-lucide-rows-3',
    iconBg: 'bg-blue-50 text-blue-600'
  },
  {
    key: 'last',
    labelKey: 'kuto.customers.import.summary.last',
    subKey: 'kuto.customers.import.summary.lastSub',
    value: '5 วัน',
    accent: '#8B5CF6',
    icon: 'i-lucide-clock',
    iconBg: 'bg-violet-50 text-violet-600'
  }
] as const

export const kutoCustomerImportFieldDefs: KutoCustomerImportFieldDef[] = [
  { key: 'company', labelKey: 'kuto.customers.import.fields.company', required: true, sheet: 'companies' },
  { key: 'taxId', labelKey: 'kuto.customers.import.fields.taxId', required: true, sheet: 'companies' },
  { key: 'customerType', labelKey: 'kuto.customers.import.fields.customerType', sheet: 'companies' },
  { key: 'businessType', labelKey: 'kuto.customers.import.fields.businessType', sheet: 'companies' },
  { key: 'tier', labelKey: 'kuto.customers.import.fields.tier', sheet: 'companies' },
  { key: 'status', labelKey: 'kuto.customers.import.fields.status', sheet: 'companies' },
  { key: 'owner', labelKey: 'kuto.customers.import.fields.owner', sheet: 'companies' },
  { key: 'phone', labelKey: 'kuto.customers.import.fields.phone', sheet: 'companies' },
  { key: 'email', labelKey: 'kuto.customers.import.fields.email', sheet: 'companies' },
  { key: 'province', labelKey: 'kuto.customers.import.fields.province', sheet: 'companies' },
  { key: 'contactName', labelKey: 'kuto.customers.import.fields.contactName', required: true, sheet: 'contacts' },
  { key: 'contactEmail', labelKey: 'kuto.customers.import.fields.contactEmail', sheet: 'contacts' },
  { key: 'contactPhone', labelKey: 'kuto.customers.import.fields.contactPhone', sheet: 'contacts' },
  { key: 'companyCode', labelKey: 'kuto.customers.import.fields.companyCode', required: true, sheet: 'contacts' },
  { key: 'contactRole', labelKey: 'kuto.customers.import.fields.contactRole', sheet: 'contacts' },
  { key: 'primaryContact', labelKey: 'kuto.customers.import.fields.primaryContact', sheet: 'contacts' }
]

export const kutoCustomerImportFileColumns: KutoCustomerImportFileColumn[] = [
  { key: 'col_company', header: 'company_name', sheet: 'companies' },
  { key: 'col_tax', header: 'tax_id', sheet: 'companies' },
  { key: 'col_type', header: 'customer_type', sheet: 'companies' },
  { key: 'col_business', header: 'business_type', sheet: 'companies' },
  { key: 'col_tier', header: 'tier', sheet: 'companies' },
  { key: 'col_status', header: 'status', sheet: 'companies' },
  { key: 'col_owner', header: 'owner_email', sheet: 'companies' },
  { key: 'col_phone', header: 'phone', sheet: 'companies' },
  { key: 'col_email', header: 'email', sheet: 'companies' },
  { key: 'col_province', header: 'province', sheet: 'companies' },
  { key: 'col_c_name', header: 'contact_name', sheet: 'contacts' },
  { key: 'col_c_email', header: 'contact_email', sheet: 'contacts' },
  { key: 'col_c_phone', header: 'contact_phone', sheet: 'contacts' },
  { key: 'col_c_code', header: 'customer_code', sheet: 'contacts' },
  { key: 'col_c_role', header: 'contact_role', sheet: 'contacts' },
  { key: 'col_c_primary', header: 'is_primary', sheet: 'contacts' }
]

export const kutoCustomerImportDefaultMapping: Record<string, string> = {
  company: 'col_company',
  taxId: 'col_tax',
  customerType: 'col_type',
  businessType: 'col_business',
  tier: 'col_tier',
  status: 'col_status',
  owner: 'col_owner',
  phone: 'col_phone',
  email: 'col_email',
  province: 'col_province',
  contactName: 'col_c_name',
  contactEmail: 'col_c_email',
  contactPhone: 'col_c_phone',
  companyCode: 'col_c_code',
  contactRole: 'col_c_role',
  primaryContact: 'col_c_primary'
}

export const kutoCustomerImportSampleFileName = 'customers-import-june-2026.xlsx'

export const kutoCustomerImportOwnerOptions = [
  { value: 'somsak', labelKey: 'kuto.customers.import.owner.somsak' },
  { value: 'nicha', labelKey: 'kuto.customers.import.owner.nicha' },
  { value: 'wipa', labelKey: 'kuto.customers.import.owner.wipa' }
] as const

export const kutoCustomerImportPreviewRows: KutoCustomerImportPreviewRow[] = [
  {
    id: '1',
    rowNo: 2,
    company: 'บริษัท เอเชีย ฟู้ดส์ จำกัด',
    taxId: '0105551234567',
    customerTypeKey: 'kuto.customers.list.types.enterprise',
    tierKey: 'kuto.customers.list.tiers.gold',
    owner: 'สมศักดิ์ ใจดี',
    statusKey: 'kuto.customers.list.status.active',
    status: 'valid'
  },
  {
    id: '2',
    rowNo: 3,
    company: 'Bangkok Technology Co., Ltd.',
    taxId: '0105559876543',
    customerTypeKey: 'kuto.customers.list.types.keyAccount',
    tierKey: 'kuto.customers.list.tiers.platinum',
    owner: 'นิชา ศรีวงศ์',
    statusKey: 'kuto.customers.list.status.active',
    status: 'valid'
  },
  {
    id: '3',
    rowNo: 4,
    company: 'Example Hospital',
    taxId: 'invalid-tax',
    customerTypeKey: 'kuto.customers.list.types.enterprise',
    tierKey: 'kuto.customers.list.tiers.silver',
    owner: 'สมศักดิ์ ใจดี',
    statusKey: 'kuto.customers.list.status.active',
    status: 'error',
    errorKey: 'kuto.customers.import.errors.invalidTaxId'
  },
  {
    id: '4',
    rowNo: 5,
    company: '',
    taxId: '0105551112222',
    customerTypeKey: 'kuto.customers.list.types.sme',
    tierKey: 'kuto.customers.list.tiers.silver',
    owner: 'วิภา สุขใจ',
    statusKey: 'kuto.customers.list.status.active',
    status: 'error',
    errorKey: 'kuto.customers.import.errors.missingCompany'
  },
  {
    id: '5',
    rowNo: 6,
    company: 'Northern Logistics Ltd.',
    taxId: '0105553334444',
    customerTypeKey: 'kuto.customers.list.types.standard',
    tierKey: 'kuto.customers.list.tiers.gold',
    owner: 'สมศักดิ์ ใจดี',
    statusKey: 'kuto.customers.list.status.active',
    status: 'warning',
    errorKey: 'kuto.customers.import.errors.duplicateTaxId'
  },
  {
    id: '6',
    rowNo: 7,
    company: 'Siam Retail Group',
    taxId: '0105555556666',
    customerTypeKey: 'kuto.customers.list.types.keyAccount',
    tierKey: 'kuto.customers.list.tiers.platinum',
    owner: 'นิชา ศรีวงศ์',
    statusKey: 'kuto.customers.list.status.active',
    status: 'valid'
  },
  {
    id: '7',
    rowNo: 8,
    company: 'Metro Clinic',
    taxId: '0105557778888',
    customerTypeKey: 'kuto.customers.list.types.enterprise',
    tierKey: 'kuto.customers.list.tiers.gold',
    owner: 'วิภา สุขใจ',
    statusKey: 'kuto.customers.list.tabs.target',
    status: 'valid'
  },
  {
    id: '8',
    rowNo: 9,
    company: 'Green Energy Co.',
    taxId: '0105559990000',
    customerTypeKey: 'kuto.customers.list.types.sme',
    tierKey: 'kuto.customers.list.tiers.silver',
    owner: 'สมศักดิ์ ใจดี',
    statusKey: 'kuto.customers.list.status.active',
    status: 'valid'
  },
  {
    id: '9',
    rowNo: 10,
    company: 'Pacific Holdings',
    taxId: '0105551212121',
    customerTypeKey: 'kuto.customers.list.types.standard',
    tierKey: 'kuto.customers.list.tiers.silver',
    owner: 'นิชา ศรีวงศ์',
    statusKey: 'kuto.customers.list.status.inactive',
    status: 'warning',
    errorKey: 'kuto.customers.import.errors.missingOwner'
  },
  {
    id: '10',
    rowNo: 11,
    company: 'Cloud Nine IT',
    taxId: '0105553434343',
    customerTypeKey: 'kuto.customers.list.types.keyAccount',
    tierKey: 'kuto.customers.list.tiers.gold',
    owner: 'วิภา สุขใจ',
    statusKey: 'kuto.customers.list.status.active',
    status: 'valid'
  }
]

export const kutoCustomerImportResultMock = {
  imported: 7,
  skipped: 2,
  failed: 1,
  contactsImported: 14,
  total: 10
}

export const kutoCustomerImportDuplicateRows: KutoCustomerImportDuplicateRow[] = [
  {
    id: 'd1',
    rowNo: 6,
    company: 'Northern Logistics Ltd.',
    taxId: '0105553334444',
    matchCode: 'CU-1042',
    matchCompany: 'Northern Logistics Ltd.'
  },
  {
    id: 'd2',
    rowNo: 8,
    company: 'Metro Clinic',
    taxId: '0105557778888',
    matchCode: 'CU-0891',
    matchCompany: 'Metro Clinic Co.'
  }
]

export const kutoCustomerImportHistory: KutoCustomerImportHistoryRow[] = [
  {
    id: 'h1',
    fileName: 'customers-import-june-2026.xlsx',
    importedAt: '2026-06-20 11:15',
    importedBy: 'นิชา ศรีวงศ์',
    totalRows: 56,
    successRows: 52,
    failedRows: 4,
    contactRows: 28,
    statusKey: 'kuto.customers.import.history.status.partial'
  },
  {
    id: 'h2',
    fileName: 'q2-customers-batch.csv',
    importedAt: '2026-06-10 09:40',
    importedBy: 'สมศักดิ์ ใจดี',
    totalRows: 85,
    successRows: 85,
    failedRows: 0,
    contactRows: 42,
    statusKey: 'kuto.customers.import.history.status.completed'
  },
  {
    id: 'h3',
    fileName: 'legacy-customers-may.xlsx',
    importedAt: '2026-05-25 16:20',
    importedBy: 'วิภา สุขใจ',
    totalRows: 24,
    successRows: 20,
    failedRows: 4,
    contactRows: 12,
    statusKey: 'kuto.customers.import.history.status.partial'
  },
  {
    id: 'h4',
    fileName: 'bad-format-customers.xls',
    importedAt: '2026-05-18 10:05',
    importedBy: 'สมศักดิ์ ใจดี',
    totalRows: 0,
    successRows: 0,
    failedRows: 0,
    statusKey: 'kuto.customers.import.history.status.failed'
  }
]

export function kutoCustomerImportPreviewCounts(rows: KutoCustomerImportPreviewRow[]) {
  return {
    valid: rows.filter(r => r.status === 'valid').length,
    warning: rows.filter(r => r.status === 'warning').length,
    error: rows.filter(r => r.status === 'error').length
  }
}

export function kutoCustomerImportFieldsForSheet(sheet: KutoCustomerImportSheetId) {
  return kutoCustomerImportFieldDefs.filter(f => f.sheet === sheet)
}

export function kutoCustomerImportColumnsForSheet(sheet: KutoCustomerImportSheetId) {
  return kutoCustomerImportFileColumns.filter(c => c.sheet === sheet)
}
