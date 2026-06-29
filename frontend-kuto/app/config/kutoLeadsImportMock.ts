/** Mock — นำเข้าเป้าหมาย `/app/leads/import` (ยังไม่ต่อ API) */

export type KutoImportStepId =
  | 'upload'
  | 'mapping'
  | 'preview'
  | 'duplicates'
  | 'confirm'
  | 'result'

export type KutoImportPreviewStatus = 'valid' | 'warning' | 'error'

export interface KutoImportFieldDef {
  key: string
  labelKey: string
  required?: boolean
}

export interface KutoImportFileColumn {
  key: string
  header: string
}

export interface KutoImportPreviewRow {
  id: string
  rowNo: number
  company: string
  contact: string
  email: string
  phone: string
  sourceKey: string
  status: KutoImportPreviewStatus
  errorKey?: string
}

export interface KutoImportHistoryRow {
  id: string
  fileName: string
  importedAt: string
  importedBy: string
  totalRows: number
  successRows: number
  failedRows: number
  statusKey: 'kuto.leads.import.history.status.completed' | 'kuto.leads.import.history.status.partial' | 'kuto.leads.import.history.status.failed'
}

export interface KutoImportDuplicateRow {
  id: string
  rowNo: number
  company: string
  email: string
  matchCode: string
  matchCompany: string
}

export type KutoImportDuplicateAction = 'skip' | 'import' | 'merge'

export const kutoImportSteps: { id: KutoImportStepId, labelKey: string }[] = [
  { id: 'upload', labelKey: 'kuto.leads.import.steps.upload' },
  { id: 'mapping', labelKey: 'kuto.leads.import.steps.mapping' },
  { id: 'preview', labelKey: 'kuto.leads.import.steps.preview' },
  { id: 'duplicates', labelKey: 'kuto.leads.import.steps.duplicates' },
  { id: 'confirm', labelKey: 'kuto.leads.import.steps.confirm' },
  { id: 'result', labelKey: 'kuto.leads.import.steps.result' }
]

export const kutoImportSummaryMeta = [
  {
    key: 'month',
    labelKey: 'kuto.leads.import.summary.month',
    subKey: 'kuto.leads.import.summary.monthSub',
    value: '12',
    accent: '#17A8A3',
    icon: 'i-lucide-upload-cloud',
    iconBg: 'bg-teal-50 text-teal-600'
  },
  {
    key: 'success',
    labelKey: 'kuto.leads.import.summary.success',
    subKey: 'kuto.leads.import.summary.successSub',
    value: '94%',
    accent: '#14B8A6',
    icon: 'i-lucide-circle-check',
    iconBg: 'bg-emerald-50 text-emerald-600'
  },
  {
    key: 'rows',
    labelKey: 'kuto.leads.import.summary.rows',
    subKey: 'kuto.leads.import.summary.rowsSub',
    value: '248',
    accent: '#3B82F6',
    icon: 'i-lucide-rows-3',
    iconBg: 'bg-blue-50 text-blue-600'
  },
  {
    key: 'last',
    labelKey: 'kuto.leads.import.summary.last',
    subKey: 'kuto.leads.import.summary.lastSub',
    value: '2 วัน',
    accent: '#8B5CF6',
    icon: 'i-lucide-clock',
    iconBg: 'bg-violet-50 text-violet-600'
  }
] as const

export const kutoImportFieldDefs: KutoImportFieldDef[] = [
  { key: 'company', labelKey: 'kuto.leads.import.fields.company', required: true },
  { key: 'contact', labelKey: 'kuto.leads.import.fields.contact', required: true },
  { key: 'email', labelKey: 'kuto.leads.import.fields.email', required: true },
  { key: 'phone', labelKey: 'kuto.leads.import.fields.phone' },
  { key: 'mobile', labelKey: 'kuto.leads.import.fields.mobile' },
  { key: 'source', labelKey: 'kuto.leads.import.fields.source' },
  { key: 'product', labelKey: 'kuto.leads.import.fields.product' },
  { key: 'priority', labelKey: 'kuto.leads.import.fields.priority' },
  { key: 'leadValue', labelKey: 'kuto.leads.import.fields.leadValue' },
  { key: 'owner', labelKey: 'kuto.leads.import.fields.owner' }
]

export const kutoImportFileColumns: KutoImportFileColumn[] = [
  { key: 'col_company', header: 'company_name' },
  { key: 'col_contact', header: 'contact_name' },
  { key: 'col_email', header: 'email' },
  { key: 'col_phone', header: 'phone' },
  { key: 'col_mobile', header: 'mobile' },
  { key: 'col_source', header: 'lead_source' },
  { key: 'col_product', header: 'product_interest' },
  { key: 'col_priority', header: 'priority' },
  { key: 'col_value', header: 'lead_value' },
  { key: 'col_owner', header: 'owner_email' },
  { key: 'col_unused', header: 'notes' }
]

/** จับคู่เริ่มต้นเมื่อโหลดไฟล์ตัวอย่าง */
export const kutoImportDefaultMapping: Record<string, string> = {
  company: 'col_company',
  contact: 'col_contact',
  email: 'col_email',
  phone: 'col_phone',
  mobile: 'col_mobile',
  source: 'col_source',
  product: 'col_product',
  priority: 'col_priority',
  leadValue: 'col_value',
  owner: 'col_owner'
}

export const kutoImportSampleFileName = 'leads-import-june-2026.csv'

