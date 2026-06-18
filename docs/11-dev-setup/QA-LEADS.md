# QA Checklist — Leads: สร้างลีด (ลูกค้าเก่า + ลูกค้าใหม่)

> **ใช้คู่กับ:** [QA-GUIDE.md](./QA-GUIDE.md) (ชั้น 0–7)  
> **Module:** `/app/leads` · `/app/leads/new` · `/app/leads/:id/edit`  
> **Spec:** [LEADS-MODULE.md](../05-frontend/LEADS-MODULE.md)  
> **อัปเดต:** 2026-06-18

---

## วิธีใช้

1. อ่าน [QA-GUIDE.md](./QA-GUIDE.md) — ทำ **ชั้น 0 → 7** ตามลำดับ  
2. เตรียมข้อมูลตาม [§ ข้อมูลทดสอบ](#ข้อมูลทดสอบ-test-fixtures)  
3. รัน **Flow A** (ลูกค้าในระบบ) และ **Flow B** (ลูกค้าใหม่) ครบทุกขั้น  
4. ติ๊ก `[ ]` → `[x]` ใน checklist ด้านล่าง  
5. บัคใส่ตาราง **บัคที่พบ (รอบล่าสุด)** — รูปแบบเดียวกับ QA-GUIDE

**Login แนะนำ:** `browser-test-owner@crm-kai.test` / `testpass123` (หรือ `tester1` / `testpass123`)

---

## ข้อมูลทดสอบ (Test fixtures)

### ลูกค้าในระบบ (สำหรับ Flow A)

สร้างล่วงหน้าที่ `/app/customer/new` หรือใช้ลูกค้า seed — บันทึกชื่อไว้ค้นหาในฟอร์มลีด

| ฟิลด์ | ค่าตัวอย่าง (A1) | หมายเหตุ |
|--------|------------------|----------|
| ชื่อบริษัท | `QA Lead Customer A1` | ใช้ค้นหาใน dropdown |
| Customer Type | Company / นิติบุคคล | |
| Email | `qa-lead-a1@crm-kai.test` | |
| Phone | `021234567` | required ลูกค้า |
| Mobile | `0812345001` | |
| Industry Segment | Technology / เทคโนโลยี | |
| Sales Grade | A | |
| Tax ID | `1234567890123` | 13 หลัก |
| Bill To (default) | `99/1 ถ.ทดสอบ กรุงเทพฯ` | จะ snapshot ลง `leads.address_street` |

### ลูกค้าใหม่ (สำหรับ Flow B — ยังไม่มีในระบบ)

| ฟิลด์ | ค่าตัวอย่าง (B1) | หมายเหตุ |
|--------|------------------|----------|
| ชื่อบริษัท | `QA Lead Customer B1 NEW` | **ต้องไม่ซ้ำ** ลูกค้าเดิม |
| Customer Type | Individual / บุคคลธรรมดา | ทดสอบล็อก Industry Segment |
| Email | `qa-lead-b1@crm-kai.test` | |
| Phone | `022345678` | |
| Mobile | `0812345002` | |
| Bill To | `88/2 ซ.ใหม่ นนทบุรี` | |

### ข้อมูลลีด (ใช้ร่วมทั้ง 2 Flow)

| ฟิลด์ | ค่าตัวอย่าง | หมายเหตุ |
|--------|-------------|----------|
| Lead Type | End User / ผู้ใช้ปลายทาง | default |
| Owner | ตัวเอง (owner login) | auto-fill ตอน new |
| Tele Sale | — ไม่ระบุ — | optional |
| Contact name | `คุณทดสอบ ลีด` | `full_name` |
| Lead Value | `150000` | |
| Lead Source | แหล่งที่มา active ใดก็ได้ | จาก Master Data |
| Status | **NEW** (default) หรือสถานะ active | required |
| Priority | High | |
| Next Action Date | วันนี้ + 7 วัน | |
| Next Action | `โทรติดตามครั้งแรก` | |
| Lead Score | `85` (Hot) หรือทดสอบ preset `100` | |
| Requirement | `ต้องการใบเสนอราคา CRM` | |

---

## ลำดับฟอร์ม (UI ปัจจุบัน)

```text
1. ข้อมูลทั่วไป (Lead Type · Owner · Status · …)
2. ลูกค้า (toggle ลูกค้าในระบบ / ลูกค้าใหม่)
3. คะแนนลีด
4. ความต้องการลูกค้า
```

---

## ชั้น 0 — Environment

- [ ] Dev server สะอาด (ไม่มี WARN/ERROR ใน terminal)
- [ ] Login owner ได้ → `/app/leads` โหลดได้
- [ ] Migration ลีด apply แล้ว + `NOTIFY pgrst, 'reload schema';`

| ลำดับ | ไฟล์ | ต้องมี |
|------|------|--------|
| 56 | `20260608120056_lead_sources.sql` | แหล่งที่มาลีด |
| 75 | `20260608120075_leads_module.sql` | ตาราง `leads` + RPC หลัก |
| 76 | `20260608120076_leads_contact_id.sql` | `contact_id` + RPC อัปเดต |
| 77 | `20260608120077_lead_status_catalog.sql` | สถานะ 8 รายการ |
| 79 | `20260608120079_industry_segment_catalog.sql` | Industry Segment catalog |
| 80 | `20260608120080_restore_customer_type_lead_type_channel.sql` | customer_type กลับ company/individual · lead_type channel |

- [ ] มีลูกค้าอย่างน้อย 1 รายการ (Flow A)
- [ ] มี `lead_sources` active ≥ 1 รายการ
- [ ] มี `module_statuses` สำหรับ `module_key = lead` (หลัง 077 มี 8 สถานะ)

---

## ชั้น 1 — Database

```sql
-- RPC ลีดต้องมีครบ
SELECT proname FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
  AND proname IN (
    'list_leads', 'create_lead', 'update_lead', 'soft_delete_lead',
    'ensure_lead_module_defaults', 'generate_job_code'
  )
ORDER BY proname;
```

- [ ] RPC ครบ ไม่ 404
- [ ] `leads_customer_type_check` → `company`, `individual`
- [ ] `leads_lead_type_check` → `end_user`, `dealer`, `contractor`, `distributor`, `oem`, `other`
- [ ] RLS: user org เดียวกัน SELECT/INSERT ได้ · org อื่นไม่เห็น

---

## ชั้น 2 — API (RPC ตรง)

### สร้างลีด + ลูกค้าในระบบ (จำลอง Flow A)

```sql
-- แทน :company_id ด้วย UUID ลูกค้า A1
SELECT public.create_lead(jsonb_build_object(
  'lead_type', 'end_user',
  'email', 'qa-lead-api-a@crm-kai.test',
  'mobile', '0811111111',
  'company_id', ':company_id',
  'company_name', 'QA Lead Customer A1',
  'customer_type', 'company',
  'industry_segment', 'technology',
  'sales_grade', 'a',
  'lead_score', 75,
  'lead_value', 100000,
  'priority', 'high',
  'module_status_id', (
    SELECT id FROM module_statuses
    WHERE module_key = 'lead' AND code = 'NEW' AND deleted_at IS NULL
    LIMIT 1
  )
));
```

- [ ] L-A1 `create_lead` + `company_id` สำเร็จ · ได้ `lead_code` (prefix LD)
- [ ] L-A2 snapshot: `email`, `mobile`, `customer_type`, `industry_segment`, `sales_grade` ตรง payload
- [ ] L-A3 `email` ว่าง → error `Email required`
- [ ] L-A4 `mobile` ว่าง → error `Mobile required`
- [ ] L-A5 `lead_score` 101 → error `Invalid lead score`
- [ ] L-A6 `customer_type` ค่าปลอม → CHECK fail

### สร้างลูกค้าแล้วสร้างลีด (จำลอง Flow B — 2 ขั้น)

- [ ] L-B1 `create_company` ด้วยข้อมูล B1 สำเร็จ
- [ ] L-B2 `create_lead` ชี้ `company_id` ใหม่ · snapshot จาก B1
- [ ] L-B3 `customer_type = individual` บน company + lead ได้

### อื่น ๆ

- [ ] L-U1 `update_lead` เปลี่ยน score + status
- [ ] L-D1 `soft_delete_lead` → `deleted_at` ไม่ null · หายจาก `list_leads`

---

## ชั้น 3 — UI

### รายการ (`/app/leads`)

- [ ] U-L1 การ์ดสรุป 3 ใบแสดงตัวเลข
- [ ] U-L2 ค้นหา · filter สถานะ · filter แหล่งที่มา
- [ ] U-L3 สลับ list / grid
- [ ] U-L4 ปุ่ม **ลีดใหม่** → `/app/leads/new`

### Flow A — ลูกค้าในระบบ (`/app/leads/new`)

| # | ขั้นตอน | คาดหวัง |
|---|---------|---------|
| A-UI-1 | เปิด `/app/leads/new` | Status default = NEW · Owner = ตัวเอง · Lead Type = End User |
| A-UI-2 | กรอกข้อมูลทั่วไป (ตาราง fixture) | ฟิลด์รับค่าได้ |
| A-UI-3 | เลือก **ลูกค้าในระบบ** | toggle ถูกต้อง |
| A-UI-4 | ค้นหาเลือก `QA Lead Customer A1` | โหลดฟอร์มลูกค้า **readonly** |
| A-UI-5 | ตรวจฟิลด์ลูกค้า | Email · Phone · Mobile · Type · Segment · Grade ตรง A1 · แก้ไม่ได้ |
| A-UI-6 | ตั้ง Lead Score = 85 | gauge สีเขียว / Hot |
| A-UI-7 | กรอก Requirement | |
| A-UI-8 | กด **สร้างลีด** (sidebar) | redirect `/app/leads/:id/edit` · แสดง `lead_code` |
| A-UI-9 | เปิดรายการลีด | แถวใหม่มี Score · ชื่อ · ลูกค้า · อีเมล · สถานะ |

**Checklist:**

- [ ] A-UI-1 … A-UI-9 ผ่าน
- [ ] A-UI-10 ไม่เลือกลูกค้า → กดบันทึก → ข้อความ `กรุณาเลือกลูกค้า` / customer required
- [ ] A-UI-11 ลบ Email/Mobile ในขั้นตอนก่อนบันทึก — **ไม่ควรทำได้** (readonly จากลูกค้า) · ถ้า snapshot ว่าง validate ชัด

### Flow B — ลูกค้าใหม่ (`/app/leads/new`)

| # | ขั้นตอน | คาดหวัง |
|---|---------|---------|
| B-UI-1 | เลือก **ลูกค้าใหม่** | ฟอร์มลูกค้า editable · ว่าง/default |
| B-UI-2 | กรอกข้อมูลลูกค้า B1 | Customer Type = Individual → Industry Segment **disabled** |
| B-UI-3 | กรอก Bill To default | |
| B-UI-4 | กรอกข้อมูลลีด + Score + Requirement | |
| B-UI-5 | กด **สร้างลีด** | สำเร็จ · redirect edit |
| B-UI-6 | ไป `/app/customer` | มีลูกค้า `QA Lead Customer B1 NEW` **ใหม่** |
| B-UI-7 | เปิดลูกค้า B1 | ข้อมูลตรงที่กรอก · Individual · ไม่มี industry |

**Checklist:**

- [ ] B-UI-1 … B-UI-7 ผ่าน
- [ ] B-UI-8 ชื่อลูกค้าว่าง → error validation ลูกค้า (name required)
- [ ] B-UI-9 Phone ลูกค้าว่าง → phone required
- [ ] B-UI-10 Email ลูกค้าว่าง → email required
- [ ] B-UI-11 Status ลีดว่าง → status required

### แก้ไขลีด (หลังสร้าง)

- [ ] E-UI-1 ลีดที่มี `company_id` → toggle ลูกค้า **ล็อก** โหมด ลูกค้าในระบบ
- [ ] E-UI-2 แก้ Lead Score · Status · Requirement → บันทึกได้
- [ ] E-UI-3 ลีดที่สร้างจากลูกค้าใหม่ (ไม่มี company_id ใน DB เก่า?) — **ตรวจจริง:** หลัง Flow B ต้องมี `company_id` → lock existing

### i18n

- [ ] I-1 สลับ TH → label ฟอร์มเป็นภาษาไทย (Lead type · ลูกค้าในระบบ · คะแนนลีด)
- [ ] I-2 สลับ EN → ภาษาอังกฤษ · ไม่มี key หลุด

---

## ชั้น 4 — Permission

- [ ] P-L1 Owner — สร้าง/แก้/ลบลีดได้
- [ ] P-L2 Employee (มีสิทธิ์ `app.lead` create) — สร้างได้
- [ ] P-L3 Employee **ไม่มี**สิทธิ์ lead — ไม่เห็นเมนู / 403
- [ ] P-L4 Readonly profile — `create_lead` Forbidden

---

## ชั้น 5 — E2E Flow

### Flow A (ลูกค้าเก่า) — E2E

```text
เตรียมลูกค้า A1 → /app/leads/new
  → กรอกลีด → เลือกลูกค้า A1 (readonly)
  → บันทึก → ตรวจรายการ + edit
  → SQL: leads.company_id = A1.id · snapshot ตรง
```

- [ ] E2E-A ครบ journey

### Flow B (ลูกค้าใหม่) — E2E

```text
/app/leads/new → ลูกค้าใหม่ B1
  → กรอกลูกค้า + ลีด → บันทึก
  → ตรวจ /app/customer มี B1
  → ตรวจลีดชี้ company_id ของ B1
  → แก้โปรไฟล์ลูกค้า B1 ภายหลัง → ลีด snapshot **ไม่เปลี่ยน** (by design)
```

- [ ] E2E-B ครบ journey
- [ ] E2E-B2 ยืนยัน snapshot ไม่ live-sync หลังแก้ลูกค้า

### Flow เปรียบเทียบ

| หัวข้อ | Flow A (เก่า) | Flow B (ใหม่) |
|--------|---------------|---------------|
| สร้าง `companies` | ไม่ (มีแล้ว) | ใช่ ก่อน `create_lead` |
| ฟอร์มลูกค้า | readonly | editable เต็ม |
| `company_id` บน lead | มีทันที | มีหลัง create company |
| Validation ลูกค้า | เลือกลูกค้า required | `validateMasterCustomerForm` |
| Industry Segment | จากลูกค้า | จากฟอร์ม (Individual = ไม่ระบุ) |

- [ ] E2E-C เปรียบเทียบตารางด้านบนตรง implementation

---

## ชั้น 6 — Audit

หลัง Flow A และ B:

```sql
SELECT action, entity_type, summary, created_at
FROM data_change_logs
WHERE entity_type IN ('leads', 'companies')
ORDER BY created_at DESC
LIMIT 20;
```

- [ ] A-LOG-1 Flow A: log `create` / `leads` เท่านั้น (ไม่สร้าง company ซ้ำ)
- [ ] B-LOG-2 Flow B: log `create` / `companies` **แล้ว** `create` / `leads`
- [ ] B-LOG-3 snapshot ใน log มี email · customer_type · lead_type

---

## ชั้น 7 — Bypass / นอกระบบ

- [ ] X-L1 ไม่ login → RPC `create_lead` ล้ม
- [ ] X-L2 `create_lead` ด้วย `company_id` org อื่น → error / RLS block
- [ ] X-L3 REST INSERT ตรง `leads` (ถ้าทดสอบ) — บันทึก finding

---

## SQL ตรวจหลังบันทึก (ใช้ร่วม Flow A/B)

```sql
-- แทน :lead_id
SELECT
  lead_code,
  lead_type,
  company_id,
  company_name,
  email,
  mobile,
  phone,
  tax_id,
  customer_type,
  industry_segment,
  sales_grade,
  lead_score,
  lead_value,
  address_street,
  module_status_id
FROM leads
WHERE id = ':lead_id';
```

**คาดหวัง Flow A:**

| คอลัมน์ | ค่า |
|---------|-----|
| `company_id` | UUID ลูกค้า A1 |
| `customer_type` | `company` |
| `lead_type` | `end_user` (หรือที่เลือก) |
| `email` / `mobile` | ตรงลูกค้า A1 |
| `address_street` | Bill To default ของ A1 |

**คาดหวัง Flow B:**

| คอลัมน์ | ค่า |
|---------|-----|
| `company_id` | UUID ลูกค้า B1 (สร้างใหม่) |
| `customer_type` | `individual` |
| `industry_segment` | `NULL` |
| `company_name` | `QA Lead Customer B1 NEW` |

- [ ] SQL-A ตรง Flow A
- [ ] SQL-B ตรง Flow B

---

## บัคที่พบ (รอบล่าสุด)

| ID | Flow | ชั้น | สถานะ | หมายเหตุ |
|----|------|------|-------|----------|
| | | | | |

---

## ควรมีมากกว่านี้ (ยังไม่ครอบคลุมใน v1)

รายการด้านล่าง **ไม่อยู่ใน scope checklist ด้านบน** — แนะนำเพิ่มในรอบถัดไปหรือ Phase 2.1+

### ทดสอบอัตโนมัติ

| รายการ | เหตุผล |
|--------|--------|
| Unit test `validateLeadForm` · `syncLeadFieldsFromCustomer` · `validateLeadCustomerMode` | ยังไม่มี Vitest ใน `package.json` |
| E2E Playwright/Cypress สำหรับ Flow A/B | ลด regression เวลา refactor ฟอร์ม |
| CI รัน migration + smoke RPC | จับ CHECK constraint พังก่อน deploy |

### ฟีเจอร์ UI / ฟอร์ม

| รายการ | สถานะปัจจุบัน |
|--------|----------------|
| ที่อยู่ลีดแยก (ตำบล · อำเภอ · จังหวัด · รหัสไปรษณีย์) | มีคอลัมน์ DB · **ยังไม่มีฟิลด์ในฟอร์ม** — snapshot แค่ `address_street` จาก Bill To |
| เลือก Contact บนลีด | `contact_id` ใน DB · **UI ยังไม่ใช้** |
| แปลงลีด → Opportunity | v1.1 |
| มอบหมาย Sales Team | v1.1 |
| Import CSV | v1.1 |
| Kanban ตามสถานะ | พิจารณา |
| Soft delete จาก UI (เมนู ⋯) | มี RPC · ต้องทดสอบแยกจาก create flow |
| Duplicate lead / clone | ยังไม่มี |

### พฤติกรรมธุรกิจ

| รายการ | หมายเหตุ |
|--------|----------|
| แก้ลูกค้าในระบบหลังสร้างลีด | snapshot บน `leads` **ไม่อัปเดตตาม** — ต้องทดสอบ + สื่อสาร user |
| ลีดซ้ำ email เดียวกัน | ยังไม่มี unique constraint — ทดสอบว่าสร้างซ้ำได้หรือไม่ (document expected) |
| Lead Value สกุลเงิน / FX | เก็บ numeric อย่างเดียว |
| Tax ID บนลีด vs ลูกค้า | validate 13 หลักบน lead form · มาจาก snapshot |

### สิทธิ์และเมนู

| รายการ | หมายเหตุ |
|--------|----------|
| Org role template — `app.lead` แยก create/edit/delete | ทดสอบ matrix ครบทุก role ที่ seed |
| Employee ไม่มี Setup แต่มี lead | ตาม org role pages |

### Performance / Edge

| รายการ | หมายเหตุ |
|--------|----------|
| ลูกค้าในระบบจำนวนมาก (search dropdown) | pagination / async search |
| บันทึกลีดขณะ network ช้า | double-submit · loading state |
| สลับ toggle ลูกค้าใหม่ ↔ เก่า | state ฟอร์มรีเซ็ตถูกต้อง (ไม่ค้างข้อมูล B ในโหมด A) |

### เอกสาร / Data

| รายการ | หมายเหตุ |
|--------|----------|
| Seed ลูกค้า + ลีดตัวอย่างใน `seed.sql` | ลดเวลาเตรียม Flow A |
| สรุปการ์ด — นิยาม “ลีดที่ใช้งาน” | ไม่นับ CONVERTED / CANCELLED / UNQUALIFIED — ทดสอบหลังเปลี่ยนสถานะ |

---

## ลิงก์ที่เกี่ยวข้อง

- [LEADS-MODULE.md](../05-frontend/LEADS-MODULE.md)
- [CUSTOMER-MASTER-FIELDS.md](../06-crm-schema/CUSTOMER-MASTER-FIELDS.md)
- [QA-CUSTOMER-CONTACT.md](./QA-CUSTOMER-CONTACT.md) — เตรียมลูกค้า A1
- [TEST-ACCOUNTS.md](./TEST-ACCOUNTS.md)
