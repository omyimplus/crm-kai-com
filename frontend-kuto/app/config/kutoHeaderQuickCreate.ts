/** Quick Create ใน header */

export interface KutoHeaderQuickCreateItem {
  key: string
  labelKey: string
  to?: string
  ready: boolean
}

export const kutoHeaderQuickCreateItems: KutoHeaderQuickCreateItem[] = [
  { key: 'lead', labelKey: 'kuto.header.quickCreate.lead', to: '/app/leads/new', ready: false },
  { key: 'customer', labelKey: 'kuto.header.quickCreate.customer', to: '/app/customers/new', ready: false },
  { key: 'opportunity', labelKey: 'kuto.header.quickCreate.opportunity', to: '/app/opportunities/new', ready: false },
  { key: 'quotation', labelKey: 'kuto.header.quickCreate.quotation', ready: false }
]
