# Changelog — Frontend

→ [README.md](./README.md)

---

## ประวัติ

### 2026-06-22 — Typography: body weight 500

- **`main.css` / `app.vue`:** IBM Plex Sans Thai Medium (500) เป็นค่าเริ่มต้น · โหลด weight 500
- **`appFormUi`:** ตาราง/sidebar ใช้ `font-medium` แทน `font-normal`
- **Docs:** D-010 · `TYPOGRAPHY.md`

### 2026-06-22 — Primary navy ตาม demo KuTo

- **`primary: 'blue'`** · `#0b2a5b` — ปุ่ม header, CTA, sidebar icon active
- **Accent emerald** `#10b981` — KPI, mode label (คง `green-*`)
- **Sidebar:** `sidebar-accent` `#eef6ff` · หัว section แบบ demo
- **`appChart.ts`** · `BRAND-ASSETS.md` sync

### 2026-06-22 — Shell colors ตาม demo KuTo

- **Palette:** emerald `#10b981` (primary) · พื้นหลัง `#f6f8fb` · token `shell-*` ใน `main.css`
- **`appShellTheme.ts`** — ใช้ร่วม header + dashboard + layout

### 2026-06-22 — Dashboard mock (KuTo demo)

- **`DashboardMockView`** — KPI 6 ใบ · ตารางลูกค้า · Customer 360 · AI panel · status badges
- ข้อมูลจำลองใน `config/dashboardMock.ts` · layout เปิด main บน `/app` (ไม่มีกล่องขาวซ้อน)

### 2026-06-22 — Header แบบ demo KuTo

- **`AppHeader`:** ค้นหาทั้งระบบ · Quick create · งานรออนุมัติ (admin) · แจ้งเตือน (placeholder)
- **`LocaleSwitcher`:** ปุ่ม TH / EN แบบ mock (แทนธง)
- **`ThemeToggle`:** ปุ่ม moon/sun ใน header · รองรับ dark mode
- **`UserMenu`:** avatar/initials + ชื่อ + บทบาท แบบ demo
- **Mobile:** ปุ่มเมนู + sidebar drawer (`useMobileNav`)

### 2026-06-22 — Brand: โลโก้ CuTo CRM (แทน kai-com)

- **Assets:** แปลง `public/images/logo.png` → `logo/logo-kai-com-crm.webp` (900×300) + `logo-kai-com-crm-icon.webp` (crop KC mark ซ้าย)
- **`AppLogo`:** prop `framed` — กล่องขาวมุมโค้งแบบ demo KuTo
- **ใช้ที่:** sidebar, auth brand panel, favicon, default avatar

### 2026-06-18 — Opportunities: รายการสินค้า/บริการ + หมวดสินค้า/บริการ

- **UI:** `OpportunitiesLineItems.vue` — ตาราง line items แทน project cards (cascade หมวด 3 ชั้นสินค้า / 2–3 ชั้นบริการ · combobox สินค้า/บริการ · qty/price · quick-create)
- **Category:** `/app/category` — toggle **สินค้า | บริการ** · `module_key` บนฟอร์ม/ต้นไม้
- **Service master:** `/app/service` · `/app/service/new` · `useServices`
- **DB:** migration `20260608120088_service_categories_line_items.sql` — `services`, `opportunity_line_items`, RPC sync/create/update
- **เมนู:** `service` ตั้ง `ready: true`

### 2026-06-18 — Opportunities: เอาที่อยู่ออกบิลออกจากฟอร์ม

- **เหตุผล:** ใช้ที่อยู่ออกบิลจาก master ลูกค้า — ไม่เลือกซ้ำบน opp
- **UI:** ลบ section Address · `OpportunitiesCustomerBillAddressModal`
- **Payload:** ไม่ส่ง `address_bill_to` — RPC สร้าง opp ดึง default จาก `get_company_default_bill_address`

### 2026-06-18 — Opportunities: สร้าง standalone (ไม่ผ่านลีด)

- **Route:** `/app/opportunities/new` · ปุ่มบนรายการ
- **UI:** `LeadsCustomerSection` — เลือกลูกค้าเดิมหรือสร้างใหม่
- **DB:** migration `20260608120087_opportunity_standalone_create.sql` · RPC `create_opportunity`

### 2026-06-18 — Opportunities: แก้ dropdown โปรเจกต์

- **Root cause:** `USelectMenu` + `value: ''` ทำให้ listbox ไม่ render
- **`OpportunitiesProjectCard.vue`:** enum ใช้ `null` + `normalizeSelectValue` · computed options
- **Types:** `OpportunityProjectDraft` — `project_type` / `project_sub_type` / `products_group` เป็น `string | null`

### 2026-06-18 — Opportunities i18n (th/en)

- แปลครบ `opportunities.*` · `stageNames` สำหรับ default pipeline · `usePipelineStageLabel`
- ชื่อ prefill จากลีดใช้ `defaultTitleSuffix` แทน hardcode ภาษาอังกฤษ

### 2026-06-18 — Opportunities module v1

- **Route:** `/app/opportunities` · `from-lead/:leadId` · `:id` · `:id/edit`
- **DB:** migration `20260608120081_opportunities_module.sql` (ต้อง apply ก่อนทดสอบ)
- **Flow:** สร้างจากลีดเท่านั้น · Convert บนหน้าดูลีด
- **Spec:** [OPPORTUNITIES-MODULE.md](../docs/05-frontend/OPPORTUNITIES-MODULE.md)

### 2026-06-18 — Leads: หน้าดู + ปุ่มดู (แยกจากแก้ไข)

- Route `/app/leads/:id` · `LeadsLeadViewPage.vue` (readonly)
- ตาราง/การ์ด: ปุ่มดู (eye) · ไม่คลิกแถวเข้าแก้ไข
- หลังสร้าง/บันทึกแก้ไข → กลับหน้าดู

### 2026-06-18 — Leads list: ตารางใหม่ + ฟิลเตอร์

- ตาราง: คอลัมน์ Lead (คะแนน + ชื่อ + รหัส + ความสำคัญ) · มูลค่า · ดำเนินการถัดไป · แหล่งที่มา · เจ้าของ · สถานะ
- ฟิลเตอร์: ชิปสถานะ · การ์ดสรุปสอดคล้องตัวกรอง · ช่วงวันที่
- `LeadsStatusBadge` — UBadge subtle + จุดสี (สไตล์เดียวกับ Tasks)
- component `LeadsLeadTable.vue`

### 2026-06-18 — Lead form: ฟอร์มลูกค้าใหม่ตามหน้าสร้างลูกค้า

- ลูกค้าใหม่บนหน้าลีด: ใช้ `MasterDataCustomerForm` — ข้อมูลทั่วไป · ภาษี · ที่อยู่ออกใบแจ้งหนี้ (ซ่อน ship-to)
- ลูกค้าในระบบ: สรุป + ปุ่มไป `/app/customer/:id/edit`
- ลบ `LeadsCustomerQuickForm` (ฟิลด์น้อยเกินไป)

### 2026-06-18 — Lead form: ย่อฟอร์มลูกค้า (superseded)

### 2026-06-18 — Fix lead_value save on edit (number from spinbutton)

- `formToLeadPayload`: coerce `lead_value` with `String()` before `.trim()` — แก้ error ตอนบันทึกแก้ไขลีดเมื่อมูลค่าเป็น number

### 2026-06-18 — Lead form layout: ลูกค้าก่อนคะแนนลีด

- ลำดับ: ข้อมูลทั่วไป → ลูกค้า → คะแนนลีด → ความต้องการ

### 2026-06-18 — Lead form layout: ข้อมูลลีดบนสุด

- หน้า new/edit: `LeadsForm` ก่อน `LeadsCustomerSection`

### 2026-06-18 — Fix: customer_type vs lead_type

- **Customer Type** กลับ `company` / `individual` (เหมือนฟอร์มลูกค้า)
- **Lead Type** → End User · Dealer · Contractor · Distributor · OEM · Other
- migration `20260608120080_restore_customer_type_lead_type_channel.sql`

### 2026-06-18 — Industry Segment catalog (mockup)

