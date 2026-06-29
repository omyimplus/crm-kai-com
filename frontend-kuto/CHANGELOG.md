# Changelog — frontend-kuto

## 2026-06-25 — แก้ filter ประวัติการติดต่อ (เทียบ figma)

- **ปัญหา:** เหมือนรายชื่อผู้ติดต่อ — `items=[]` + `flex-1` ทำให้ dropdown กลายเป็นแถบดำซ้อนแนวตั้ง
- **แก้:** search ซ้าย · filter 8 ช่องแนวนอน scroll · placeholder item
- **ไฟล์:** `KutoCustomersContactHistoryPage.vue`

## 2026-06-25 — แก้ filter รายชื่อผู้ติดต่อ (เทียบ figma)

- **ปัญหา:** `USelectMenu` ที่ `items=[]` + `flex-1` ทำให้ dropdown 12 ช่องกลายเป็นแถบดำเต็มความกว้างซ้อนแนวตั้ง
- **แก้:** แยก search กับ filter · แถว filter แนวนอน scroll · ลำดับตาม figma (บริษัท → ตำแหน่ง → แผนก → บทบาท → …) · placeholder item สำหรับ mock filter
- **ไฟล์:** `KutoCustomersContactsListPage.vue`

## 2026-06-25 — แก้รายชื่อผู้ติดต่อ / ประวัติการติดต่อไม่แสดง (auto-import)

- **สาเหตุ:** ชื่อ component ใน `kuto/customers/` ขึ้นต้น `Kuto` ซ้ำ → Nuxt resolve เป็น `KutoCustomersKutoContactsListPage` แต่หน้าเรียก `KutoContactsListPage`
- **แก้:** rename เป็น `KutoCustomersContactsListPage.vue` · `KutoCustomersContactHistoryPage.vue` · ใช้ชื่อ component ตรงกับไฟล์ใน `pages/`

## 2026-06-25 — เป้าหมายทั้งหมด: แผงขวาแบบกล่องรับเป้าหมาย

- **ทำอะไร:** `/app/leads` — KPI เต็มความกว้าง · โหมดตารางมีแผงขวา 2 การ์ด (ดูรายละเอียดด่วน + ช่องทาง) · คลิกแถวเลือกเป้าหมาย · `lg:` sticky
- **ไฟล์หลัก:** `KutoLeadsListPage.vue`

## 2026-06-25 — นำเข้าข้อมูลลูกค้า (mock wizard ตาม figma + leads import)

- **ทำอะไร:** `/app/customers/import` — wizard 7 ขั้น (อัปโหลด · mapping 2 sheet · ตรวจสอบ · ซ้ำ · Owner · ยืนยัน · ผลลัพธ์) · KPI 4 · ประวัตินำเข้า
- **อ้างอิง:** `KutoLeadsImportPage.vue` · figma `/app/customers/import`
- **ไฟล์หลัก:** `KutoCustomersImportPage.vue`, `kutoCustomersImportMock.ts`, `pages/app/customers/import/index.vue`
- **i18n:** `kuto.customers.import.*` (th + en)

## 2026-06-25 — ประวัติการติดต่อ (mock timeline ตาม figma)

- **ทำอะไร:** `/app/customers/contact-history` — filter · แท็บประเภทกิจกรรม · **Timeline feed** จัดกลุ่มตามวัน · สลับโหมดตาราง · แถบล่างเปิด C360
- **หมายเหตุ:** figma ใช้ timeline ไม่ใช่ตาราง+แผงขวาแบบรายชื่อลูกค้า/ผู้ติดต่อ
- **ไฟล์หลัก:** `KutoContactHistoryPage.vue`, `kutoContactHistoryMock.ts`, `kutoContactHistoryBadges.ts`

## 2026-06-25 — รายชื่อผู้ติดต่อ (mock ตาม figma)

- **ทำอะไร:** `/app/customers/contacts` — KPI 6 ใบ · filter · แท็บ 9 · ตาราง + แผงขวา 2 การ์ด (รายละเอียดด่วน + กิจกรรมล่าสุด)
- **ไฟล์หลัก:** `KutoContactsListPage.vue`, `kutoContactsListMock.ts`, `kutoContactBadges.ts`, `pages/app/customers/contacts/index.vue`
- **i18n:** `kuto.customers.contacts.list.*` (th + en)

## 2026-06-25 — คำศัพท์ Leads vs ลูกค้า (ลดความสับสน)

- **ทำอะไร:** Leads sidebar + หน้า — **กล่องรับเป้าหมาย / เป้าหมายทั้งหมด / นำเข้าเป้าหมาย** (parent คง **ลูกค้าเป้าหมาย**) · แท็บ/KPI ลูกค้า `prospect` → **สถานะ: เป้าหมาย**
- **ไฟล์หลัก:** `i18n/locales/th.json`, `en.json` · `KUTO-LEADS-IA.md`, `KUTO-CUSTOMERS-IA.md`, `KUTO-MENU-PAGE-MATRIX.md`

