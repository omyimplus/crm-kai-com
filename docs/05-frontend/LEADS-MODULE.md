# Leads Module — Phase 2 Design Spec

> **Phase:** 2 — CRM Menu (ถัดจาก Tasks ✅)  
> **Route:** `/app/leads` · สร้าง `/app/leads/new` · แก้ไข `/app/leads/:id/edit`  
> **สถานะ:** ✅ implement v1 — migrations `20260608120075_leads_module.sql` · `20260608120076_leads_contact_id.sql`  
> **อ้างอิง UI เก่า:** รายการลีด · สรุปการ์ด · filter สถานะ/แหล่งที่มา · ฟอร์ม New Lead (หน้าเต็ม + sidebar Actions)

---

## เป้าหมาย

หน้า **Lead** สำหรับรับและคัดกรองลูกค้าเป้าหมายก่อนแปลงเป็น Opportunity — มี **คะแนนลีด (Lead Score)** มูลค่าที่เป็นไปได้ และมอบหมายเจ้าของ/ทีมขาย

Flow ถัดไป: **Lead → Opportunity → Quotation → …** (ดู [APP-MENU.md](./APP-MENU.md))

---

## ข้อจำกัด / หลักการ

| หัวข้อ | กำหนด |
|--------|--------|
| Phase | 2 — ทำหลัง Tasks ship |
| สถานะ workflow | จาก **`module_statuses`** (`module_key = lead`) — ไม่ hardcode enum ใน UI |
| เลขที่ลีด | **`job_code_sequences`** — module `lead` · running อัตโนมัติ (read-only หลังสร้าง) |
| Priority | enum — High / Medium / Low (คงที่ v1 · badge ขนาดเล็กแบบ Tasks) |
| Lead score | 0–100 · slider ในฟอร์ม · สีวงกลมใน list ตามช่วงคะแนน |
| สิทธิ์ | `app.lead` — view / create / edit / delete (org role templates มีแล้ว) |
| DB | RLS + `org_id` + `data_change_logs` ทุก CRUD |
| i18n | th + en — key `appMenu.lead.*` / `leads.*` |
| ฟอร์ม | **หน้าเต็ม** (pattern Customer) — **ไม่ใช้ modal** แบบ Tasks |

**แหล่งที่มา (Source):** FK → `lead_sources` (Master Data `/app/lead-source`)

**ลูกค้า:** toggle **ลูกค้าในระบบ** / **ลูกค้าใหม่**

| โหมด | พฤติกรรม |
|------|----------|
| **ลูกค้าในระบบ** | ค้นหาเลือก `companies` · แสดง `MasterDataCustomerForm` แบบ **readonly** |
| **ลูกค้าใหม่** | ฟอร์มเดียวกับหน้าสร้างลูกค้า · validate `validateMasterCustomerForm` · **สร้าง company ทันที** ตอนบันทึกลีด |

ข้อมูลลูกค้า sync ลง snapshot บน `leads` (email · phone · tax · ที่อยู่ bill default · ฯลฯ) ผ่าน `syncLeadFieldsFromCustomer`

---

## อ้างอิง mockup (ระบบเก่า)

| หน้า | รายละเอียด |
|------|-------------|
| รายการ | การ์ดสรุป 3 ใบ · ค้นหา · filter สถานะ + แหล่งที่มา · table/grid toggle · คอลัมน์ Score / ชื่อ / Company / Email / Phone / Source / สถานะ / Actions |
| สร้าง — General | grid 3 คอลัมน์ · Lead Type · Owner · Tele Sale · Company · Email* · Phone · Tax ID · Mobile* · Lead Value · Customer Type · Industry Segment · Lead Source · Grade · Status* · Priority · Next Action Date · Next Action |
| สร้าง — ด้านล่าง | Lead Score (slider 0–100) · Customer Message / Requirement · Address (ถนน · ตำบล · อำเภอ · จังหวัด · รหัสไปรษณีย์) |
| Actions sidebar | ปุ่ม **Create Lead** / **Save** ด้านขวา (sticky) |

---