- `industry_segment`: Agriculture … Transportation (แทน enterprise/sme/startup/individual)
- ซ่อนฟิลด์ Industry ซ้ำในฟอร์ม · placeholder th/en
- migration `20260608120079_industry_segment_catalog.sql`

### 2026-06-18 — Customer Type channel options (mockup) — **ยกเลิก**

- ~~`CUSTOMER_TYPES`: End User …~~ → revert ใน `20260608120080_*` · ย้ายไป `lead_type` แทน

### 2026-06-18 — Leads i18n polish (th + en)

- แปล `leads.*` ครบ — สถานะ · คะแนน · คอลัมน์ · ประเภทลีด · เมนู

### 2026-06-18 — Lead status catalog (8 statuses)

- **สถานะ:** NEW · OPEN · CONTACTED · NURTURING · QUALIFIED · UNQUALIFIED · CANCELLED · CONVERTED
- **Migration:** `20260608120077_lead_status_catalog.sql` · i18n `leads.statusCodes.*`

### 2026-06-18 — Leads score UI polish

- **`LeadsScoreControl`** — ring gauge · gradient slider · tier legend · quick presets
- **`LeadsScoreBadge`** — progress ring ใน list/grid

### 2026-06-18 — Leads customer section (existing vs new)

- **โหมด:** ลูกค้าในระบบ (ค้นหา + readonly) · ลูกค้าใหม่ (ฟอร์มสร้างลูกค้า + validate + create ก่อนบันทึกลีด)
- **ไฟล์:** `LeadsCustomerSection.vue` · reuse `MasterDataCustomerForm`
- **fix:** import `CUSTOMER_*` จาก `config/masterCustomer` (build error)

### 2026-06-18 — Leads form pulls from customer + contact

- **ฟอร์ม:** เลือกลูกค้า/ผู้ติดต่อ → auto-fill ข้อมูลทั่วไป · `contact_id` บน `leads`
- **Migration:** `20260608120076_leads_contact_id.sql`

### 2026-06-18 — Leads module v1 (frontend + migration)

- **Route:** `/app/leads` · `/app/leads/new` · `/app/leads/:id/edit`
- **DB:** `20260608120075_leads_module.sql` — table `leads` · RPC CRUD · seed module `lead`
- **ไฟล์:** `components/leads/*`, `useLeads.ts`, `masterLeads.ts`, i18n `leads.*`

### 2026-06-08 — Tasks priority badge smaller text

- **UX:** badge ความสำคัญ — `text-xs` · padding/มุมโค้งกะทัดรัดขึ้น
- **ไฟล์:** `TasksPriorityBadge.vue`

### 2026-06-08 — Tasks assign target team OR person

- **UX:** มอบหมายให้ — สลับทีมขาย / บุคคล (เลือกได้อย่างใดอย่างหนึ่ง) · ตาราง/การ์ดแสดงชื่อทีมเมื่อมอบให้ทีม
- **ไฟล์:** `TasksFormModal.vue`, `masterTasks.ts`, `tasks.vue`, `TasksTaskCard.vue`

### 2026-06-08 — Tasks form sales team

- **UX:** ฟอร์มสร้าง/แก้ไขงาน — เลือกทีมขาย · กรองผู้รับผิดชอบตามสมาชิกทีม
- **DB:** `tasks.sales_team_id` · migration `20260608120074_tasks_sales_team.sql`
- **ไฟล์:** `TasksFormModal.vue`, `tasks.vue`, `masterTasks.ts`, `crm.ts`

### 2026-06-08 — Tasks actions column header

- **UX:** คอลัมน์การทำงาน — ไม่แสดงหัวข้อใน header · ปุ่มชิดขวา (`align="right"`)
- **ไฟล์:** `tasks.vue`

### 2026-06-08 — Tasks table row truncate + semibold

- **UX:** หัวของ truncate ไม่ล้นคอลัมน์ · `table-fixed` + กำหนดความกว้าง · ทั้งแถว `font-semibold`
- **ไฟล์:** `tasks.vue`, `appTableRowClass`, task cell components

### 2026-06-08 — Tasks table typography unify

- **UX:** ชื่อ · ลูกค้า · ผู้ติดต่อ · ความสำคัญ — ใช้ `appTableTextClass` (IBM Plex 400) เดียวกัน · priority ไม่ใช้ UBadge
- **ไฟล์:** `appFormUi.ts`, `TasksPriorityBadge`, `TasksCustomerLink`, `TasksContactCell`, `tasks.vue`

### 2026-06-08 — Tasks priority badge solid style

- **UX:** ความสำคัญ — badge ใหญ่ขึ้น · พื้นเข้ม · ตัวอักษรขาว
- **ไฟล์:** `TasksPriorityBadge.vue`, `TASK_PRIORITY_SOLID_COLORS`

### 2026-06-08 — Tasks quick status change action

- **UX:** ปุ่มธงในคอลัมน์การทำงาน + การ์ด → modal เปลี่ยนสถานะอย่างเดียว (ไม่เปิดฟอร์มแก้ไขเต็ม)
- **ไฟล์:** `TasksStatusChangeModal.vue`, `tasks.vue`, `TasksTaskCard.vue`

### 2026-06-08 — Tasks list priority colors + contact phone + assigner

- **UX:** ความสำคัญสีแยก (สูง/กลาง/ต่ำ) · คอลัมน์ผู้ติดต่อ+เบอร์ · ผู้มอบหมาย + ผู้รับผิดชอบ
- **ไฟล์:** `TasksPriorityBadge.vue`, `TasksContactCell.vue`, `tasks.vue`, `TasksTaskCard.vue`

### 2026-06-08 — Tasks customer info dialog from table/card

- **UX:** คลิกชื่อลูกค้าใน table/card → dialog โทร · อีเมล · ที่อยู่ · รายชื่อผู้ติดต่อ · ลิงก์โปรไฟล์ลูกค้า
- **ไฟล์:** `TasksCustomerLink.vue`, `TasksCustomerInfoDialog.vue`, `tasks.vue`, `TasksTaskCard.vue`

### 2026-06-08 — Tasks activity type colors

- **UX:** สีแยกประเภทงาน (งาน/โทร/อีเมล/ประชุม/เยี่ยม) — filter · ตาราง · การ์ด · ฟอร์ม · dialog ปฏิทิน
- **ไฟล์:** `masterTasks.TASK_TYPE_COLORS`, `TasksTypeIcon`, `TasksTypeBadge`

### 2026-06-08 — Tasks list date range filter

- **UX:** แทน filter ปี/เดือน/วัน — ช่วงวันที่ (ตั้งแต่–ถึง) ต่อท้ายช่องค้นหา · default เดือนปัจจุบัน
- **ไฟล์:** `tasks.vue`, `AppDateRangeFilter.vue`, `masterTasks.taskMatchesDateRange`

### 2026-06-08 — Tasks calendar day chip redesign

- **UX:** ช่องวันที่มีงาน — ขอบ/พื้นหลัง primary · badge ตัวเลขมุมขวา · ปุ่มเต็มความกว้างด้านล่าง (icon + จำนวน) · วันนี้เน้นวงกลม primary
- **ไฟล์:** `TasksCalendar.vue`

### 2026-06-08 — Tasks list schedule filters (year / month / start date)

- **UX:** กรอง list/table/grid ตามปี · เดือน · วันเริ่ม (`start_at`) · default ปีปัจจุบัน
- **ไฟล์:** `tasks.vue`, `masterTasks.taskMatchesScheduleFilters`

### 2026-06-08 — Tasks calendar count chip + day dialog

- **UX:** ปฏิทินแสดง chip จำนวนงานตามวันเริ่ม · dialog รายการพร้อมวันสิ้นสุด · กดเปิดแก้ไข
- **ไฟล์:** `TasksCalendar.vue`, `TasksCalendarDayDialog.vue`

### 2026-06-08 — Task status change log datetime

- **UX:** บันทึกเปลี่ยนสถานะใช้ `datetime-local` (วัน+เวลา) · default = ตอนเปลี่ยนสถานะ · แสดง preview `formatDateTime`

### 2026-06-08 — Task status change log UX

