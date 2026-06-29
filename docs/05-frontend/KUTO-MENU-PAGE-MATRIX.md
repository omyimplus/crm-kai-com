# KuTo — Sidebar Menu & Page Matrix

> **Source of truth (code):** `frontend-kuto/app/config/kutoMenu.ts`  
> **UX reference:** https://morph-boho-25621922.figma.site/  
> **Placeholder route:** `pages/app/[...slug].vue` (⏳ เร็ว ๆ นี้) · **Dashboard ของฉัน:** `pages/app/index.vue` (✅ mock)

---

## สถานะ (legend)

| สัญลักษณ์ | ความหมาย |
|-----------|----------|
| ✅ | มีหน้า/UI implement แล้ว (ไม่ใช่ placeholder) |
| ⏳ | มี route + เมนูแล้ว · ยังเป็น placeholder / mock |
| 📋 | วางแผนใน spec · ยังไม่มีในเมนู |

---

## กฎ sync — อ่านทุกครั้งก่อนแก้เมนูหรือเพิ่มหน้า

เมื่อ **เพิ่ม · ลด · เปลี่ยนชื่อ · ย้าย route** ใน sidebar KuTo ให้แก้ **ครบ 4 จุด** ใน commit เดียวกัน:

1. **`frontend-kuto/app/config/kutoMenu.ts`** — โครงเมนู + badge + `flattenKutoNav` / expand keys
2. **ไฟล์นี้** — อัปเดตตาราง + สถานะหน้า
3. **`frontend-kuto/i18n/locales/th.json` + `en.json`** — key `kuto.nav.*` / `kuto.nav.sub.*`
4. **`frontend-kuto/CHANGELOG.md`** — บรรทัดสั้น ๆ ว่าเปลี่ยน IA อะไร

ถ้า implement หน้าจริง (ไม่ใช่ placeholder) → เปลี่ยนสถานะเป็น ✅ ในไฟล์นี้ · สร้าง `pages/...` แทน catch-all ถ้าจำเป็น

**Agent rule:** `.cursor/rules/frontend-kuto.mdc`

---

## สรุป

| โมดูล | รายการ leaf | ✅ | ⏳ |
|--------|-------------|----|----|
| แดชบอร์ด | 1 | 1 | 0 |
| ลูกค้าเป้าหมาย (sidebar) | 3 | 3 | 0 |
| ลูกค้า (sidebar) | 4 | 1 | 3 |
| โอกาสการขาย | 13 | 0 | 13 |
| ใบเสนอราคา | 7 | 0 | 7 |
| สัญญาและต่ออายุ | 15 | 0 | 15 |
| สินทรัพย์ | 7 | 0 | 7 |
| Ticket | 9 | 0 | 9 |
| กิจกรรม | 5 | 0 | 5 |
| เอกสาร | 11 | 0 | 11 |
| รายงาน | 1 | 0 | 1 |
| AI | 1 | 0 | 1 |
| ตั้งค่าระบบ | 24 | 0 | 24 |
| **รวม sidebar** | **101** | **5** | **96** |

Badge mock: leads inbox 12 · quotations approvals 5 · contracts renewal 26 · tickets 8 · tickets SLA 3

**Leads IA เต็ม:** [KUTO-LEADS-IA.md](./KUTO-LEADS-IA.md)  
**Customers IA เต็ม:** [KUTO-CUSTOMERS-IA.md](./KUTO-CUSTOMERS-IA.md)  
**Contacts IA (รวมในลูกค้า):** [KUTO-CONTACTS-IA.md](./KUTO-CONTACTS-IA.md)

---

## แดชบอร์ด

| Route | Label (TH) | สถานะ | หมายเหตุ |
|-------|------------|--------|----------|
| `/app` | แดชบอร์ด | ✅ | direct link · ประเภทแดชบอร์ด (Sales, Executive, …) เลือก**ในหน้า** ไม่ใช่ sidebar |