## หน้ารายการ (`/app/leads`)

```
┌─────────────────────────────────────────────────────────────────────┐
│  ลีด                                    [ + ลีดใหม่ ]               │
│  จัดการลีดพร้อมการให้คะแนน                                          │
├─────────────────────────────────────────────────────────────────────┤
│  [🎯 ลีดที่ใช้งาน: 4]  [✨ ลีดร้อนแรง 80+: 0]  [฿ มูลค่าที่เป็นไปได้] │
├─────────────────────────────────────────────────────────────────────┤
│  [🔍 ค้นหาลีด...]  [▼ ทุกสถานะ]  [▼ ทุกแหล่งที่มา]   [ grid | list ] │
├─────────────────────────────────────────────────────────────────────┤
│  Score │ ชื่อ │ Company │ อีเมล │ โทร │ Source │ สถานะ │ Actions   │
│   (41) │ ...  │ ...     │ ...   │ ... │ ...    │ badge │ ✏️  ⋯      │
└─────────────────────────────────────────────────────────────────────┘
```

### การ์ดสรุป (summary cards)

| การ์ด | นิยาม v1 | หมายเหตุ |
|--------|----------|----------|
| **ลีดที่ใช้งาน** | จำนวน lead active ใน **ชุดที่ตรงตัวกรองปัจจุบัน** (ยกเว้นกรองลีดร้อนแรง) | icon target |
| **ลีดร้อนแรง (80+)** | จำนวน hot ในชุดเดียวกัน | กดเพื่อกรองรายการ |
| **มูลค่าที่เป็นไปได้** | ผลรวม `lead_value` ของ active ในชุดเดียวกัน | มีตัวกรอง → label「มูลค่า (ตามตัวกรอง)」 |

### Filter / มุมมอง

| องค์ประกอบ | v1 |
|-----------|-----|
| ค้นหา | subject ชื่อลีด · company · email · phone · lead code · owner |
| สถานะ | **ชิปสถานะ** จาก `module_statuses` active · ค่าเริ่ม = ทุกสถานะ |
| ลีดร้อนแรง | กดการ์ดสรุป「ลีดร้อนแรง」→ กรอง `lead_score >= 80` |
| แหล่งที่มา | dropdown จาก `lead_sources` active |
| ช่วงวันที่ | `AppDateRangeFilter` — default เดือนปัจจุบัน · เลือกอิง **วันที่สร้าง** หรือ **ดำเนินการถัดไป** |
| table / grid | ✅ `AppViewModeToggle` — default **table** |
| เรียงลำดับ | คะแนนสูงก่อน · แล้ว `updated_at` ล่าสุด |
| คลิกแถว | — (ใช้ปุ่มดู) |
| Actions | ดู (eye) · แก้ไข · ลบ |

### คอลัมน์ตาราง (v1.1)

| คอลัมน์ | เนื้อหา |
|---------|---------|
| **ลีด** | วงคะแนน · ชื่อผู้ติดต่อ/ลูกค้า · รหัสลีด · badge ความสำคัญ · ชื่อบริษัท (ถ้าต่างจากหัวข้อ) |
| **มูลค่า** | `lead_value` format สกุล |
| **ดำเนินการถัดไป** | วันที่ + ข้อความ (md+) |
| **แหล่งที่มา** | `lead_source_name` (lg+) |
| **เจ้าของลีด** | `owner_name` (lg+) |
| **เทเลเซลล์** | `tele_sale_name` (lg+) |
| **สถานะ** | badge จาก module status |
| **Actions** | แก้ไข · ลบ |

Component: `LeadsLeadTable.vue`

### คอลัมน์ Score (list)

| ช่วงคะแนน | สีวงกลม (แนะนำ) |
|-----------|------------------|
| 0–39 | แดง |
| 40–79 | ส้ม |
| 80–100 | เขียว / primary (hot) |

แสดงตัเลขกลางวง · ไม่ใช้ badge ข้อความ

### คอลัมน์สถานะ

