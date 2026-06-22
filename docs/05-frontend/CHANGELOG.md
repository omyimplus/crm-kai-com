# Changelog — Frontend

→ ออกแบบปัจจุบัน: [README.md](./README.md)

---

## ประวัติ

### 2026-06-18 — Opportunities: standalone create

- **Route:** `/app/opportunities/new` · ลูกค้า pattern Lead
- **Spec:** [OPPORTUNITIES-MODULE.md](./OPPORTUNITIES-MODULE.md)

### 2026-06-18 — Opportunities: แก้ dropdown โปรเจกต์

- **Handoff:** [OPPORTUNITIES-PROJECTS-HANDOFF.md](./OPPORTUNITIES-PROJECTS-HANDOFF.md) — root cause `value: ''` ใน `USelectMenu`
- **`OpportunitiesProjectCard.vue`** — แยกการ์ดโปรเจกต์ · enum ใช้ `null` แทน empty string

### 2026-06-18 — Opportunities module v1 (implement)

- **Route:** `/app/opportunities` · `/app/opportunities/from-lead/:leadId` · `/app/opportunities/:id` · `/app/opportunities/:id/edit`
- **DB:** migration `20260608120081_opportunities_module.sql`
- **Flow:** สร้างจากลีดเท่านั้น · ปุ่ม Convert บนหน้าดูลีด · stage จาก default pipeline
- **Spec:** [OPPORTUNITIES-MODULE.md](./OPPORTUNITIES-MODULE.md) · QA: [QA-OPPORTUNITIES.md](../11-dev-setup/QA-OPPORTUNITIES.md)

### 2026-06-18 — Leads list table redesign

- ตารางใหม่ `LeadsLeadTable.vue` — คอลัมน์กระชับ · มูลค่า · ดำเนินการถัดไป · เจ้าของ
- ฟิลเตอร์ชิปสถานะ · การ์ดสรุปกดกรองลีดร้อนแรง
- **Spec:** [LEADS-MODULE.md](./LEADS-MODULE.md)

### 2026-06-18 — Leads module v1 (implement)

- **Route:** `/app/leads` · `/app/leads/new` · `/app/leads/:id/edit`
- **DB:** migration `20260608120075_leads_module.sql`
- **Spec:** [LEADS-MODULE.md](./LEADS-MODULE.md) — สถานะ ✅ implement v1

### 2026-06-18 — Leads module design spec

- **Docs:** `LEADS-MODULE.md` — รายการ + summary cards · filter · ฟอร์ม New Lead (หน้าเต็ม) · Lead Score · Address · อ้างอิง mockup ระบบเก่า
- **อัปเดต:** `APP-MENU.md`, `README.md`

### 2026-06-08 — Tasks list date range filter

- **UX:** ช่วงวันที่ (ตั้งแต่–ถึง) ต่อท้ายช่องค้นหา · กรองตาม `start_at`
- **ไฟล์:** `AppDateRangeFilter.vue`, `tasks.vue`, `masterTasks.ts`

### 2026-06-08 — Tasks calendar day indicator redesign

- **UX:** ช่องวันที่มีงาน — ขอบ/พื้นหลัง primary · ปุ่มเต็มความกว้างด้านล่าง · วันนี้เน้นวงกลม primary
- **ไฟล์:** `TasksCalendar.vue`

### 2026-06-08 — Tasks list schedule filters

- **UX:** กรอง list/table/grid ตามปี · เดือน · วันเริ่ม (`start_at`) — default ปีปัจจุบัน
- **ไฟล์:** `tasks.vue`, `masterTasks.ts` — `taskMatchesScheduleFilters`

### 2026-06-08 — Tasks dynamic statuses (Master Data)

- **UX:** summary cards / list filter จาก `module_statuses` active · create default = `is_default` · edit งาน inactive ยังเลือกสถานะเดิม
- **Docs:** `TASKS-MODULE.md` § lifecycle สถานะ

### 2026-06-08 — Tasks form modal layout

- **UX:** flow แนวตั้ง · select ค้นหาได้ · `TasksFormModal.vue`
- **Docs:** `TASKS-MODULE.md` modal wireframe

### 2026-06-08 — Modal overlay ดำ fade

- **UI:** พื้นหลัง `UModal` / `AppDialog` ทั้งระบบ — `bg-black/60` + fade animation
- **ไฟล์:** `app/app.config.ts`, `components/AppDialog.vue`, `SHARED-COMPONENTS.md`

