# Contact Master — ฟิลด์ UI และ spec สำหรับ SQL

> Mockup ฟอร์ม `/app/contact/new` · **Relation:** `contacts.company_id` → `companies.id` (Customer)  
> **Code:** `frontend/app/config/masterContact.ts` · **ฟอร์ม:** `MasterDataContactForm.vue`

---

## สถานะ DB ปัจจุบัน (`contacts`)

| Column | Type | บันทึกจาก UI | หมายเหตุ |
|--------|------|-------------|----------|
| `first_name` | text NOT NULL | ✅ | required |
| `last_name` | text NULL | ✅ | |
| `email` | text NULL | ✅ | required ใน validation UI |
| `phone` | text NULL | ✅ | required ใน validation UI |
| `mobile` | text NULL | ✅ | migration `20260608120038_*` |
| `company_id` | uuid NULL | ✅ | **FK → companies (Customer)** · required ใน UI |
| `job_title` | text NULL | ✅ | |
| `department` | text NULL | ✅ | |
| `contact_role` | text NULL | ✅ | slug · default `other` |
| `is_main_contact` | boolean | ✅ | Main Contact checkbox — **1 คนต่อลูกค้า** |
| `notes` | text NULL | ✅ | textarea |

→ รายละเอียดตาราง: [tables.md](./tables.md#contacts)

---

## Layout ฟอร์ม (2 คอลัมน์)

| Contact Info | Work Details |
|--------------|--------------|
| First Name * | Customer * (select → `company_id`) |
| Last Name | Job Title |
| Email * | Department |
| Phone * | Role (dropdown) |
| Mobile | Main Contact (checkbox) |
| | Notes |

---

## Customer relation (`company_id`)

- **UI label:** Customer / ลูกค้า
- **DB:** `contacts.company_id` → `companies.id` (ON DELETE ไม่ cascade ลบ contact — ใช้ SET NULL หรือ restrict ตาม FK เดิม)
- **Required:** บังคับใน UI Phase 1 (DB ยัง nullable สำหรับ legacy rows)
- **Dropdown:** รายชื่อ `companies` ใน org เดียวกัน (ไม่รวม soft-deleted ถ้ามี `deleted_at`)

---

## Contact role (`contact_role`)

**Default UI:** `other`

| slug | Label EN | Label TH |
|------|----------|----------|
| `decision_maker` | Decision maker | ผู้ตัดสินใจ |
| `influencer` | Influencer | ผู้ให้คำแนะนำ |
| `user` | User | ผู้ใช้งาน |
| `gatekeeper` | Gatekeeper | ผู้ประสาน |
| `other` | Other | อื่น ๆ |

**i18n:** `masterData.contact.options.role.{slug}`

---

## Main contact (`is_main_contact`)

- **กฎ:** ลูกค้า 1 รายมีผู้ติดต่อหลักได้ **ไม่เกิน 1 คน** (active, `deleted_at IS NULL`)
- **DB:** partial unique index `contacts_one_main_per_company_idx` บน `company_id`
- **RPC:** `create_contact` / `update_contact` — ถ้าตั้ง `is_main_contact = true` → `ensure_single_main_contact()` ยกเลิกคนเดิมของลูกค้านั้นก่อนบันทึก
- **Restore:** `restore_company` / `restore_contact` — dedupe หลังกู้คืน
- **Migration:** `20260608120045_contacts_single_main_contact.sql`
- **UI hint:** `masterData.contact.fields.mainContactHint` (th + en)

คนสำคัญหลายคน → ใช้ `contact_role` (ผู้ตัดสินใจ · ผู้ประสาน) แทน checkbox หลัก

---

## Validation UI (Phase 1)

| ฟิลด์ | กฎ |
|--------|-----|
| `first_name` | required |
| `email` | required |
| `phone` | required |
| `company_id` | required (ต้องเลือกลูกค้า) |

---

## หน้ารายการ — กรองตามลูกค้า

- **UI:** USelectMenu `searchable` (autocomplete) — เลือกบริษัท/ลูกค้า
- **ค่าเริ่มต้น:** ลูกค้าทั้งหมด (`companyFilter = null`)
- **Code:** `pages/app/contact/index.vue`

---

## Data change log (`data_change_logs`)

| action | RPC | entity_type |
|--------|-----|-------------|
| create | `create_contact` | `contacts` |
| update | `update_contact` | `contacts` |
| delete (soft) | `soft_delete_contact` | `contacts` |

**Snapshot:** `contact_log_snapshot(uuid)` — ไม่รวม `org_id` / audit cols  
**Frontend:** `useContacts` เรียก RPC เท่านั้น (ไม่ INSERT/UPDATE ตรง)  
**Migration:** `20260608120039_contacts_crud_rpc.sql`

→ [DATA-CHANGE-LOG.md](./DATA-CHANGE-LOG.md)

---

## Checklist

- [x] slug ตรง `CONTACT_*` ใน `masterContact.ts`
- [x] i18n th + en
- [x] [tables.md](./tables.md) + [DB-CHANGELOG.md](../02-database/DB-CHANGELOG.md)
- [x] `data_change_logs` ผ่าน RPC create/update/soft delete

---

## ลบ (soft delete)

- **UI:** ปุ่มลบบนหน้ารายการ + หน้ารายละเอียด · `MasterDataContactDeleteModal`
- **RPC:** `soft_delete_contact` → `data_change_logs`

---

## ความสัมพันธ์กับลูกค้า (company)

- **Required:** `company_id` ต้องชี้ลูกค้าที่ยัง active (`deleted_at IS NULL`)
- **ลบลูกค้า:** `soft_delete_company` cascade soft delete ผู้ติดต่อที่ผูกอยู่ทั้งหมด — ไม่ให้ contact active ค้าง FK กับลูกค้าที่ลบแล้ว
- **Trigger:** `contacts_block_deleted_company_trg` — กัน create/update contact ให้ผูกลูกค้าที่ soft delete แล้ว
- **รายการ/ดูรายละเอียด:** `useContacts` filter `companies!inner` + `companies.deleted_at IS NULL`
- **Migration:** `20260608120041_soft_delete_company_cascade_contacts.sql`

---

## กู้คืน (restore)

- **UI:** แท็บ **ใช้งาน / ถูกลบ** — owner + admin เท่านั้น (`useArchiveTabs`)
- **กู้ลูกค้า:** `restore_company` → cascade กู้ผู้ติดต่อที่ถูกลบพร้อมลูกค้า
- **กู้ผู้ติดต่อเดี่ยว:** `restore_contact` — ได้เมื่อลูกค้ายัง active · ถ้าลูกค้าถูกลบ → กู้จากแท็บถูกลบที่หน้าลูกค้า
- **Migration:** `20260608120043_restore_master_data.sql`