- **UX:** บันทึกเฉพาะการเปลี่ยนสถานะจริง + วันที่ · ไม่ใช่ stepper ครบทุกสถานะ · `TasksStatusChangeLog.vue`
- **DB:** migration `20260608120073_task_status_history_changelog.sql`

### 2026-06-08 — Task status timeline in form

- **UX:** ลำดับสถานะตาม Master Data · ระบุวันที่แต่ละขั้น · เปลี่ยนสถานะบันทึกอัตโนมัติ
- **ไฟล์:** `TasksStatusTimeline.vue`, `TasksFormModal.vue`, `useTasks.listStatusHistory`
- **DB:** migration `20260608120072_task_status_history.sql`

### 2026-06-08 — Tasks show end date in list views

- **UX:** ตาราง/grid card แสดงวันเริ่ม + วันสิ้นสุด · ปฏิทินแสดงช่วงวันที่บน chip และโผล่ทั้งวันเริ่ม/วันสิ้นสุด
- **ไฟล์:** `tasks.vue`, `TasksTaskCard.vue`, `TasksCalendar.vue`, `useFormat.formatDate`, `masterTasks.taskCalendarDateKeys`

### 2026-06-08 — Tasks dynamic statuses (Master Data)

- **UX:** การ์ดสรุป/list tab จาก `module_statuses` ที่ active (ไม่ hardcode 4 สถานะ) · default สร้างงาน = `is_default` · แก้ไขงานที่สถานะ inactive ยังเลือกสถานะเดิมได้
- **Master Data:** ลบสถานะถูกบล็อกเมื่องานยังใช้อยู่ — ตั้ง inactive แทน · i18n `masterData.moduleStatuses.validation.inUseByTasks`
- **ไฟล์:** `utils/masterTasks.ts`, `TasksSummaryCards.vue`, `tasks.vue`, `TasksFormModal.vue`, `utils/masterModuleStatus.ts`
- **DB:** migration `20260608120071_module_status_block_delete_tasks.sql`

### 2026-06-08 — Tasks default table view

- **UX:** หน้า `/app/tasks` เปิดมาเป็นมุมมองตาราง (table) แทน grid

### 2026-06-08 — Task status i18n display

- **i18n:** แสดงชื่อสถานะจาก `tasks.statusCodes.*` ตาม locale (ไม่ใช้ชื่อ EN จาก DB) · `useTaskStatusLabel`
- **th:** เปิดอยู่ · กำลังดำเนินการ · เสร็จสิ้น · ยกเลิกแล้ว

### 2026-06-08 — Fix task status dropdown empty (list_tasks read-only)

- **Root cause:** `list_tasks` STABLE เรียก INSERT → error → `Promise.all` ล้าง statuses ทั้งที่ DB มี 4 สถานะแล้ว
- **Fix:** แยกโหลด statuses จาก `list()` · migration `20260608120070_fix_list_tasks_readonly.sql`

### 2026-06-08 — Task status lazy seed fix

- **Fix:** เรียก `ensure_task_module_defaults` ก่อนโหลดสถานะ (กัน race ใน `Promise.all`)
- **UX:** ข้อความใน modal เมื่อยังไม่มีสถานะ · i18n `tasks.statusesMissing`

### 2026-06-08 — Tasks form modal layout

- **UX:** flow แนวตั้ง — ประเภท+หัวข้อ → กำหนดการ/สถานะ → ผู้รับผิดชอบ/ลูกค้า → รายละเอียด · select ค้นหาได้
- **ไฟล์:** `components/tasks/TasksFormModal.vue`, i18n `tasks.createSubtitle`, `tasks.sections.schedule|related`

### 2026-06-08 — Modal overlay ดำ fade

- **UI:** พื้นหลัง modal ทั้งระบบ `bg-black/60` + fade in/out (ผ่าน `app.config.ts` + `AppDialog`)

### 2026-06-08 — Tasks page UX pass

- **UX:** การ์ดสถานะคลิกกรอง · chip ประเภท · ตารางกระชับ · คลิกแถว/การ์ดแก้ไข · default grid
- **ไฟล์:** `pages/app/tasks.vue`, `TasksSummaryCards.vue`, `TasksTaskCard.vue`

### 2026-06-08 — AppViewModeToggle (table/card switcher)

- **ทำอะไร:** component กลางสลับมุมมอง · ใช้ใน roles, company profiles, tasks
- **ไฟล์:** `AppViewModeToggle.vue`, `config/appViewMode.ts`, `common.viewMode` i18n

### 2026-06-08 — Tasks module `/app/tasks` (Phase 2 v1)

- **ทำอะไร:** หน้างาน CRM แรก — สรุปสถานะ · แท็บ list · ปฏิทิน (view switcher) · Create/Edit modal 3 คอลัมน์ · i18n th/en
- **ไฟล์ที่กระทบ:** `pages/app/tasks.vue`, `components/tasks/*`, `composables/useTasks.ts`, `config/masterTasks.ts`, `config/appMenu.ts`, `AppSidebar.vue`, `locales/{th,en}.json`

### 2026-06-08 — แก้ build: import path supabaseRealtimeTransport

- **ทำอะไร:** `app/plugins/supabase.server.ts` → `../../build/supabaseRealtimeTransport` (SSR build ผ่าน)
- **ไฟล์ที่กระทบ:** `supabase.server.ts`

### 2026-06-08 — แก้ WARN duplicated `normalizeSelectValue` imports

- **ทำอะไร:** รวม helper ไป `utils/normalizeSelectValue.ts` · ลบ export ซ้ำจาก master utils 6 ไฟล์
- **ไฟล์ที่กระทบ:** `normalizeSelectValue.ts`, `masterCategory.ts`, `masterUnit.ts`, …, form components

### 2026-06-08 — Master Data menu Phase 1 complete

- **ทำอะไร:** ครบ 11 เมนู · ไม่มี Coming soon badge · sidebar เปิดข้อมูลหลักค่าเริ่มต้น · legacy `/app/master-data/*` redirect
- **ไฟล์ที่กระทบ:** `masterDataMenu.ts`, `AppSidebar.vue`, `pages/app/master-data/*`, docs

### 2026-06-08 — Job code master (`/app/job-code`)

- **Route:** `/app/job-code` · แท็บโมดูลซ้าย + ฟอร์มขวา (query `?module=`)
- **Migration:** `20260608120067_job_code_sequences.sql`
- **Frontend:** `useJobCodes()` · `MasterDataJobCode*` · preview สด

### 2026-06-08 — Module status code validation (UPPER_SNAKE_CASE)

- **ทำอะไร:** `status_code` บังคับตัวใหญ่ · พิมพ์เล็กแปลงอัตโนมัติ · validate ตาม org role pattern (กลับด้าน) · migration `20260608120066`
- **ไฟล์ที่กระทบ:** `utils/moduleStatusCode.ts`, `MasterDataModuleStatusForm.vue`, i18n th/en

### 2026-06-08 — Module statuses master (`/app/module-status`)

- **Route:** `/app/module-status` · แท็บโมดูลซ้าย + รายการขวา (query `?module=`) · เพิ่มสถานะ `/module/:moduleKey/new` (ล็อกโมดูล)
- **Migration:** `20260608120065_module_statuses.sql`
- **Frontend:** `useModuleStatuses()` · `loadSelectOptions()` · `MasterDataModuleStatus*`

### 2026-06-08 — Sales team master (`/app/sales-team`)

- **Route:** `/app/sales-team` · CRUD + archive tabs · สมาชิกหลายคนจากผู้ใช้งานในระบบ
- **Migration:** `20260608120064_sales_teams.sql`
- **Frontend:** `useSalesTeams()` · `MasterDataSalesTeam*` · `AppProfileChipSelect`

### 2026-06-08 — ยกเลิก Employee position + Employee master menu

- **เหตุผล:** ใช้ **Setup → ผู้ใช้งานในระบบ** (`/app/setup/system-users`) แทน
- **Migration:** `20260608120063_drop_employee_position_master.sql` — drop table/RPC · ลบ permission `master.employeePosition` / `master.employee`
- **Frontend:** ลบ route `/app/employee-position` · menu · i18n · components