### 2026-06-08 — AppViewModeToggle shared component

- **Component:** `AppViewModeToggle` + `config/appViewMode.ts` — table/grid และ list/calendar presets
- **Refactor:** Setup roles, company profiles, Tasks
- **i18n:** `common.viewMode.*`

### 2026-06-08 — Tasks page Phase 2 v1

- **Route:** `/app/tasks` — summary cards · status tabs (list) · calendar view · CRUD modal
- **ไฟล์:** `components/tasks/*`, `composables/useTasks.ts`, `config/masterTasks.ts`, i18n `tasks.*`
- **Docs:** `TASKS-MODULE.md`, `APP-MENU.md`

### 2026-06-08 — Tasks module design spec (Phase 2)

- **เอกสาร:** `TASKS-MODULE.md` — job code auto-running, lazy seed, ปฏิทินแยก view, Create Task modal (ระบบเก่า)
- **ไฟล์ที่กระทบ:** `APP-MENU.md`, `07-phases/README.md`, `TASKS-MODULE.md`

### 2026-06-08 — Master Data menu Phase 1 complete

- **11 menus:** customer → job code · split-pane UX สำหรับ module-status + job-code
- **Docs:** `PROJECT-STATUS.md`, `MASTER-DATA-MENU.md`, `frontend/README.md`

### 2026-06-08 — Job code master UI

- **Route:** `/app/job-code` · แท็บโมดูลซ้าย + ฟอร์มขวา (query `?module=`)
- **Docs:** `MASTER-DATA-MENU.md` · `tables.md`

### 2026-06-08 — Module statuses master UI

- **Route:** `/app/module-status` · แท็บโมดูลซ้าย + รายการขวา (query `?module=`) · locked module on create
- **Docs:** `MASTER-DATA-MENU.md` · `tables.md`

### 2026-06-08 — Sales team master UI

- **Route:** `/app/sales-team` · multi-member chip select from system users
- **Docs:** `MASTER-DATA-MENU.md` · `tables.md`

### 2026-06-08 — ยกเลิก Employee position + Employee master menu

- **เหตุผล:** ใช้ Setup → ผู้ใช้งานในระบบ แทน master menu พนักงาน/ตำแหน่ง
- **Docs:** `MASTER-DATA-MENU.md`

### 2026-06-08 — Master Data Category UI

- **Route:** `/app/category` · hierarchy · color · archive tabs
- **Docs:** `CATEGORY-MASTER-FIELDS.md`

### 2026-06-08 — Master Data Products UI

- **Route:** `/app/product` · list/new/view/edit + archive tabs
- **Docs:** `PRODUCT-MASTER-FIELDS.md` · `MASTER-DATA-MENU.md`

### 2026-06-17 — Charts: nuxt-charts + AppLineChart

- **ทำอะไร:** ติดตั้ง `nuxt-charts` · wrapper `AppLineChart` · เอกสาร `CHARTS.md` · เป้ายอดขายใช้ lib แทน SVG
- **ไฟล์ที่กระทบ:** `nuxt.config.ts`, `AppLineChart.vue`, `config/appChart.ts`, `MasterDataSalesTargetProgressChart.vue`, `SHARED-COMPONENTS.md`

### 2026-06-16 — SHARED-COMPONENTS: list layout แบบ system-users

- **ทำอะไร:** จด reference layout filter + tabs + modal จาก `/app/setup/system-users`
- **ไฟล์ที่กระทบ:** `SHARED-COMPONENTS.md`

### 2026-06-08 — IMAGE-UPLOAD.md + shared image upload stack

- **ทำอะไร:** เอกสารและชุดกลาง `useImageUpload` / `AppImageUpload` — avatar + company logo
- **ไฟล์ที่กระทบ:** `IMAGE-UPLOAD.md`, `SHARED-COMPONENTS.md`, `README.md`

### 2026-06-08 — AppDataTable header rounded corners

- **ทำอะไร:** หัวตารางมนซ้าย–ขวา–บน ผ่าน `.app-data-table` ใน `main.css`
- **ไฟล์ที่กระทบ:** `AppDataTable.vue`, `frontend/app/assets/css/main.css`, `SHARED-COMPONENTS.md`

### 2026-06-08 — add SHARED-COMPONENTS.md