## 2026-06-25 — รายชื่อลูกค้า: แผงขวาแบบกล่องรับลูกค้า

- **ทำอะไร:** ปรับ layout `/app/customers` — KPI เต็มความกว้าง · ตารางซ้าย + การ์ดขวา 2 ใบ (ดูรายละเอียดด่วน + ความสัมพันธ์ลูกค้า) · `lg:` sticky เหมือน `KutoLeadsInboxPage`
- **ไฟล์หลัก:** `KutoCustomersListPage.vue`, i18n `kuto.customers.list.detail.quickTitle`, `kuto.customers.list.relations.*`

## 2026-06-25 — หน้ารายชื่อลูกค้า (mock ตาม figma)

- **ทำอะไร:** `/app/customers` — KPI 6 ใบ · filter · แท็บสถานะ 8 · ตาราง + แผงรายละเอียดขวา · pagination
- **ไฟล์หลัก:** `KutoCustomersListPage.vue`, `kutoCustomersListMock.ts`, `kutoCustomerBadges.ts`, `pages/app/customers/index.vue`
- **i18n:** `kuto.customers.list.*` (th + en)

## 2026-06-25 — ประวัติการติดต่อใน sidebar ลูกค้า

- **ทำอะไร:** เมนูย่อย **ประวัติการติดต่อ** → `/app/customers/contact-history` (ลำดับ: ลูกค้า · ผู้ติดต่อ · ประวัติ · นำเข้า)
- **ไฟล์หลัก:** `kutoMenu.ts`, i18n, `KUTO-CUSTOMERS-IA.md`, `KUTO-CONTACTS-IA.md`

## 2026-06-25 — รายชื่อผู้ติดต่อใน sidebar ลูกค้า

- **ทำอะไร:** เพิ่มเมนูย่อย **รายชื่อผู้ติดต่อ** ใต้ลูกค้า → `/app/customers/contacts` (ลำดับ: ลูกค้า · ผู้ติดต่อ · นำเข้า)
- **ไฟล์หลัก:** `kutoMenu.ts`, i18n `kuto.nav.sub.customers.contacts`, `KUTO-CUSTOMERS-IA.md`, `KUTO-CONTACTS-IA.md`

## 2026-06-25 — Contacts IA รวมเข้าลูกค้า (sidebar 0)

- **ทำอะไร:** เอาโมดูล **ผู้ติดต่อ** ออกจาก sidebar (10 → 0) · ผู้ติดต่อ + ประวัติการติดต่อ → แท็บใน C360 (`/app/customers/:id`)
- **เอกสาร:** `KUTO-CONTACTS-IA.md` · อัปเดต `KUTO-CUSTOMERS-IA.md`
- **ไฟล์หลัก:** `kutoMenu.ts`, `KUTO-MENU-PAGE-MATRIX.md`

## 2026-06-25 — Customers IA ยุบเมนู (8 → 2)

- **ทำอะไร:** Sidebar Customers เหลือ รายชื่อลูกค้า + นำเข้า · C360/สาขา/เอกสาร/ซ้ำ/กิจกรรม → hub + `/app/customers/:id` + deep link
- **เอกสาร:** `docs/05-frontend/KUTO-CUSTOMERS-IA.md`
- **ไฟล์หลัก:** `kutoMenu.ts`, `KUTO-MENU-PAGE-MATRIX.md`

## 2026-06-25 — หน้านำเข้าลูกค้า (mock wizard)

- **ทำอะไร:** `/app/leads/import` — wizard 6 ขั้น (อัปโหลด · Mapping · ตรวจสอบ · ตรวจซ้ำ · ยืนยัน · ผลลัพธ์)
- **ไฟล์หลัก:** `KutoLeadsImportPage.vue`, `kutoLeadsImportMock.ts`, `pages/app/leads/import.vue`

## 2026-06-25 — ลูกค้าทั้งหมด: สถานะ pipeline + KPI ตาม mock

- **ทำอะไร:** `/app/leads` — KPI 5 ใบ (2,418 / 184 / 642 / 318 / 96) · แท็บสถานะ 8 รายการพร้อมตัวเลข mock · คอลัมน์ตาราง Lead ID / สินค้า / Priority · `KutoPagination` แสดงตลอด (mock page size 5) ใน list + inbox + dashboard opps
- **i18n:** `kuto.leads.list.pipeline.*`, `summary.*`, `kuto.common.pagination.*`, `actions.inbox` (th + en)
- **ไฟล์หลัก:** `KutoLeadsListPage.vue`, `kutoLeadsListMock.ts`, `KutoPagination.vue`, `useKutoPagination.ts`, `KutoLeadsInboxPage.vue`, `KutoDashboardPage.vue`

## 2026-06-25 — หน้าลูกค้าทั้งหมด hub (mock)