### 2026-06-08 — Employee position master (`/app/employee-position`) (ยกเลิกแล้ว)

- **Route:** `/app/employee-position` · CRUD + archive tabs · redirect จาก `/app/master-data/employee-position`
- **Migration:** `20260608120061_employee_positions.sql` · `20260608120062_employee_position_permissions.sql`
- **สถานะ:** superseded โดย migration 63

### 2026-06-08 — Partner form aligned with legacy CRM

- **Migration:** `20260608120060_partners_legacy_fields.sql`
- **UI:** Partner Info + Contact Details (type, tier, partner since, contact, commission)
- **List:** ชื่อบริษัท · ประเภท · ระดับ · สถานะ

### 2026-06-08 — Partner master (`/app/partner`)

- **Route:** `/app/partner` · CRUD + archive tabs · redirect จาก `/app/master-data/partner`
- **Migration:** `20260608120058_partners.sql` · `20260608120059_partner_permissions.sql`
- **Frontend:** `usePartners()` · `MasterDataPartner*` · sidebar + i18n th/en
- **Docs:** `PARTNER-MASTER-FIELDS.md`

### 2026-06-08 — Lead source master (`/app/lead-source`)

- **Route:** `/app/lead-source` · CRUD + archive tabs · redirect จาก `/app/master-data/lead-source`
- **Migration:** `20260608120056_lead_sources.sql` (+ `57` ถ้ารัน variant เก่า)
- **Frontend:** `useLeadSources()` · `MasterDataLeadSource*` · **องค์กรกำหนดเอง** (ไม่มี seed ค่าเริ่มต้น) · ใช้กับ Lead ในอนาคต
- **i18n:** `masterData.leadSource.*` (th + en)

### 2026-06-08 — Product gallery layout: below notes, wide box

- **UI:** ย้าย `AppProductGalleryUpload` ใต้หมายเหตุ (full width) · drop zone แนวนอน · thumbnails แถวเลื่อน

### 2026-06-08 — Product gallery images (multi-upload + drag reorder)

- **Route:** edit/view product sidebar · `AppProductGalleryUpload`
- **Migration:** `20260608120055_product_gallery_images.sql` · table `product_gallery_images` + RPC
- **Storage:** `org-images/{org_id}/products/{id}/gallery/{image_id}.webp` · max 20 images
- **Composable:** `useProductGallery()` · ลบ gallery เมื่อ soft delete สินค้า

### 2026-06-08 — Product form: inline create category / unit dialogs

- **UI:** ปุ่ม `+` ข้าง dropdown หมวด/หน่วยในหน้า new/edit สินค้า
- **Dialog:** `MasterDataCategoryFormModal` · `MasterDataUnitFormModal` (hoist ที่ page level)
- **หลังสร้าง:** refresh options และเลือกรายการใหม่ให้อัตโนมัติ

### 2026-06-08 — Unit master + products.unit_id FK

- **Route:** `/app/unit` · CRUD + archive tabs · redirect จาก `/app/master-data/unit`
- **Migration:** `20260608120053_units.sql` · `20260608120054_products_unit_id.sql`
- **Frontend:** `useUnits()` · `MasterDataUnit*` · สินค้าเลือกหน่วยจาก USelectMenu
- **Docs:** `UNIT-MASTER-FIELDS.md` · `PRODUCT-MASTER-FIELDS.md`

### 2026-06-08 — Product main image upload

- **รูปหลัก:** `AppProductImageUpload` + `useProductImage()` · preset `productImage` (WebP max 800px)
- **Storage:** `org-images/{org_id}/products/{id}.webp` · ลบไฟล์เมื่อ soft delete
- **Migration:** `20260608120052_product_image.sql` · column `products.image_url`

### 2026-06-08 — Products link to categories (category_id FK)

- **ประเภท:** migration `20260608120051_products_category_id.sql`
- **ทำอะไร:** `category_id` FK · ลบคอลัมน์ `category` text · migrate ข้อมูลเดิม · block ลบหมวดถ้ามีสินค้า
- **Frontend:** USelectMenu หมวด · แสดงรูป/ลิงก์หมวดใน list/view

### 2026-06-08 — Category main image upload

- **รูปหลัก:** `AppCategoryImageUpload` + `useCategoryImage()` · preset `categoryImage` (WebP max 640px)
- **Storage:** `org-images/{org_id}/categories/{id}.webp` · ลบไฟล์เมื่อ soft delete
- **Migration:** `20260608120050_category_image.sql` · column `categories.image_url`

### 2026-06-08 — fix category save error [object Object]

- **สาเหตุ:** Supabase PostgrestError ไม่ใช่ `Error` · `String(error)` → `[object Object]`
- **แก้:** `getSupabaseErrorMessage` ใน `categorySaveErrorMessage` · ลบ embed FK ใน `useCategories` (self-ref PGRST)

### 2026-06-08 — Master Data Category UI

- **Route:** `/app/category` · hierarchy + color · archive tabs
- **Migration:** `20260608120049_categories.sql`
- **Docs:** `CATEGORY-MASTER-FIELDS.md`

### 2026-06-08 — Master Data Products (CRUD)

- **Route:** `/app/product` · redirect จาก `/app/master-data/products`
- **Migration:** `20260608120048_products.sql`
- **Components:** `MasterDataProduct*` · `useProducts` · `masterProduct.ts`

### 2026-06-17 — Charts: nuxt-charts + AppLineChart

- **Lib:** `nuxt-charts` (vue-chrts) · docs `docs/05-frontend/CHARTS.md`
- **Component:** `AppLineChart` + `config/appChart.ts` · เป้ายอดขายใช้แทน SVG จำลอง

### 2026-06-17 — กราฟเส้นความคืบหน้า (จำลองวันปิดดีล)

- **ทำอะไร:** SVG line chart ในหน้าดูเป้า · จำลองยอดสะสมตาม `current_amount` · จุดวันปิดดีล + รายการด้านล่าง

### 2026-06-17 — fix หน้า sales-target detail/edit ไม่มี app layout

- **สาเหตุ:** `[id]/index.vue` และ `[id]/edit.vue` ไม่มี `definePageMeta({ layout: 'app' })` — ไม่แสดง sidebar/header
- **แก้:** เพิ่ม page meta + `ensureProfile` · sidebar เปิด section ข้อมูลหลักเมื่ออยู่ customer/contact/sales-target

### 2026-06-17 — หน้าดูเป้ายอดขาย: layout มาตรฐาน master-data

- **ทำอะไร:** `MasterDataSalesTargetForm` readonly + `AppFormSection` 2 คอลัมน์ · sidebar sticky แบบ customer/contact

### 2026-06-17 — รอบเป้า: ข้อความอ่านง่ายขึ้น

- **ทำอะไร:** หัวคอลัมน์ «รอบเป้า» · แสดง «พฤศจิกายน 2028» / «ไตรมาสที่ 4 ปี 2028» / «เป้าประจำปี …» แทน `11/2028`

### 2026-06-17 — ตารางเป้ายอดขาย: icon actions ตาม master-data

- **ทำอะไร:** eye / pencil / trash / restore แบบ customer·contact · `aria-label` · restore สี primary

### 2026-06-17 — ตารางเป้ายอดขาย: progress bar + header

- **ทำอะไร:** คอลัมน์ความคืบหน้าแสดง `UProgress` · ไม่มีหัวคอลัมน์การดำเนินการ · label `progress` แทน `achievement`

### 2026-06-17 — fix บันทึกเป้ายอดขาย (PGRST201)

- **สาเหตุ:** `select('*, profiles(...)')` ambiguous — FK สองเส้น (`profile_id`, `created_by`)
- **แก้:** `profiles!sales_targets_profile_id_fkey` ใน `useSalesTargets` · ข้อความ duplicate period · icon ฟอร์ม

### 2026-06-17 — sales_targets current_amount (manual)

- **ทำอะไร:** คอลัมน์ `current_amount` · RPC create/update · UI เป้าหมาย + ยอดปัจจุบัน (ยังไม่ผูกดีล)
- **Migration:** `20260608120047_sales_targets_current_amount.sql`