- Badge จาก `module_statuses.color` + ชื่อแสดง (i18n mapping `leads.statusCodes.*` เมื่อมี)
- ตัวอย่าง mockup: Converted · Contacted · Qualified

---

## หน้าสร้าง / แก้ไข

**Route (ห้ามใช้ `leads.vue` + `leads/new.vue` พร้อมกัน — ดู rule nested routes):**

```
pages/app/leads/
  index.vue          ← รายการ
  new.vue            ← สร้าง
  [id]/
    index.vue        ← ดู ✅
    edit.vue         ← แก้ไข
```

**Layout:** เนื้อหาซ้าย (sections ใน card) · **sidebar ขวา** — กล่อง ACTIONS + ปุ่ม primary

```
┌──────────────────────────────────────────────────┬─────────────────┐
│  ←  New Lead                                     │  ACTIONS        │
│  Fill in the details…          [ Lead badge ]    │                 │
├──────────────────────────────────────────────────┤  [ Create Lead ]│
│  General Information (grid 3 cols)               │                 │
│  …                                               │                 │
├──────────────────────────────────────────────────┤                 │
│  Lead Score          0 / 100                     │                 │
│  [====●────────────────────────────] 0…100        │                 │
├──────────────────────────────────────────────────┤                 │
│  Customer Message / Requirement                  │                 │
│  [ textarea … ]                                  │                 │
├──────────────────────────────────────────────────┤                 │
│  Address                                         │                 │
│  Street · Sub-district | District                │                 │
│  Province | Postal Code                          │                 │
└──────────────────────────────────────────────────┴─────────────────┘
```

---

## ฟิลด์หลัก (Leads v1)

### ลูกค้า (ระหว่างข้อมูลทั่วไปกับคะแนนลีด)

| โหมด UI | พฤติกรรม | Component |
|---------|----------|-----------|
| **ลูกค้าในระบบ** | ค้นหาเลือก `companies` · แสดงฟอร์มลูกค้า **readonly** | `LeadsCustomerSection` + `MasterDataCustomerForm` |
| **ลูกค้าใหม่** | ฟอร์มเดียวกับ `/app/customer/new` · `validateMasterCustomerForm` · **create company ก่อนบันทึกลีด** | เหมือนบน |

- บันทึกลีด: `syncLeadFieldsFromCustomer()` คัดลอก snapshot (email · phone · mobile · tax · type · segment · grade · ที่อยู่ bill default) ลงคอลัมน์ `leads.*`
- แก้ไขลีดที่ผูก `company_id` แล้ว → lock โหมด **ลูกค้าในระบบ**

### ข้อมูลลีด (section ด้านล่าง — แก้ไขได้)