export const kutoImportPreviewRows: KutoImportPreviewRow[] = [
  {
    id: '1',
    rowNo: 2,
    company: 'บริษัท เอเชีย ฟู้ดส์ จำกัด',
    contact: 'คุณสมชาย ใจดี',
    email: 'somchai@asiafoods.co.th',
    phone: '02-123-4567',
    sourceKey: 'kuto.leads.inbox.sources.website',
    status: 'valid'
  },
  {
    id: '2',
    rowNo: 3,
    company: 'Example Hospital',
    contact: 'คุณวิภา สุขใจ',
    email: 'wipa@example-hospital.or.th',
    phone: '02-999-8888',
    sourceKey: 'kuto.leads.inbox.sources.tender',
    status: 'valid'
  },
  {
    id: '3',
    rowNo: 4,
    company: 'Bangkok Technology Co., Ltd.',
    contact: 'คุณประเสริฐ มั่นคง',
    email: 'invalid-email',
    phone: '081-555-1234',
    sourceKey: 'kuto.leads.inbox.sources.lineOa',
    status: 'error',
    errorKey: 'kuto.leads.import.errors.invalidEmail'
  },
  {
    id: '4',
    rowNo: 5,
    company: '',
    contact: 'คุณมานี มีตัง',
    email: 'manee@retail.co.th',
    phone: '089-000-1111',
    sourceKey: 'kuto.leads.inbox.sources.facebook',
    status: 'error',
    errorKey: 'kuto.leads.import.errors.missingCompany'
  },
  {
    id: '5',
    rowNo: 6,
    company: 'Northern Logistics Ltd.',
    contact: 'คุณอรทัย มั่นคง',
    email: 'orathai@northlog.com',
    phone: '053-111-222',
    sourceKey: 'kuto.leads.inbox.sources.website',
    status: 'warning',
    errorKey: 'kuto.leads.import.errors.duplicateEmail'
  },
  {
    id: '6',
    rowNo: 7,
    company: 'Siam Retail Group',
    contact: 'คุณปิยะ รุ่งเรือง',
    email: 'piya@siamretail.co.th',
    phone: '081-999-0001',
    sourceKey: 'kuto.leads.inbox.sources.lineOa',
    status: 'valid'
  },
  {
    id: '7',
    rowNo: 8,
    company: 'Metro Clinic',
    contact: 'คุณนภา สุขสันต์',
    email: 'napa@metroclinic.com',
    phone: '02-444-5555',
    sourceKey: 'kuto.leads.inbox.sources.marketplace',
    status: 'valid'
  },
  {
    id: '8',
    rowNo: 9,
    company: 'Green Energy Co.',
    contact: 'คุณชัย วิริยะ',
    email: 'chai@greenenergy.co.th',
    phone: '032-777-8888',
    sourceKey: 'kuto.leads.inbox.sources.website',
    status: 'valid'
  },
  {
    id: '9',
    rowNo: 10,
    company: 'Fast Freight Ltd.',
    contact: 'คุณสุดา เร็วดี',
    email: 'suda@fastfreight.co.th',
    phone: '038-222-3333',
    sourceKey: 'kuto.leads.inbox.sources.tender',
    status: 'warning',
    errorKey: 'kuto.leads.import.errors.missingPhone'
  },
  {
    id: '10',
    rowNo: 11,
    company: 'Cloud Nine IT',
    contact: 'คุณกิตติ คลาวด์',
    email: 'kitti@cloudnine.co.th',
    phone: '02-111-2222',
    sourceKey: 'kuto.leads.inbox.sources.website',
    status: 'valid'
  }
]

export const kutoImportResultMock = {
  imported: 7,
  skipped: 2,
  failed: 1,
  total: 10
}

export const kutoImportDuplicateRows: KutoImportDuplicateRow[] = [
  {
    id: 'd1',
    rowNo: 5,
    company: 'Northern Logistics Ltd.',
    email: 'orathai@northlog.com',
    matchCode: 'LD-2390',
    matchCompany: 'Northern Logistics Ltd.'
  },
  {
    id: 'd2',
    rowNo: 8,
    company: 'Metro Clinic',
    email: 'napa@metroclinic.com',
    matchCode: 'LD-2388',
    matchCompany: 'Metro Clinic Co.'
  }
]

export const kutoImportHistory: KutoImportHistoryRow[] = [
  {
    id: 'h1',
    fileName: 'leads-import-june-2026.csv',
    importedAt: '2026-06-22 14:32',
    importedBy: 'นิชา ศรีวงศ์',
    totalRows: 48,
    successRows: 45,
    failedRows: 3,
    statusKey: 'kuto.leads.import.history.status.partial'
  },
  {
    id: 'h2',
    fileName: 'leads-q2-batch.xlsx',
    importedAt: '2026-06-15 09:10',
    importedBy: 'สมศักดิ์ ใจดี',
    totalRows: 120,
    successRows: 120,
    failedRows: 0,
    statusKey: 'kuto.leads.import.history.status.completed'
  },
  {
    id: 'h3',
    fileName: 'event-leads-may.csv',
    importedAt: '2026-05-28 16:45',
    importedBy: 'นิชา ศรีวงศ์',
    totalRows: 32,
    successRows: 28,
    failedRows: 4,
    statusKey: 'kuto.leads.import.history.status.partial'
  },
  {
    id: 'h4',
    fileName: 'bad-format.xls',
    importedAt: '2026-05-20 11:02',
    importedBy: 'สมศักดิ์ ใจดี',
    totalRows: 0,
    successRows: 0,
    failedRows: 0,
    statusKey: 'kuto.leads.import.history.status.failed'
  }
]

export function kutoImportPreviewCounts(rows: KutoImportPreviewRow[]) {
  return {
    valid: rows.filter(r => r.status === 'valid').length,
    warning: rows.filter(r => r.status === 'warning').length,
    error: rows.filter(r => r.status === 'error').length
  }
}