### 2026-06-17 — เป้ายอดขาย (Sales targets)

- **ทำอะไร:** Master data เป้ารายคน × เดือน/ไตรมาส/ปี · ผลจริงจากดีล Won · archive tabs
- **Route:** `/app/sales-target` · migration `20260608120046_sales_targets.sql`
- **Spec:** `docs/06-crm-schema/SALES-TARGET-MASTER-FIELDS.md`

### 2026-06-17 — กิจกรรมผู้ใช้: รายละเอียดอ่านง่าย

- **ทำอะไร:** แทน JSON ดิบด้วยตารางฟิลด์/ก่อน-หลัง · i18n ชื่อฟิลด์ · ปุ่มแสดง JSON ดิบ
- **ไฟล์:** `SetupDataChangeLogDetails.vue` · `utils/dataChangeLogDisplay.ts` · `user-activity.vue`

### 2026-06-17 — ผู้ติดต่อหลัก 1 คนต่อลูกค้า

- **ทำอะไร:** hint ใต้ checkbox · RPC ยกเลิกคนเดิมอัตโนมัติ (migration 45)
- **i18n:** `mainContactHint` th + en

### 2026-06-17 — แท็บ ถูกลบ owner/admin เท่านั้น

- **ทำอะไร:** `canViewDeletedRecords` · `AppArchiveTabs` + `useArchiveTabs` · RLS + restore RPC จำกัด admin/owner
- **Migration:** `20260608120044_deleted_records_admin_only.sql`

### 2026-06-17 — หน้าดูลูกค้า: panel ผู้ติดต่อ + modal เพิ่มทันที

- **ทำอะไร:** panel รายชื่อผู้ติดต่อ · `MasterDataContactFormModal` ลูกค้าถูก lock ไม่ต้อง select
- **ไฟล์:** `MasterDataCustomerViewPage.vue` · `MasterDataContactFormModal.vue` · `MasterDataContactForm.vue`

### 2026-06-17 — Tab ถูกลบ + กู้คืน (restore)

- **ทำอะไร:** แท็บ Active/Deleted บน list ลูกค้าและผู้ติดต่อ · `restore_company` cascade กู้ผู้ติดต่อ · modal กู้คืน
- **Migration:** `20260608120043_restore_master_data.sql`
- **UI:** `/app/customer` · `/app/contact`

### 2026-06-17 — Fix soft_delete ต้องมี contact_log_snapshot

- **สาเหตุ:** migration 41 เรียก `contact_log_snapshot` แต่ migration 39 ยังไม่รันบน DB → ลบลูกค้าที่มีผู้ติดต่อผูกอยู่ error
- **Migration:** `20260608120042_fix_soft_delete_contact_snapshot.sql`
- **UI:** แสดงข้อความ error จาก Supabase ใน modal ลบลูกค้า

### 2026-06-17 — ลบลูกค้า cascade ผู้ติดต่อ

- **ทำอะไร:** `soft_delete_company` soft delete contacts ที่ผูก `company_id` · trigger กัน contact ชี้ลูกค้าที่ลบแล้ว
- **Migration:** `20260608120041_soft_delete_company_cascade_contacts.sql`
- **Phase:** 1

### 2026-06-17 — Customer CRUD RPC + Contact delete UI + DB-SCHEMA sync

- **ทำอะไร:** `create_company` / `update_company` + logs · ปุ่มลบ contact · sync DB-SCHEMA
- **Migration:** `20260608120040_companies_crud_rpc.sql`
- **Phase:** 1

### 2026-06-16 — Contact data_change_logs (RPC)

- **ทำอะไร:** `create_contact` / `update_contact` / `soft_delete_contact` → `data_change_logs` · `useContacts` เรียก RPC
- **Migration:** `20260608120039_contacts_crud_rpc.sql`
- **Phase:** 1

### 2026-06-16 — Contact list filter by customer (autocomplete)

- **ทำอะไร:** หน้ารายการผู้ติดต่อ — USelectMenu searchable กรองตามบริษัท/ลูกค้า
- **ไฟล์ที่กระทบ:** `pages/app/contact/index.vue`, i18n
- **Phase:** 1

### 2026-06-16 — Contact master UI + customer FK

- **ทำอะไร:** `/app/contact` list/new/view/edit · `company_id` required · migration `20260608120038_*`
- **Spec:** `docs/06-crm-schema/CONTACT-MASTER-FIELDS.md`
- **Phase:** 1

### 2026-06-16 — Sidebar inactive nav font (weight 400)

- **ทำอะไร:** เมนูไม่ active ใช้ `font-normal` (400) แทน `font-medium` (500) — IBM Plex โหลดแค่ 400/600
- **ไฟล์ที่กระทบ:** `AppSidebarNavItem.vue`, `main.css`
- **Phase:** 1

### 2026-06-16 — Tax section layout (WHT + credit ติดกัน)

- **ทำอะไร:** ย้าย WHT ไปคอล. 3 แถว 2 · วงเงินเครดิต + เครดิตคงเหลือ อยู่แถวล่างติดกัน
- **ไฟล์ที่กระทบ:** `MasterDataCustomerForm.vue`, `CUSTOMER-MASTER-FIELDS.md`
- **Phase:** 1

### 2026-06-16 — tax_vat → อัตราหัก ณ ที่จ่าย (WHT)

- **ทำอะไร:** เปลี่ยน dropdown จาก VAT 7%/0% เป็น WHT · slug `none`, `wht_3`, `wht_5`, `wht_0_5`, `wht_0_75`, `wht_1`, `wht_1_5`, `wht_2`, `wht_10`, `wht_15`
- **Migration:** `20260608120037_companies_tax_vat_wht_rates.sql`
- **Phase:** 1

### 2026-06-16 — Sidebar font ตรง content (IBM Plex Sans Thai)

- **ทำอะไร:** บังคับ `--font-sans` บน sidebar/header · แก้ `<button>` ไม่ inherit · ขนาดตัวอักษร nav ใช้ `appSidebarNavTextClass`
- **ไฟล์ที่กระทบ:** `main.css`, `AppSidebar*.vue`, `AppHeader.vue`, `appFormUi.ts`
- **Phase:** 1

### 2026-06-16 — Tax VAT dropdown

- **ทำอะไร:** `tax_vat` เป็น USelectMenu · slug `vat_7` / `vat_0` / `exempt` / `no_vat`
- **ไฟล์ที่กระทบ:** `masterCustomer.ts`, `MasterDataCustomerForm.vue`, `i18n`, migration `20260608120036_*`
- **Phase:** 1

### 2026-06-16 — Bill To: หลายที่อยู่ + default

- **ทำอะไร:** `company_bill_addresses` · UI เหมือน Ship To · `MasterDataCustomerAddressList`
- **ไฟล์ที่กระทบ:** migration `20260608120035_*`, `useCompanies.ts`, `MasterDataCustomerForm.vue`
- **Phase:** 1

### 2026-06-16 — Customer list: คอลัมน์ประเภท/โทร/email/เกรด/กลุ่มอุตสาหกรรม

- **ทำอะไร:** ขยายตารางหน้ารายการลูกค้า
- **ไฟล์ที่กระทบ:** `pages/app/customer/index.vue`
- **Phase:** 1

### 2026-06-16 — Individual customer: ล็อก segment + industry

- **ทำอะไร:** ประเภทบุคคลธรรมดา → กลุ่มอุตสาหกรรม = รายบุคคล · อุตสาหกรรม = ไม่ระบุ · CHECK ใน DB
- **ไฟล์ที่กระทบ:** `masterCustomer.ts`, `MasterDataCustomerForm.vue`, migration `20260608120034_*`
- **Phase:** 1

### 2026-06-16 — Ship To default address

- **ทำอะไร:** `is_default` ต่อ company · UI badge/ดาว/checkbox · RPC สำหรับโมดูลอื่น
- **ไฟล์ที่กระทบ:** migration `20260608120033_*`, `MasterDataCustomerForm.vue`, `useCompanies.ts`
- **Phase:** 1

### 2026-06-16 — Customer view + soft delete + log

