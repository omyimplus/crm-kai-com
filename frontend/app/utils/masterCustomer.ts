import type { Company } from '~/types/crm'
import {
  CUSTOMER_INDUSTRIES,
  CUSTOMER_INDUSTRY_SEGMENTS,
  CUSTOMER_PAYMENT_CODES,
  CUSTOMER_SALES_GRADES,
  CUSTOMER_STATUSES,
  CUSTOMER_WHT_RATE_OPTIONS,
  CUSTOMER_TYPES,
  CUSTOMER_VAT_CURRENCIES,
  type CustomerIndustry,
  type CustomerIndustrySegment,
  type CustomerPaymentCode,
  type CustomerSalesGrade,
  type CustomerStatus,
  type CustomerWhtRate,
  type CustomerType,
  type CustomerVatCurrency
} from '~/config/masterCustomer'
import { normalizeWebsiteUrl } from '~/utils/websiteUrl'

export interface MasterCustomerFormInput {
  name: string
  customer_type: CustomerType
  email: string
  industry_segment: CustomerIndustrySegment | null
  phone: string
  industry: CustomerIndustry | null
  owner_id: string | null
  mobile: string
  sales_grade: CustomerSalesGrade | null
  status: CustomerStatus
  website: string
  notes: string
  tax_id: string
  vat_currency: CustomerVatCurrency
  credit_term_days: number
  tax_branch: string
  payment_code: CustomerPaymentCode | null
  credit_limit: number
  tax_vat: CustomerWhtRate | null
  credit_balance: number
}

export interface CustomerCompanyAddressDraft {
  id: string
  label: string
  address: string
  is_default: boolean
}

export type CustomerShipAddressDraft = CustomerCompanyAddressDraft
export type CustomerBillAddressDraft = CustomerCompanyAddressDraft

/** คง default ได้แค่ 1 รายการ — ใช้ก่อน sync ลง DB */
export function normalizeCompanyAddressDefaults(
  drafts: CustomerCompanyAddressDraft[]
): CustomerCompanyAddressDraft[] {
  const defaultIndex = drafts.findIndex(row => row.is_default)
  if (defaultIndex < 0) return drafts
  return drafts.map((row, index) => ({
    ...row,
    is_default: index === defaultIndex
  }))
}

/** @deprecated ใช้ normalizeCompanyAddressDefaults */
export const normalizeShipAddressDefaults = normalizeCompanyAddressDefaults

export function mapCompanyAddressRows(
  rows: Array<{
    id: string
    label: string | null
    address: string
    is_default: boolean
  }>
): CustomerCompanyAddressDraft[] {
  return rows.map(row => ({
    id: row.id,
    label: row.label ?? '',
    address: row.address,
    is_default: row.is_default
  }))
}

export function billAddressesFromLegacyAddress(
  companyId: string,
  address: string | null | undefined
): CustomerCompanyAddressDraft[] {
  const text = address?.trim()
  if (!text) return []
  return [{
    id: `legacy-${companyId}`,
    label: '',
    address: text,
    is_default: true
  }]
}

export function defaultCompanyAddressText(
  drafts: CustomerCompanyAddressDraft[]
): string | null {
  if (drafts.length === 0) return null
  const normalized = normalizeCompanyAddressDefaults(drafts)
  const row = normalized.find(d => d.is_default) ?? normalized[0]
  return row?.address.trim() || null
}

export function defaultMasterCustomerFormInput(): MasterCustomerFormInput {
  return {
    name: '',
    customer_type: 'company',
    email: '',
    industry_segment: null,
    phone: '',
    industry: null,
    owner_id: null,
    mobile: '',
    sales_grade: null,
    status: 'active',
    website: '',
    notes: '',
    tax_id: '',
    vat_currency: 'THB',
    credit_term_days: 30,
    tax_branch: '',
    payment_code: null,
    credit_limit: 0,
    tax_vat: null,
    credit_balance: 0
  }
}

/** บุคคลธรรมดา → ไม่ระบุอุตสาหกรรม */
export function applyIndividualCustomerTypeRules(
  input: MasterCustomerFormInput
): MasterCustomerFormInput {
  if (input.customer_type !== 'individual') return input
  return {
    ...input,
    industry_segment: null,
    industry: null
  }
}

function parseSlug<T extends string>(
  value: string | null | undefined,
  allowed: readonly string[],
  fallback: T | null
): T | null {
  if (value && allowed.includes(value)) return value as T
  return fallback
}

export function companyToFormInput(company: Company): MasterCustomerFormInput {
  return applyIndividualCustomerTypeRules({
    ...defaultMasterCustomerFormInput(),
    name: company.name,
    customer_type: parseSlug(company.customer_type, CUSTOMER_TYPES, 'company') ?? 'company',
    email: company.email ?? '',
    mobile: company.mobile ?? '',
    notes: company.notes ?? '',
    industry_segment: parseSlug(company.industry_segment, CUSTOMER_INDUSTRY_SEGMENTS, null)
      ?? parseSlug(company.industry, CUSTOMER_INDUSTRIES, null),
    phone: company.phone ?? '',
    industry: null,
    sales_grade: parseSlug(company.sales_grade, CUSTOMER_SALES_GRADES, null),
    website: company.website ?? '',
    owner_id: company.owner_id,
    status: parseSlug(company.status, CUSTOMER_STATUSES, 'active') ?? 'active',
    tax_id: company.tax_id ?? '',
    tax_branch: company.tax_branch ?? '',
    tax_vat: parseSlug(company.tax_vat, CUSTOMER_WHT_RATE_OPTIONS, null),
    vat_currency: parseSlug(company.vat_currency, CUSTOMER_VAT_CURRENCIES, 'THB') ?? 'THB',
    payment_code: parseSlug(company.payment_code, CUSTOMER_PAYMENT_CODES, null),
    credit_term_days: company.credit_term_days ?? 30,
    credit_limit: Number(company.credit_limit ?? 0),
    credit_balance: Number(company.credit_balance ?? 0)
  })
}

export function formToCompanyPayload(
  input: MasterCustomerFormInput,
  billAddresses: CustomerCompanyAddressDraft[] = []
): Partial<Company> {
  const form = applyIndividualCustomerTypeRules(input)
  return {
    name: form.name.trim(),
    customer_type: form.customer_type,
    email: form.email.trim() || null,
    mobile: form.mobile.trim() || null,
    notes: form.notes.trim() || null,
    industry_segment: form.industry_segment,
    industry: form.industry_segment,
    sales_grade: form.sales_grade,
    website: normalizeWebsiteUrl(form.website) || null,
    phone: form.phone.trim() || null,
    address: defaultCompanyAddressText(billAddresses),
    owner_id: form.owner_id || null,
    status: form.status,
    tax_id: form.tax_id.trim() || null,
    tax_branch: form.tax_branch.trim() || null,
    tax_vat: form.tax_vat,
    vat_currency: form.vat_currency,
    payment_code: form.payment_code,
    credit_term_days: form.credit_term_days,
    credit_limit: form.credit_limit
    // credit_balance: readonly — อัปเดตจาก AR Phase 2+
  }
}

export function validateMasterCustomerForm(input: MasterCustomerFormInput): string | null {
  if (!input.name.trim()) return 'nameRequired'
  if (!input.email.trim()) return 'emailRequired'
  if (!input.phone.trim()) return 'phoneRequired'
  return null
}