- **ทำอะไร:** เอกสาร component ใช้ร่วม — AppDataTable, AppPagination, AppDialog, form UI class, avatar
- **ไฟล์ที่กระทบ:** `SHARED-COMPONENTS.md`, `README.md`

### 2026-06-08 — add Master Data → Roles menu (กำหนด Role)

- **ทำอะไร:** เมนูกำหนด role ใน Master Data (นอก Setup) + route `/app/master-data/roles` + เอกสาร
- **ไฟล์ที่กระทบ:** `masterDataMenu.ts`, `pages/app/master-data/roles.vue`, `i18n`, `MASTER-DATA-MENU.md`

### 2026-06-08 — implement Setup → System Users page

- **ทำอะไร:** หน้าผู้ใช้ในระบบ — ตารางรายชื่อ, แก้ไขชื่อ/บทบาท/สถานะ (owner/admin)
- **ไฟล์ที่กระทบ:** `system-users.vue`, `SystemUserEditModal.vue`, `useSystemUsers.ts`, migration `20260608120003_*`, `i18n`, `setupMenu.ts`

### 2026-06-08 — replace sidebar with App menu (12 pages Coming soon)

- **ทำอะไร:** ลบ Setup / Master Data / CRM เดิมออกจาก sidebar — ใช้เมนู Menu 12 รายการ (dashboard → service) พร้อม routes และเอกสาร APP-MENU.md
- **ไฟล์ที่กระทบ:** `appMenu.ts`, `AppSidebar.vue`, `AppMenuComingSoon.vue`, `pages/app/{tasks,leads,...}.vue`, `i18n/locales/{th,en}.json`, `APP-MENU.md`, `README.md`, `IRON-RULES.md`
- **หมายเหตุ:** routes เดิม (`/app/setup/**`, `/app/master-data/**`, contacts/companies/deals) ยังอยู่ใน repo — legacy

### 2026-06-08 — create Master data menu scaffold (10 pages Coming soon)

- **ทำอะไร:** เมนูข้อมูลหลักใน sidebar + routes `/app/master-data/**` + เอกสาร MASTER-DATA-MENU.md (รวม module statuses)
- **ไฟล์ที่กระทบ:** `masterDataMenu.ts`, `pages/app/master-data/*`, `MasterDataComingSoon.vue`, `AppSidebar.vue`, `i18n/locales/{th,en}.json`, `MASTER-DATA-MENU.md`
- **Phase:** 2+ (scaffold)

### 2026-06-08 — create Setup menu scaffold (6 pages Coming soon)

- **ทำอะไร:** เมนู Setup ใน sidebar + routes `/app/setup/**` + component `SetupComingSoon` + เอกสาร SETUP-MENU.md
- **ไฟล์ที่กระทบ:** `frontend/app/config/setupMenu.ts`, `frontend/app/pages/app/setup/*`, `frontend/app/components/setup/SetupComingSoon.vue`, `frontend/app/layouts/app.vue`, `frontend/i18n/locales/{th,en}.json`, `SETUP-MENU.md`, `README.md`
- **เหตุผล:** เตรียมโครง admin ไว้ก่อน — implement ทีละหน้า
- **Phase:** 2+ (scaffold ใน Phase 1)

### 2026-06-08 — create BRAND-ASSETS.md (logo paths)

- **ทำอะไร:** บันทึก logo `public/images/logo/logo-kai-com-crm.webp` + `logo-kai-com-crm-icon.webp`
- **ไฟล์ที่กระทบ:** `BRAND-ASSETS.md`, `README.md`, `IRON-RULES.md`, `frontend/README.md`
- **Phase:** 1

### 2026-06-08 — update เอกสาร TYPOGRAPHY.md

- **ทำอะไร:** ลิงก์ฟอนต์ใน README
- **ไฟล์ที่กระทบ:** `README.md`
- **Phase:** 1

### 2026-06-08 — update เอกสาร i18n 2 ภาษา

- **ทำอะไร:** เพิ่ม i18n ใน README + ลิงก์ docs/12-i18n
- **ไฟล์ที่กระทบ:** `README.md`
- **Phase:** 1

### 2026-06-08 — create เอกสาร frontend

- **ทำอะไร:** สร้าง README routes + โครงโฟลเดอร์ Nuxt
- **ไฟล์ที่กระทบ:** `README.md`
- **Phase:** 1 (ยังไม่ scaffold frontend/)
