import type { Service } from '~/types/crm'
import type { ServiceKind } from '~/types/crm'
import { SERVICE_KINDS, SERVICE_STATUSES } from '~/config/masterService'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'

export interface MasterServiceFormInput {
  service_code: string
  name: string
  description: string
  category_id: string | null
  unit_id: string | null
  list_price: number
  cost_price: number | null
  currency: string
  service_kind: ServiceKind
  status: 'active' | 'inactive'
  is_sellable: boolean
  notes: string
}

export function defaultMasterServiceFormInput(): MasterServiceFormInput {
  return {
    service_code: '',
    name: '',
    description: '',
    category_id: null,
    unit_id: null,
    list_price: 0,
    cost_price: null,
    currency: 'THB',
    service_kind: 'repair',
    status: 'active',
    is_sellable: true,
    notes: ''
  }
}

export function formToServicePayload(form: MasterServiceFormInput) {
  return {
    service_code: form.service_code.trim(),
    name: form.name.trim(),
    description: form.description.trim() || null,
    category_id: normalizeSelectValue(form.category_id),
    unit_id: normalizeSelectValue(form.unit_id),
    list_price: form.list_price ?? 0,
    cost_price: form.cost_price,
    currency: form.currency,
    service_kind: form.service_kind,
    status: form.status,
    is_sellable: form.is_sellable,
    notes: form.notes.trim() || null
  }
}

export function validateMasterServiceForm(form: MasterServiceFormInput): string | null {
  if (!form.service_code.trim()) return 'codeRequired'
  if (!form.name.trim()) return 'nameRequired'
  if (form.list_price < 0) return 'listPriceInvalid'
  if (form.cost_price != null && form.cost_price < 0) return 'costPriceInvalid'
  if (!(SERVICE_KINDS as readonly string[]).includes(form.service_kind)) return 'kindInvalid'
  if (!(SERVICE_STATUSES as readonly string[]).includes(form.status)) return 'statusInvalid'
  return null
}

export function serviceDisplayLabel(row: Pick<Service, 'service_code' | 'name'>) {
  return `${row.service_code} — ${row.name}`
}