---

## ลูกค้าเป้าหมาย (Leads)

> **IA ตัดสินแล้ว:** [KUTO-LEADS-IA.md](./KUTO-LEADS-IA.md)

### Sidebar

| Route | Label (TH) | Icon | Badge | สถานะ |
|-------|------------|------|-------|--------|
| `/app/leads/inbox` | กล่องรับเป้าหมาย | inbox | 12 | ✅ mock |
| `/app/leads` | เป้าหมายทั้งหมด | list | | ✅ mock hub |
| `/app/leads/import` | นำเข้าเป้าหมาย | upload | | ✅ mock |

ลำดับใน sidebar: **กล่องรับ → ทั้งหมด → นำเข้า** · ทุกเมนูย่อยมี icon (lucide) ตาม figma

### ไม่ใช่ sidebar — deep link / ในหน้า

| Route | ที่อยู่จริง | สถานะ |
|-------|-------------|--------|
| `/app/leads/new` | ปุ่ม + สร้าง | ⏳ |
| `/app/leads/kanban` | มุมมอง Kanban ในหน้ารายการ | 📋 |
| `/app/leads/assignment` | bulk มอบหมายในหน้ารายการ | 📋 |
| `/app/leads/scoring` | คอลัมน์/filter คะแนน | 📋 |
| `/app/leads/sources` | filter + master data ตั้งค่า | 📋 |
| `/app/leads/duplicates` | ปุ่ม/แจ้งเตือน | 📋 |
| `/app/leads/converted` | แท็บในหน้ารายการ | 📋 |

---

## ลูกค้า (Customers)

> **IA ตัดสินแล้ว:** [KUTO-CUSTOMERS-IA.md](./KUTO-CUSTOMERS-IA.md)

### Sidebar

| Route | Label (TH) | Icon | สถานะ |
|-------|------------|------|--------|
| `/app/customers` | รายชื่อลูกค้า | list | | ✅ mock |
| `/app/customers/contacts` | รายชื่อผู้ติดต่อ | users | ✅ mock |
| `/app/customers/contact-history` | ประวัติการติดต่อ | history | ✅ mock |
| `/app/customers/import` | นำเข้าข้อมูลลูกค้า | upload | | ✅ mock |

ลำดับใน sidebar: **รายชื่อลูกค้า → รายชื่อผู้ติดต่อ → ประวัติการติดต่อ → นำเข้า**

### ไม่ใช่ sidebar — deep link / ใน C360

| Route | ที่อยู่จริง | สถานะ |
|-------|-------------|--------|
| `/app/customers/new` | ปุ่ม + สร้าง | ⏳ |
| `/app/customers/:id` | Customer 360 shell | ⏳ |
| `/app/customers/360` | redirect/legacy → ใช้ `:id` | 📋 |
| `/app/customers/accounts` | แท็บ Accounts ใน C360 | 📋 |
| `/app/customers/documents` | แท็บ Documents · `/app/documents` | 📋 |
| `/app/customers/branches` | แท็บ Company ใน C360 | 📋 |
| `/app/customers/duplicates` | ปุ่มใน hub | 📋 |
| `/app/customers/activity-schedule` | legacy → `/app/customers/contact-history` + C360 | 📋 |

---

## ผู้ติดต่อ (Contacts)

> **IA ตัดสินแล้ว — ไม่มีโมดูล top-level:** [KUTO-CONTACTS-IA.md](./KUTO-CONTACTS-IA.md) · **รายชื่อผู้ติดต่อ** อยู่ใน sidebar ใต้ **ลูกค้า** (`/app/customers/contacts`)

### Sidebar (ภายใต้ลูกค้า)

| Route | Label (TH) | สถานะ |
|-------|------------|--------|
| `/app/customers/contacts` | รายชื่อผู้ติดต่อ | ✅ mock |
| `/app/customers/contact-history` | ประวัติการติดต่อ (ทั้ง org) | ✅ mock |