- **ทำอะไร:** ดูรายละเอียด (คลิกชื่อ/ปุ่มตา) · ลบ soft delete ผ่าน RPC + `data_change_logs`
- **ไฟล์ที่กระทบ:** `MasterDataCustomerViewPage.vue`, routes `[id]/`, migration `20260608120032_*`
- **Phase:** 1

### 2026-06-16 — Customer master: migration + บันทึกครบฟิลด์

- **ทำอะไร:** รองรับคอลัมน์ companies ใหม่ + ship addresses · ลบ layout-only hint
- **ไฟล์ที่กระทบ:** `masterCustomer.ts`, `useCompanies.ts`, `MasterDataCustomerPage.vue`, `crm.ts`, `i18n`
- **Phase:** 1 · ต้องรัน migration `20260608120031_*` ก่อน

### 2026-06-16 — Customer website: auto https://

- **ทำอะไร:** `normalizeWebsiteUrl` — blur + ตอนบันทึก เติม `https://` ถ้าผู้ใช้ไม่ใส่ scheme
- **ไฟล์ที่กระทบ:** `utils/websiteUrl.ts`, `masterCustomer.ts`, `MasterDataCustomerForm.vue`
- **Phase:** 1

### 2026-06-16 — Customer Tax & Payment section ตาม mockup

- **ทำอะไร:** grid 3 คอล · Payment Code ลำดับ transfer/credit/cash/cheque · VAT dropdown · credit ชิดขวา
- **ไฟล์ที่กระทบ:** `MasterDataCustomerForm.vue`, `masterCustomer.ts`, `i18n`, `CUSTOMER-MASTER-FIELDS.md` §6
- **Phase:** 1

### 2026-06-16 — Customer Owner: dropdown + spec §5

- **ทำอะไร:** เลือกพนักงานจาก profiles (active ใน org) · บันทึก `owner_id` · จด MD รอ confirm rules
- **ไฟล์ที่กระทบ:** `MasterDataCustomerForm.vue`, `CUSTOMER-MASTER-FIELDS.md`, `i18n/en.json`
- **Phase:** 1

### 2026-06-16 — Customer Status dropdown (5 lifecycle values)

- **ทำอะไร:** active · inactive · prospect · churned · pending · USelectMenu · tabs/badge หน้ารายการ · migration DB
- **ไฟล์ที่กระทบ:** `masterCustomer.ts`, `MasterDataCustomerForm.vue`, `customer/index.vue`, `i18n`, migration `20260608120030_*`
- **Phase:** 1

### 2026-06-16 — Customer Sales Grade dropdown ตาม mockup

- **ทำอะไร:** vip · A · B · C · Prospect (รูปแบบ Code — Description) · ลบเกรด D
- **ไฟล์ที่กระทบ:** `masterCustomer.ts`, `MasterDataCustomerForm.vue`, `i18n/locales/*`, `CUSTOMER-MASTER-FIELDS.md`
- **Phase:** 1

### 2026-06-16 — Customer Industry dropdown + spec MD

- **ทำอะไร:** เปลี่ยน Industry จาก text input เป็น USelectMenu 10 ตัวเลือก + slug ลง `companies.industry`
- **ไฟล์ที่กระทบ:** `masterCustomer.ts`, `MasterDataCustomerForm.vue`, `i18n/locales/*`, `customer/index.vue`
- **Docs:** `docs/06-crm-schema/CUSTOMER-MASTER-FIELDS.md`
- **Phase:** 1

### 2026-06-16 — Customer Industry Segment options ตาม mockup

- **ทำอะไร:** เปลี่ยนเป็น Enterprise · SME · Startup · Individual (ลำดับตาม dropdown)
- **ไฟล์ที่กระทบ:** `config/masterCustomer.ts`, `i18n/locales/*`, `MasterDataCustomerForm.vue`
- **Phase:** 1

### 2026-06-16 — Customer form: แปล th ครบ + placeholder i18n

- **ทำอะไร:** ฟอร์มเพิ่ม/แก้ไขลูกค้า — sections, fields, options ภาษาไทย · ลบ hardcode placeholder
- **ไฟล์ที่กระทบ:** `i18n/locales/*`, `MasterDataCustomerForm.vue`
- **Phase:** 1

### 2026-06-16 — Customer list UI แบบ system-users (หน้า new/edit แยก)

- **ทำอะไร:** filter card + status tabs + ตาราง/pagination เหมือนผู้ใช้ในระบบ · เพิ่ม/แก้ไขเปิดหน้า `/new` และ `/:id` (ไม่ใช่ modal)
- **ไฟล์ที่กระทบ:** `pages/app/customer/*`, `MasterDataCustomerPage.vue`
- **Phase:** 1

### 2026-06-16 — Customer route `/app/customer` + filter UI แบบ users

- **ทำอะไร:** ย้ายออกจาก `/app/master-data/customer` · filter card + status tabs + ตารางเหมือน system-users
- **ไฟล์ที่กระทบ:** `pages/app/customer/*`, `masterDataMenu.ts`, `MasterDataCustomerPage.vue`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-16 — IBM Plex Sans Thai ทั้งระบบ

- **ทำอะไร:** `--font-sans` / `--font-heading` = IBM Plex Sans Thai · Google Fonts 400 + 600
- **ไฟล์ที่กระทบ:** `main.css`, `app.vue`
- **Phase:** 1

### 2026-06-16 — Master Data Customer: layout ฟอร์มครบ

- **ทำอะไร:** หน้ารายการ + new/edit ฟอร์ม 4 section (General / Tax / Bill To / Ship To) อ้างอิง layout system-users · บันทึกเฉพาะคอลัมน์ `companies` ที่มีอยู่
- **ไฟล์ที่กระทบ:** `master-data/customer/*`, `MasterDataCustomerForm.vue`, `AppFormSection.vue`, `masterCustomer.ts`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — Settings: ตารางข้อมูลบริษัทแสดงโลโก้

- **ทำอะไร:** คอลัมน์โลโก้ในมุมมองตาราง — แสดงรูปที่อัปโหลด (fallback ไอคอน building)
- **ไฟล์ที่กระทบ:** `SettingsCompanyProfilesTab.vue`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — Supabase Realtime: WebSocket บน Node < 22

- **ทำอะไร:** ติดตั้ง `ws` + แทนที่ `@nuxtjs/supabase` server plugin ด้วย `app/plugins/supabase.server.ts` ส่ง `realtime.transport` ตรง (ห้ามใส่ function ใน `runtimeConfig.public`)
- **ไฟล์ที่กระทบ:** `build/supabaseRealtimeTransport.ts`, `app/plugins/supabase.server.ts`, `nuxt.config.ts`, `package.json`
- **Phase:** 1

### 2026-06-08 — Sidebar version จาก git commit

- **ทำอะไร:** แสดง `0.1.0 · fb58af4` ใน sidebar — อ่าน `git rev-parse --short HEAD` ตอน `dev`/`build`; CI ใช้ `NUXT_PUBLIC_GIT_COMMIT` ได้
- **ไฟล์ที่กระทบ:** `scripts/gitBuildInfo.mjs`, `nuxt.config.ts`, `useAppBuildInfo.ts`, `AppSidebarVersion.vue`, `appVersion.ts`
- **Phase:** 1

### 2026-06-08 — Settings: Auth Providers tab (ครบ 4 แท็บ)

- **ทำอะไร:** แท็บผู้ให้บริการเข้าสู่ระบบ — Microsoft 365 / Google / Azure AD / Username&Password; toggle + configure modal; tips
- **ไฟล์ที่กระทบ:** `SettingsAuthProvidersTab.vue`, `SettingsAuthProviderFormModal.vue`, `useOrgAuthProviders.ts`, `settings.vue`, `i18n/locales/*`
- **DB:** `20260608120029_org_auth_providers.sql`
- **Phase:** 1

### 2026-06-08 — Settings: Email Service (SMTP) tab

- **ทำอะไร:** แท็บบริการอีเมล — ฟอร์ม SMTP, บันทึก `settings.email`, ทดสอบการเชื่อมต่อ (validate Phase 1)
- **ไฟล์ที่กระทบ:** `SettingsEmailTab.vue`, `useOrgEmailSettings.ts`, `orgEmailSettings.ts`, `settings.vue`, `i18n/locales/*`
- **DB:** `20260608120028_org_email_settings.sql`
- **Phase:** 1

