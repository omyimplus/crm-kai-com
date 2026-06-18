/** Shared form field styles — ใช้คู่กับ AppDialog ทั้งระบบ */

export const appFormFieldClass = 'w-full'

export const appInputUi = { base: 'w-full rounded-xl' }

export const appSelectUi = { base: 'w-full rounded-xl' }

export const appSelectMenuUi = { base: 'w-full rounded-xl' }

export const appTextareaUi = { base: 'w-full rounded-xl' }

export const appFormHintClass
  = 'mt-1.5 text-xs leading-relaxed text-gray-500 dark:text-gray-400'

export const appFormSwitchBoxClass
  = 'flex w-full items-center gap-3 rounded-xl border border-gray-200 bg-gray-50 px-4 py-3 dark:border-gray-700 dark:bg-gray-800/50'

export const appFormErrorClass
  = 'rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-600 dark:border-red-900/50 dark:bg-red-950/40 dark:text-red-300'

export const appFormInfoClass
  = 'rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-xs leading-relaxed text-green-800 dark:border-green-900/50 dark:bg-green-950/40 dark:text-green-200'

/** ตาราง — ขนาด body CRM + weight 400 ให้สม่ำเสมอ (D-010) */
export const appTableTextClass = 'text-[calc(0.875rem+1px)] font-normal leading-snug'

/** แถวตารางที่เน้นอ่านง่าย — ใช้กับ tasks list เป็นหลัก */
export const appTableRowClass = 'text-[calc(0.875rem+1px)] font-semibold leading-snug'

/** ลิงก์ใน cell ตาราง — ขนาด/น้ำหนักเดียวกับ appTableTextClass */
export const appTableCellLinkClass
  = 'text-[calc(0.875rem+1px)] font-normal leading-snug text-primary underline-offset-2 transition hover:text-primary/80 hover:underline'

/** ลิงก์ในแถวตาราง tasks — น้ำหนักเดียวกับ appTableRowClass */
export const appTableRowLinkClass
  = 'text-[calc(0.875rem+1px)] font-semibold leading-snug text-primary underline-offset-2 transition hover:text-primary/80 hover:underline'

/** Chip/badge ในตาราง — ตัวอักษรดำหนา อ่านง่ายบนพื้น subtle */
export const appTableBadgeClass
  = 'font-semibold text-gray-900 dark:text-gray-100'

/** Tab กรอง role เหนือตาราง — inline-block กล่อง */
export const appTableRoleTabBaseClass
  = 'inline-block rounded-lg border px-3 py-1.5 font-semibold transition-colors'

/** Sidebar — ใช้ scale เดียวกับเนื้อหา (appTableTextClass) */
export const appSidebarNavTextClass = appTableTextClass

export const appSidebarSectionTextClass
  = 'text-xs font-semibold font-heading uppercase tracking-wider'

export const appTableRoleTabActiveClass
  = 'border-menu-section bg-menu-section text-white shadow-sm dark:border-primary dark:bg-primary'

export const appTableRoleTabInactiveClass
  = 'border-gray-200 bg-white text-gray-800 hover:border-gray-300 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-200 dark:hover:bg-gray-800'

/** Chip ระดับองค์กร — สีแยก owner / admin / employee */
export const appPlatformRoleBadgeClass = {
  owner: 'bg-amber-100 ring-1 ring-inset ring-amber-300/60 dark:bg-amber-950/50 dark:ring-amber-700/50',
  admin: 'bg-sky-100 ring-1 ring-inset ring-sky-300/60 dark:bg-sky-950/50 dark:ring-sky-700/50',
  employee: 'bg-emerald-50 ring-1 ring-inset ring-emerald-300/50 dark:bg-emerald-950/40 dark:ring-emerald-800/50'
} as const