### ใน Customer 360 (`/app/customers/:id`)

| ส่วน | แทนเมนู figma | สถานะ |
|------|---------------|--------|
| แท็บ ผู้ติดต่อ | รายชื่อ · หลัก · role filters · + สร้าง | ⏳ |
| แผงประวัติรายบุคคล | ประวัติการติดต่อ (ต่อ contact) | ⏳ |
| แท็บ กิจกรรม | ประวัติระดับลูกค้า · timeline | ⏳ |

### ไม่ใช่ sidebar — deep link

| Route | ที่อยู่จริง | สถานะ |
|-------|-------------|--------|
| `/app/contacts` | legacy figma → ใช้ `/app/customers/contacts` | 📋 |
| `/app/contacts/primary` | filter `is_main_contact` | 📋 |
| `/app/contacts/decision-makers` | filter `contact_role` | 📋 |
| `/app/contacts/purchasing` | role chip | 📋 |
| `/app/contacts/it` | role chip | 📋 |
| `/app/contacts/roles` | ฟอร์ม · ไม่ใช่ list | 📋 |
| `/app/contacts/history` | legacy → `/app/customers/contact-history` | 📋 |
| `/app/contacts/duplicates` | import / hub | 📋 |
| `/app/contacts/import` | ขั้นในนำเข้าลูกค้า | 📋 |
| `/app/contacts/schedule` | `/app/activities?contact=` | 📋 |

---

## โอกาสการขาย (Opportunities)

| Route | Label (TH) | สถานะ |
|-------|------------|--------|
| `/app/opportunities/pipeline` | Pipeline แบบ Kanban | ⏳ |
| `/app/opportunities` | รายการโอกาสการขาย | ⏳ |
| `/app/opportunities/new` | เพิ่มโอกาสการขาย | ⏳ |
| `/app/opportunities/mine` | โอกาสการขายของฉัน | ⏳ |
| `/app/opportunities/team` | โอกาสการขายของทีม | ⏳ |
| `/app/opportunities/detail` | รายละเอียดโอกาสการขาย | ⏳ |
| `/app/opportunities/forecast` | คาดการณ์ยอดขาย | ⏳ |
| `/app/opportunities/stale` | ดีลที่ค้างนาน | ⏳ |
| `/app/opportunities/competitors` | คู่แข่ง | ⏳ |
| `/app/opportunities/win-loss` | วิเคราะห์ชนะและแพ้ | ⏳ |
| `/app/opportunities/lost-reasons` | เหตุผลที่แพ้ | ⏳ |
| `/app/opportunities/scoring` | คะแนนโอกาสการขาย | ⏳ |
| `/app/opportunities/sales-stages` | ตั้งค่า Sales Stage | ⏳ |

---

## ใบเสนอราคา (Quotations)

| Route | Label (TH) | Badge | สถานะ |
|-------|------------|-------|--------|
| `/app/quotations` | รายการใบเสนอราคา | | ⏳ |
| `/app/quotations/new` | สร้างใบเสนอราคา | | ⏳ |
| `/app/quotations/approvals` | อนุมัติใบเสนอราคา | 5 | ⏳ |
| `/app/quotations/pricing` | ราคาสินค้า | | ⏳ |
| `/app/quotations/templates` | Template ใบเสนอราคา | | ⏳ |
| `/app/quotations/versions` | ประวัติเวอร์ชัน | | ⏳ |
| `/app/quotations/expired` | ใบเสนอราคาหมดอายุ | | ⏳ |

---

## สัญญาและต่ออายุ (Contracts)