### 2026-06-08 — Settings: Notifications tab

- **ทำอะไร:** แท็บการแจ้งเตือน — toggle 6 ประเภท + ปุ่มส่งอีเมล (guard จนกว่า Email Service พร้อม)
- **ไฟล์ที่กระทบ:** `SettingsNotificationsTab.vue`, `useOrgNotificationSettings.ts`, `orgNotificationSettings.ts`, `settings.vue`, `i18n/locales/*`
- **DB:** `20260608120027_org_notification_settings.sql`
- **Phase:** 1

### 2026-06-08 — Image upload กลาง + โลโก้บริษัท

- **ทำอะไร:** `useImageUpload` / `useImageUploadState` / `AppImageUpload`; refactor avatar; อัปโหลดโลโก้ company profile
- **ไฟล์ที่กระทบ:** `config/imageUpload.ts`, `utils/imageUpload.ts`, `AppImageUpload.vue`, `useUserAvatar.ts`, `useOrgCompanyLogo.ts`, `SettingsCompanyProfileFormModal.vue`, `SystemUserFormModal.vue`
- **เอกสาร:** `docs/05-frontend/IMAGE-UPLOAD.md`
- **DB:** `20260608120026_org_images_storage.sql`
- **Phase:** 1

### 2026-06-08 — Settings: ข้อมูลบริษัท grid card + table toggle

- **ทำอะไร:** แท็บข้อมูลบริษัท — สลับมุมมองกล่อง (default) / ตาราง; card แสดงโลโก้ ชื่อ ภาษี สาขา ที่อยู่ ติดต่อ
- **ไฟล์ที่กระทบ:** `SettingsCompanyProfileCard.vue`, `SettingsCompanyProfilesTab.vue`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — Settings: ข้อมูลบริษัทหลายโปรไฟล์ (สาขา)

- **ทำอะไร:** แท็บข้อมูลบริษัท — รายการ + เพิ่ม/แก้ไข/ลบ หลาย company profile (สำนักงานใหญ่/สาขา); ตั้งค่าเริ่มต้นได้
- **ไฟล์ที่กระทบ:** `SettingsCompanyProfilesTab.vue`, `SettingsCompanyProfileFormModal.vue`, `useOrgCompanyProfiles.ts`, `orgCompanyProfile.ts`, `settings.vue`, `types/crm.ts`, `i18n/locales/*`
- **ลบ:** `SettingsCompanyInfoForm.vue`, `orgCompanyInfo.ts`
- **DB:** `20260608120025_org_company_profiles.sql`
- **Phase:** 1

### 2026-06-08 — Settings page: tabs + Company Info form

- **ทำอะไร:** `/app/setup/settings` — 4 แท็บ (ข้อมูลบริษัท / แจ้งเตือน / อีเมล / Auth); ฟอร์มข้อมูลบริษัท (superseded โดย multi-profile)
- **ไฟล์ที่กระทบ:** `settings.vue`, `SettingsTabSoon.vue`, `settingsTabs.ts`
- **DB:** `20260608120024_org_settings_company_info.sql`
- **Phase:** 1

### 2026-06-08 — sidebar: ปิด ข้อมูลหลัก / ตั้งค่าระบบ โดยค่าเริ่มต้น

- **ทำอะไร:** panel Master Data + Setup หุบไว้ — เปิดอัตโนมัติเฉพาะเมื่ออยู่ใน route ของ section นั้น
- **ไฟล์ที่กระทบ:** `AppSidebar.vue`
- **Phase:** 1

### 2026-06-08 — CRM scrollbar + menu ready badge

- **ทำอะไร:** scrollbar เล็กสีเขียวอ่อนใน `.crm-app`; `ready: true` สำหรับ active-sessions + user-approvals (เอา badge เร็ว ๆ นี้ออก)
- **กฎ:** `.cursor/rules/nuxt-frontend-pitfalls.mdc` §5 — หน้าพร้อมแล้วต้องตั้ง `ready: true` ใน menu config
- **ไฟล์ที่กระทบ:** `main.css`, `setupMenu.ts`, `SETUP-MENU.md`
- **Phase:** 1

### 2026-06-08 — app layout: sidebar scroll แยกจาก main

- **ทำอะไร:** ล็อกความสูง `h-dvh` — sidebar เลื่อนใน `nav` เอง เนื้อหาหลักเลื่อนใน `main` ไม่ scroll ทั้ง page
- **ไฟล์ที่กระทบ:** `layouts/app.vue`, `AppSidebar.vue`, `AppHeader.vue`, `assets/css/main.css`
- **Phase:** 1

### 2026-06-08 — Active Sessions: login / activity / ended columns

- **ทำอะไร:** แยกคอลัมน์ เข้าสู่ระบบ · ใช้งานล่าสุด · สิ้นสุด — logout แสดง `ended_at`; ปิด browser แสดง `last_seen` พร้อม (ประมาณ)
- **ไฟล์ที่กระทบ:** `active-sessions.vue`, `loginSessionDisplay.ts`, `types/crm.ts`, `i18n/locales/*`
- **DB:** `20260608120023_user_login_sessions_list_ended.sql`
- **Phase:** 1

### 2026-06-08 — Active Sessions page (Setup)

- **ทำอะไร:** หน้า `/app/setup/active-sessions` — ตาราง User / Device / Browser / IP / Last Login / Status; บันทึกเซสชันตอน login + heartbeat ใน app layout
- **ไฟล์ที่กระทบ:** `active-sessions.vue`, `useLoginSession.ts`, `userAgent.ts`, `login.vue`, `signup.vue`, `UserMenu.vue`, `layouts/app.vue`, `server/api/session/client-info.get.ts`, `i18n/locales/*`
- **DB:** `20260608120022_user_login_sessions.sql`
- **Phase:** 1

### 2026-06-08 — roles: org role code validation + hints

- **ทำอะไร:** validate รหัสบทบาทตอนสร้าง (ห้ามเว้นวรรค/ตัวใหญ่/ขีดกลาง, ต้องขึ้นต้นด้วยตัวอักษร, 2–49 ตัว) ตรงกับ DB constraint — ข้อความช่วย th/en
- **ไฟล์ที่กระทบ:** `utils/orgRoleCode.ts`, `OrgRoleFormModal.vue`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — roles: remove create-from-template UI

- **ทำอะไร:** เอา dropdown เทมเพลตออกจากฟอร์มเพิ่มบทบาท — สร้างบทบาทใหม่เป็น code + ชื่อ + สิทธิ์ว่างเท่านั้น; บทบาทระบบ 4 อันยัง seed จาก DB ตอนสร้าง org
- **สาเหตุ:** เทมเพลตซ้ำกับบทบาทที่ seed แล้ว และชน unique code
- **ไฟล์ที่กระทบ:** `OrgRoleFormModal.vue`, `config/orgRoleTemplates.ts`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — fix OrgRoleFormModal empty dialog (add role)

- **ทำอะไร:** แก้ `OrgRoleFormModal` / `OrgRoleDeleteModal` — ใช้ default slot ของ `AppDialog` (เดิม `#body` ไม่แสดงเนื้อหา); `AppDialog` รองรับ `#body` fallback
- **สาเหตุ:** `AppDialog` ส่งเฉพาะ default slot ไป `UModal#body` — ฟอร์มเพิ่มบทบาทว่าง
- **ไฟล์ที่กระทบ:** `OrgRoleFormModal.vue`, `OrgRoleDeleteModal.vue`, `AppDialog.vue`
- **Phase:** 1

### 2026-06-08 — AppDataTable header rounded top corners

- **ทำอะไร:** หัวตารางมน `rounded-t-lg` ซ้าย–ขวา–บน (`.app-data-table` ใน `main.css`)
- **ไฟล์ที่กระทบ:** `AppDataTable.vue`, `app/assets/css/main.css`
- **Phase:** 1

### 2026-06-08 — docs: SHARED-COMPONENTS.md

