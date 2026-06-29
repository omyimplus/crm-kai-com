/** รายการ Quick Create ใน header — ลิงก์จริงหรือ coming soon */

export interface AppHeaderQuickCreateItem {
  key: string
  labelKey: string
  to?: string
  ready: boolean
}

export const appHeaderQuickCreateItems: AppHeaderQuickCreateItem[] = [
  { key: 'lead', labelKey: 'appHeader.quickCreate.lead', to: '/app/leads/new', ready: true },
  { key: 'customer', labelKey: 'appHeader.quickCreate.customer', to: '/app/customer/new', ready: true },
  { key: 'contact', labelKey: 'appHeader.quickCreate.contact', to: '/app/contact/new', ready: true },
  { key: 'opportunity', labelKey: 'appHeader.quickCreate.opportunity', to: '/app/opportunities/new', ready: true },
  { key: 'quotation', labelKey: 'appHeader.quickCreate.quotation', ready: false },
  { key: 'contract', labelKey: 'appHeader.quickCreate.contract', ready: false },
  { key: 'ticket', labelKey: 'appHeader.quickCreate.ticket', ready: false },
  { key: 'activity', labelKey: 'appHeader.quickCreate.activity', ready: false }
]