| Route | Label (TH) | Badge | สถานะ |
|-------|------------|-------|--------|
| `/app/contracts` | สัญญาทั้งหมด | | ⏳ |
| `/app/contracts/renewal-alerts` | แจ้งเตือนต่ออายุ | 26 | ⏳ |
| `/app/contracts/renewal-forecast` | คาดการณ์รายได้ต่ออายุ | | ⏳ |
| `/app/contracts/expiring` | สัญญาใกล้หมดอายุ | | ⏳ |
| `/app/contracts/expired` | สัญญาหมดอายุแล้ว | | ⏳ |
| `/app/contracts/renewed` | สัญญาที่ต่ออายุแล้ว | | ⏳ |
| `/app/contracts/not-renewed` | สัญญาที่ไม่ต่ออายุ | | ⏳ |
| `/app/contracts/renewal-calendar` | Calendar ต่ออายุ | | ⏳ |
| `/app/contracts/microsoft-csp` | สัญญา Microsoft CSP | | ⏳ |
| `/app/contracts/google-workspace` | สัญญา Google Workspace | | ⏳ |
| `/app/contracts/firewall` | สัญญา Firewall | | ⏳ |
| `/app/contracts/antivirus-edr` | สัญญา Antivirus / EDR | | ⏳ |
| `/app/contracts/maintenance` | สัญญา Maintenance | | ⏳ |
| `/app/contracts/sla` | สัญญา SLA | | ⏳ |
| `/app/contracts/warranty` | ติดตาม Warranty | | ⏳ |

---

## สินทรัพย์ (Assets)

| Route | Label (TH) | สถานะ |
|-------|------------|--------|
| `/app/assets` | สินทรัพย์ทั้งหมด | ⏳ |
| `/app/assets/installed-base` | ฐานข้อมูลการติดตั้ง | ⏳ |
| `/app/assets/subscriptions` | การสมัครใช้งาน | ⏳ |
| `/app/assets/warranty` | การรับประกัน | ⏳ |
| `/app/assets/by-customer` | สินทรัพย์ตามลูกค้า | ⏳ |
| `/app/assets/import` | นำเข้าสินทรัพย์ | ⏳ |
| `/app/assets/settings` | ตั้งค่าสินทรัพย์ | ⏳ |

---

## Ticket / งานบริการ

| Route | Label (TH) | Badge | สถานะ |
|-------|------------|-------|--------|
| `/app/tickets` | Ticket ทั้งหมด | 8 | ⏳ |
| `/app/tickets/new` | สร้าง Ticket | | ⏳ |
| `/app/tickets/mine` | Ticket ของฉัน | | ⏳ |
| `/app/tickets/team` | Ticket ของทีม | | ⏳ |
| `/app/tickets/kanban` | มุมมอง Kanban | | ⏳ |
| `/app/tickets/sla` | ติดตาม SLA | 3 | ⏳ |
| `/app/tickets/engineer-assignment` | มอบหมายวิศวกร | | ⏳ |
| `/app/tickets/service-reports` | รายงานงานบริการ | | ⏳ |
| `/app/tickets/knowledge-base` | ฐานความรู้ | | ⏳ |

---

## กิจกรรม (Activities)

| Route | Label (TH) | สถานะ |
|-------|------------|--------|
| `/app/activities/mine` | กิจกรรมของฉัน | ⏳ |
| `/app/activities/schedule` | กำหนดการกิจกรรม | ⏳ |
| `/app/activities/calendar` | มุมมองปฏิทิน | ⏳ |
| `/app/activities/meetings` | การประชุม | ⏳ |
| `/app/activities/follow-up` | การติดตามงาน | ⏳ |

---

## เอกสาร (Documents)

| Route | Label (TH) | สถานะ |
|-------|------------|--------|
| `/app/documents` | เอกสารทั้งหมด | ⏳ |
| `/app/documents/customer` | เอกสารลูกค้า | ⏳ |
| `/app/documents/quotation` | เอกสารใบเสนอราคา | ⏳ |
| `/app/documents/contract` | เอกสารสัญญา | ⏳ |
| `/app/documents/project` | เอกสารโครงการ | ⏳ |
| `/app/documents/service` | รายงานงานบริการ | ⏳ |
| `/app/documents/warranty` | เอกสารประกัน | ⏳ |
| `/app/documents/invoice` | เอกสาร Invoice | ⏳ |
| `/app/documents/templates` | Template เอกสาร | ⏳ |
| `/app/documents/versioning` | ควบคุมเวอร์ชัน | ⏳ |
| `/app/documents/archived` | เอกสารที่จัดเก็บ | ⏳ |