- **ทำอะไร:** `/app/leads` — การ์ดสรุป · แท็บ ทั้งหมด/กล่องรับ/แปลงแล้ว · filter · ตาราง/Kanban · bulk มอบหมาย (mock) · ปุ่ม ลีดใหม่/นำเข้า/ตรวจซ้ำ
- **IA:** ยุบเมนู figma (kanban, scoring, assignment, converted tab, …) เข้าหน้าเดียว — ดู `KUTO-LEADS-IA.md`
- **ไฟล์หลัก:** `KutoLeadsListPage.vue`, `kutoLeadsListMock.ts`, `pages/app/leads/index.vue`

## 2026-06-25 — หน้ากล่องรับลูกค้า (mock ตาม figma)

- **ทำอะไร:** `/app/leads/inbox` — KPI 6 ใบ · filter chips · ตาราง · panel รายละเอียดขวา · breadcrumb จาก `useKutoBreadcrumb`
- **ไฟล์หลัก:** `KutoLeadsInboxPage.vue`, `kutoLeadsInboxMock.ts`, `pages/app/leads/inbox.vue`

## 2026-06-25 — Sidebar ตัวอักษรใหญ่ขึ้น

- **ทำอะไร:** เมนูหลัก `text-sm` · ย่อย `13px` · nested `text-xs` · sidebar `w-60`
- **ไฟล์หลัก:** `KutoSidebar.vue`, `kutoTheme.ts`

## 2026-06-25 — Leads: เรียง inbox ก่อน + นำเข้า + icon เมนูย่อย

- **ทำอะไร:** Sidebar Leads — กล่องรับ → ทั้งหมด → นำเข้า · icon lucide ทุกเมนูย่อย (`kutoNavSubIcons.ts`)
- **ไฟล์หลัก:** `kutoMenu.ts`, `KutoSidebar.vue`, `kutoNavSubIcons.ts`, `KUTO-LEADS-IA.md`

## 2026-06-25 — Leads IA ยุบเมนู (2 sub + spec)

- **ทำอะไร:** Sidebar Leads เหลือ ลูกค้าทั้งหมด + กล่องรับ · เอา มอบหมาย/นำเข้า/ซ้ำ และอื่น ๆ ออกจาก sidebar → อยู่ในหน้า/deep link
- **เอกสาร:** `docs/05-frontend/KUTO-LEADS-IA.md`
- **ไฟล์หลัก:** `kutoMenu.ts`, `KUTO-MENU-PAGE-MATRIX.md`

## 2026-06-25 — แดชบอร์ด direct link (ไม่มี submenu)

- **ทำอะไร:** เอา dropdown แดชบอร์ดออกจาก sidebar — ประเภท (Sales, Executive, …) เลือกใน `KutoDashboardPage` อยู่แล้ว
- **ไฟล์หลัก:** `kutoMenu.ts`, `KUTO-MENU-PAGE-MATRIX.md`

## 2026-06-25 — Sidebar dropdown + page matrix

- **ทำอะไร:** เมนู sidebar แบบ expand/collapse ตรง figma.site (~129 leaf routes) · nested ตั้งค่า → ข้อมูลหลัก · badge mock · i18n `kuto.nav.sub.*`
- **เอกสาร:** `docs/05-frontend/KUTO-MENU-PAGE-MATRIX.md` · rule sync 4 จุดใน `.cursor/rules/frontend-kuto.mdc`
- **ไฟล์หลัก:** `kutoMenu.ts`, `KutoSidebar.vue`, `i18n/locales/th.json`, `en.json`

## 2026-06-25 — Sidebar + dropdown polish

- **ทำอะไร:** Sidebar `w-56` (224px) · ตัวอักษร `text-xs` ตรง figma.site · Quick Create dropdown (ปิดเมื่อเลือก · coming soon badge) · filter row ใช้ `USelectMenu`
- **ไฟล์หลัก:** `KutoSidebar.vue`, `KutoHeader.vue`, `KutoDashboardPage.vue`, `kutoHeaderQuickCreate.ts`

## 2026-06-25 — Live KPI bar ตรง figma.site

- **ทำอะไร:** ส่วนหัวแดชบอร์ด (แดชบอร์ด · โหมดภาษาไทย · ข้อมูลสดจาก Supabase · รีเฟรช) + การ์ด KPI 6 ใบ — เส้นสีซ้าย · ไอคอน · ตัวเลขสี accent · subtext
- **ไฟล์หลัก:** `KutoDashboardLiveSection.vue`, `kutoDashboardMock.ts`, i18n `kuto.dashboard.live.*`

## 2026-06-25 — v0 scaffold + Dashboard แดชบอร์ดของฉัน

- **ทำอะไร:** สร้าง `frontend-kuto/` — Nuxt 4 + Nuxt UI · port 3001 · shell KuTo teal · dashboard mock ตาม figma.site
- **ไฟล์หลัก:** layout, KutoSidebar, KutoHeader, KutoDashboardPage, i18n th/en
- **ยังไม่มี:** auth, ต่อ DB จริง, โมดูลอื่น