- **ทำอะไร:** เอกสาร component/config ใช้ร่วมทั้งระบบ — ตาราง, pagination, dialog, form, avatar
- **ไฟล์ที่กระทบ:** `docs/05-frontend/SHARED-COMPONENTS.md`, `docs/05-frontend/README.md`, `frontend/README.md`
- **Phase:** 1

### 2026-06-08 — AppPagination + usePagination (20 rows/page)

- **ทำอะไร:** component `AppPagination` + composable `usePagination` — 20 รายการต่อหน้า; ใช้กับตาราง system-users, contacts, companies, roles, user-approvals
- **ไฟล์ที่กระทบ:** `AppPagination.vue`, `usePagination.ts`, `config/pagination.ts`, `AppDataTable.vue` (embedded), หน้าตาราง CRM, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — system-users: inline role tabs above table

- **ทำอะไร:** tabs กรอง role เป็นกล่อง inline-block ชิดด้านบนตาราง (รวม border กับ `AppDataTable` embedded)
- **ไฟล์ที่กระทบ:** `pages/app/setup/system-users/index.vue`, `AppDataTable.vue`, `config/appFormUi.ts`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — system-users: role tabs + distinct role chip colors

- **ทำอะไร:** tabs กรองตามระดับองค์กร (ทั้งหมด / เจ้าของ / ผู้ดูแล / พนักงาน) พร้อมจำนวน; chip สีแยก owner (amber), admin (sky), employee (emerald)
- **ไฟล์ที่กระทบ:** `pages/app/setup/system-users/index.vue`, `config/appFormUi.ts`
- **Phase:** 1

### 2026-06-08 — AppDataTable font +1px

- **ทำอะไร:** ขนาดตัวอักษรในตารางทั้งระบบใหญ่ขึ้น 1px จาก `text-sm` เดิม (`calc(0.875rem + 1px)`)
- **ไฟล์ที่กระทบ:** `AppDataTable.vue`, `config/appFormUi.ts`
- **Phase:** 1

### 2026-06-08 — table badge chips: bold dark text

- **ทำอะไร:** chip ในตารางผู้ใช้ในระบบ — ตัวอักษรดำหนา (`appTableBadgeClass`) อ่านง่ายบนพื้น subtle
- **ไฟล์ที่กระทบ:** `config/appFormUi.ts`, `pages/app/setup/system-users/index.vue`
- **Phase:** 1

### 2026-06-08 — system-users create: default role employee

- **ทำอะไร:** เปิดฟอร์มสร้างผู้ใช้ใหม่ — default ระดับองค์กรเป็น «พนักงาน» (employee) แทนรายการแรกใน dropdown
- **ไฟล์ที่กระทบ:** `components/setup/SystemUserFormModal.vue`
- **Phase:** 1

### 2026-06-08 — password generate button + avatar delete from storage

- **ทำอะไร:** ปุ่มสร้างรหัสผ่าน — พื้นเขียวเข้ม (`bg-menu-section`) ตัวอักษรขาว; ลบรูปแล้วบันทึก — ลบไฟล์จริงใน Supabase Storage (path จาก URL + list โฟลเดอร์ org)
- **ไฟล์ที่กระทบ:** `AppPasswordFieldGroup.vue`, `useUserAvatar.ts`, `SystemUserFormModal.vue`
- **Phase:** 1

### 2026-06-08 — system-users list: search filters

- **ทำอะไร:** เพิ่ม filter ค้นหาจากชื่อ / อีเมล / username และตัวเลือก «ดูข้อมูลทั้งหมด» บนหน้ารายการผู้ใช้ในระบบ
- **ไฟล์ที่กระทบ:** `pages/app/setup/system-users/index.vue`, `i18n/locales/th.json`, `i18n/locales/en.json`
- **Phase:** 1

### 2026-06-08 — system-users avatar: webp + resize before upload

- **ทำอะไร:** ย้าย `AppAvatarUpload` ไปคอลัมน์ขวา และแปลงรูปเป็น `webp` พร้อมลดขนาดด้วย `canvas` ก่อนอัปโหลดขึ้น Storage
- **ไฟล์ที่กระทบ:** `app/components/setup/SystemUserFormModal.vue`, `app/composables/useUserAvatar.ts`
- **Phase:** 1


### 2026-06-08 — fix system-users/new route + edit modal component name

- **ทำอะไร:** ย้าย list → `system-users/index.vue` (แก้ nested route กับ `/new`); ใช้ `SetupSystemUserFormModal` ใน template
- **สาเหตุ:** Nuxt ไม่ register `/system-users/new` เมื่อมีทั้ง `system-users.vue` + `system-users/new.vue`; ชื่อ component ผิดทำให้ dialog แก้ user ไม่ขึ้น
- **ไฟล์ที่กระทบ:** `pages/app/setup/system-users/index.vue`, `.cursor/rules/nuxt-frontend-pitfalls.mdc`
- **Phase:** 1

### 2026-06-08 — strengthen login → CRM session routing

- **ทำอะไร:** `useAuthSession`, middleware auth/guest, index redirect, logo ใน CRM sidebar
- **ไฟล์ที่กระทบ:** `composables/useAuthSession.ts`, `middleware/*`, `index.vue`, `login.vue`, `layouts/app.vue`
- **Phase:** 1

### 2026-06-08 — default font Noto Sans Thai ทั้งระบบ (interim)

- **ทำอะไร:** `--font-sans` / `--font-heading` = Noto ทุก locale — รอ user สั่ง Taviraj/Prompt
- **ไฟล์ที่กระทบ:** `main.css`, `app.vue`, `TYPOGRAPHY.md`, `DECISIONS.md`, IRON-RULES, Cursor rule
- **Phase:** 1

### 2026-06-08 — auth panel: container + green-50 + Noto สำหรับ p

- **ทำอะไร:** AuthShell ซ้าย — container, พื้นเขียวอ่อน, `.auth-brand-panel` ใช้ Noto Sans Thai ชั่วคราว
- **ไฟล์ที่กระทบ:** `AuthShell.vue`, `main.css`, `TYPOGRAPHY.md`
- **Phase:** 1

### 2026-06-08 — redesign login/signup (FlowAccount-style + logo)

- **ทำอะไร:** AuthShell split layout, logo, i18n brand copy, signup ใช้ layout เดียวกัน
- **ไฟล์ที่กระทบ:** `AuthShell.vue`, `login.vue`, `signup.vue`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — fix dev script TMPDIR สำหรับ macOS (Nuxt 4.4.7 socket)

- **ทำอะไร:** `dev`: `TMPDIR=/tmp nuxt dev` — แก้ ENOENT vite-node socket
- **ไฟล์ที่กระทบ:** `package.json`
- **Phase:** 1

### 2026-06-08 — add locale typography (Noto Sans Thai, Taviraj, Prompt)

- **ทำอะไร:** Google Fonts + CSS variables ตาม `html[lang]` — sync กับ i18n locale
- **ไฟล์ที่กระทบ:** `app/assets/css/main.css`, `app.vue`, `app/layouts/app.vue`
- **Phase:** 1
- **อ้างอิง:** `docs/12-i18n/README.md` § Typography

### 2026-06-08 — add i18n (th + en) ทุกหน้า UI

- **ทำอะไร:** `@nuxtjs/i18n`, locale files, LocaleSwitcher, useFormat — แทน hardcoded strings ใน login/signup/CRM
- **ไฟล์ที่กระทบ:** `i18n/**`, `app/pages/**`, `app/layouts/app.vue`, `app/components/**`, `nuxt.config.ts`, `package.json`
- **Phase:** 1
- **อ้างอิง:** `docs/12-i18n/`, DECISIONS D-009, IRON-RULES §12

### 2026-06-08 — create Phase 1 CRM scaffold

- **ทำอะไร:** Nuxt 4 + Nuxt UI + Supabase — login/signup, dashboard, contacts, companies, deals Kanban
- **ไฟล์ที่กระทบ:** `app/**`, `nuxt.config.ts`, `package.json`, `.env.example`
- **Phase:** 1
- **หมายเหตุ:** `/signup` สำหรับผูก demo org (ไม่ใช่ SaaS register Phase 4)