---

## รายงาน · AI (ไม่มี dropdown ใน sidebar)

| Route | Label (TH) | สถานะ | หมายเหตุ |
|-------|------------|--------|----------|
| `/app/reports` | รายงานและการวิเคราะห์ | ⏳ | figma: แท็บภายในหน้า ไม่มี sub sidebar |
| `/app/ai` | ข้อมูลเชิงลึกจาก AI | ⏳ | direct link |

---

## ตั้งค่าระบบ (Settings)

| Route | Label (TH) | สถานะ |
|-------|------------|--------|
| `/app/settings/company` | ข้อมูลบริษัท | ⏳ |
| `/app/settings/users` | ผู้ใช้งาน | ⏳ |
| `/app/settings/roles` | บทบาทและสิทธิ์ | ⏳ |
| `/app/settings/locale` | ตั้งค่าภาษา | ⏳ |
| `/app/settings/audit-log` | ประวัติการใช้งานระบบ | ⏳ |
| `/app/settings/teams` | ทีมงานและแผนก | ⏳ |
| `/app/settings/notifications` | การแจ้งเตือน | ⏳ |
| `/app/settings/approval-workflow` | Workflow การอนุมัติ | ⏳ |
| `/app/settings/security` | ความปลอดภัย | ⏳ |
| `/app/settings/import-export` | การนำเข้า/ส่งออก | ⏳ |
| `/app/settings/api-integration` | API และ Integration | ⏳ |
| `/app/settings/master-data` | ข้อมูลหลัก (parent) | ⏳ |
| `/app/settings/ai` | ตั้งค่า AI | ⏳ |
| `/app/settings/package` | แพ็กเกจการใช้งาน | ⏳ |
| `/app/settings/features` | การตั้งค่าการใช้งานฟังก์ชัน | ⏳ |

### ตั้งค่า → ข้อมูลหลัก (nested)

| Route | Label (TH) | สถานะ |
|-------|------------|--------|
| `/app/settings/master-data/customer-type` | ประเภทลูกค้า | ⏳ |
| `/app/settings/master-data/business-type` | ประเภทธุรกิจ | ⏳ |
| `/app/settings/master-data/lead-source` | แหล่งที่มาของลูกค้า | ⏳ |
| `/app/settings/master-data/sales-stage` | ขั้นตอนการขาย | ⏳ |
| `/app/settings/master-data/product-category` | หมวดหมู่สินค้า | ⏳ |
| `/app/settings/master-data/region` | ภูมิภาค | ⏳ |
| `/app/settings/master-data/tier` | ระดับ | ⏳ |
| `/app/settings/master-data/unit` | หน่วย | ⏳ |
| `/app/settings/master-data/tags` | แท็ก | ⏳ |
| `/app/settings/master-data/lost-reason` | เหตุผลที่แพ้ | ⏳ |

---

## Sprint แนะนำ (ลำดับ implement)

1. Auth + layout guard
2. Leads inbox / list — reuse composables จาก `frontend/`
3. Customers hub + C360 (`/app/customers`, `/app/customers/:id`) — ดู [KUTO-CUSTOMERS-IA.md](./KUTO-CUSTOMERS-IA.md) · [CUSTOMER-360-FUNCTIONAL-SPEC.md](../07-phases/CUSTOMER-360-FUNCTIONAL-SPEC.md)
4. Opportunities pipeline
5. Settings → Master Data (align `frontend/` setup routes)