| ฟิลด์ UI | คีย์ DB | Required | หมายเหตุ |
|----------|---------|----------|----------|
| Lead Type | `lead_type` | | enum — ดู [§ Lead type](#lead-type) |
| Leads Owner (Sales) | `owner_id` | | FK → `profiles` |
| Tele Sale | `tele_sale_id` | | FK → `profiles` |
| Name | `full_name` | | ชื่อผู้ติดต่อ/ลีด (ไม่ใช่ชื่อบริษัท) |
| Lead Value | `lead_value` | | numeric(15,2) default 0 |
| Lead Source | `lead_source_id` | | FK → `lead_sources` |
| Lead Status | `module_status_id` | ✅ | FK → `module_statuses` (`module_key = lead`) |
| Priority | `priority` | | `high` \| `medium` \| `low` |
| Next Action Date | `next_action_at` | | date |
| Next Action | `next_action` | | text |

### Snapshot จากลูกค้า (readonly บน DB หลัง sync — ไม่แสดงเป็นฟิลด์แก้ไขใน section ลีด)

| คีย์ DB | แหล่ง |
|---------|--------|
| `company_id` | ลูกค้าในระบบ หรือ company ที่สร้างใหม่ |
| `company_name`, `email`, `phone`, `mobile`, `tax_id` | จาก `MasterCustomerFormInput` |
| `customer_type`, `industry_segment`, `sales_grade` | จากลูกค้า |
| `address_*` | จาก bill address default (flatten ลง `leads`) |

### Lead type

| slug | Label EN | Label TH |
|------|----------|----------|
| `end_user` | End User | ผู้ใช้ปลายทาง |
| `dealer` | Dealer | ตัวแทนจำหน่าย |
| `contractor` | Contractor | ผู้รับเหมา |
| `distributor` | Distributor | ผู้จัดจำหน่าย |
| `oem` | OEM | OEM |
| `other` | Other | อื่นๆ |

เก็บเป็น CHECK constraint + config `masterLeads.ts` — migration `20260608120080_*`

### Lead Score

| ฟิลด์ | หมายเหตุ |
|--------|----------|
| `lead_score` | integer 0–100 · slider + ตัวเลข `n / 100` · default 0 |

### Customer Message / Requirement

| ฟิลด์ | หมายเหตุ |
|--------|----------|
| `requirement` | text · textarea |

### Address

| ฟิลด์ UI | คีย์ DB |
|----------|---------|
| Street Address | `address_street` |
| Sub-district | `address_sub_district` |
| District | `address_district` |
| Province | `address_province` |
| Postal Code | `address_postal_code` |

v1 เก็บ flat columns บน `leads` — **ไม่แยกตารางที่อยู่** (ต่างจาก Customer ship/bill)

### ระบบ / audit

| ฟิลด์ | หมายเหตุ |
|--------|----------|
| `lead_code` | auto `generate_job_code('lead')` · แสดง read-only ตอน edit |
| `org_id`, `created_by`, `created_at`, `updated_at`, `deleted_at` | มาตรฐาน CRM |
| `converted_opportunity_id` | nullable · v1.1 เมื่อกด Convert |

---

## มอบหมาย — ทีมขาย vs บุคคล (Tasks pattern)

ใน mockup มี **Leads Owner** และ **Tele Sale** แยกกัน — **ไม่ใช่** toggle ทีม/บุคคลแบบ Tasks

| ฟิลด์ | v1 |
|--------|-----|
| Owner | บุคคล (profile) — ผู้รับผิดชอบหลัก |
| Tele Sale | บุคคล (profile) — ผู้ดูแล telesales |
| Sales team | **v1.1** — `sales_team_id` optional ถ้าต้องการมอบทั้งทีม ( mutual exclusive กับ owner ตาม pattern Tasks) |

---

## Seed Master Data — lazy per module

**ฟังก์ชัน:** ขยาย `seed_org_module_defaults(p_org_id, p_module_key)` เมื่อ `p_module_key = 'lead'`

**Default สถานะ (`module_key = lead`):**

| status_code | name | is_default | หมายเหตุ |
|-------------|------|------------|----------|
| `NEW` | New | ✅ | ค่าเริ่มฟอร์ม |
| `OPEN` | Open | | |
| `CONTACTED` | Contacted | | |
| `NURTURING` | Nurturing | | |
| `QUALIFIED` | Qualified | | |
| `UNQUALIFIED` | Unqualified | | ปิด loop · ไม่นับใน “ลีดที่ใช้งาน” |
| `CANCELLED` | Cancelled | | ปิด loop · ไม่นับใน “ลีดที่ใช้งาน” |
| `CONVERTED` | Converted | | ปิด loop · ไม่นับใน “ลีดที่ใช้งาน” |

**Job code:** prefix `LD` (หรือ `LEAD`) · pad 4 · lazy seed คู่กับสถานะ

**Lead source:** org สร้างเองที่ `/app/lead-source` — แนะนำ seed “Other” ถ้ายังไม่มี

---

## Scope v1 vs v1.1

| รายการ | v1 | v1.1+ |
|--------|----|-------|
| List + summary cards | ✅ | |
| Search + filter status/source | ✅ | |
| table / grid toggle | ✅ | |
| Create / Edit หน้าเต็ม + sidebar | ✅ | |
| Lead score slider | ✅ | |
| Address + requirement | ✅ | |
| Link / สร้าง Company | ✅ toggle ลูกค้าในระบบ / ลูกค้าใหม่ + create ก่อนบันทึกลีด | |
| Soft delete + activity log | ✅ | |
| Convert → Opportunity | ✅ | |
| `sales_team_id` assignment | | ✅ |
| Import CSV | | ✅ |
| Kanban by status | | พิจารณา |

---

## Backend (แผน)

```
supabase/migrations/
  YYYYMMDD_leads_module.sql
    - leads table + indexes
    - seed_org_module_defaults() + module lead
    - generate_job_code('lead') sequence backfill
    - list_leads / create_lead / update_lead / soft_delete_lead
    - RLS + data_change_logs
    - block delete module_status ถ้ามี lead active (pattern Tasks)
```

**ตาราง `leads` (สรุป):** ฟิลด์ใน [§ ฟิลด์หลัก](#ฟิลด์หลัก-leads-v1) + FK ที่ระบุ

→ อัปเดต [tables.md](../06-crm-schema/tables.md) เมื่อมี migration

---

## Frontend (แผน)

```
frontend/app/
  config/masterLeads.ts           ← lead_type, priority, score tiers
  utils/masterLeads.ts            ← form validation, payload, display helpers
  composables/useLeads.ts
  components/leads/
    LeadsCustomerSection.vue      ← toggle ลูกค้าในระบบ/ใหม่ + MasterDataCustomerForm
    LeadsSummaryCards.vue
    LeadsForm.vue                 ← ข้อมูลลีด (type · owner · score · requirement)
    LeadsScoreBadge.vue           ← วงกลมคะแนน list/grid
    LeadsPriorityBadge.vue        ← reuse pattern TasksPriorityBadge
    LeadsStatusBadge.vue
    LeadsFormActions.vue          ← sidebar Create/Save
  pages/app/leads/
    index.vue
    new.vue
    [id]/edit.vue
```

**Shared components:** `AppDataTable` · `AppViewModeToggle` · `AppDateRangeFilter` (ถ้า filter วันที่ next action ใน v1.1) · `AppDialogFooter` ไม่ใช้สำหรับฟอร์มหลัก

---

## ความสัมพันธ์กับ Master Data

| Master | การใช้ใน Leads |
|--------|----------------|
| Module statuses (`lead`) | dropdown สถานะ · badge list · default NEW |
| Job code (`lead`) | `lead_code` ตอน create |
| Lead source | dropdown Source |
| Customer fields | reuse enums `customer_type`, `industry_segment`, `sales_grade` |
| System users (profiles) | Owner · Tele Sale |
| Sales team | v1.1 |

---

## i18n (ร่าง key)

| Prefix | ตัวอย่าง |
|--------|----------|
| `leads.pageTitle` | ลีด (Lead) |
| `leads.pageSubtitle` | จัดการลีดพร้อมการให้คะแนน |
| `leads.newLead` | ลีดใหม่ |
| `leads.summary.*` | active · hot · potentialValue |
| `leads.fields.*` | ตามตารางฟิลด์ |
| `leads.options.leadType.*` | end_user … other |
| `leads.options.priority.*` | high / medium / low |
| `leads.statusCodes.*` | NEW, CONTACTED, … |

---

## เอกสารที่เกี่ยวข้อง

- [APP-MENU.md](./APP-MENU.md) — CRM navigation
- [TASKS-MODULE.md](./TASKS-MODULE.md) — pattern โมดูล CRM Menu ก่อนหน้า
- [LEAD-SOURCE-MASTER-FIELDS.md](../06-crm-schema/LEAD-SOURCE-MASTER-FIELDS.md)
- [CUSTOMER-MASTER-FIELDS.md](../06-crm-schema/CUSTOMER-MASTER-FIELDS.md) — reuse enums
- [MASTER-DATA-MENU.md](./MASTER-DATA-MENU.md) — module statuses · job code
- [QA-LEADS.md](../11-dev-setup/QA-LEADS.md) — checklist tester สร้างลีด (ลูกค้าเก่า + ใหม่)
- [06-crm-schema/tables.md](../06-crm-schema/tables.md)

→ [CHANGELOG.md](./CHANGELOG.md)
