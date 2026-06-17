# Changelog — CRM Schema

→ ออกแบบปัจจุบัน: [README.md](./README.md)  
→ **DB snapshot:** [../02-database/DB-SCHEMA.md](../02-database/DB-SCHEMA.md)  
→ **DB changes:** [../02-database/DB-CHANGELOG.md](../02-database/DB-CHANGELOG.md)

---

## ประวัติ

### 2026-06-17 — Customer CRUD RPC + Contact delete UI

- **ทำอะไร:** `create_company` / `update_company` logs · ลบ contact บน list/view · DB-SCHEMA sync
- **Migration:** `20260608120040_*`
- **Phase:** 1

### 2026-06-16 — Contact CRUD + data_change_logs

- **ทำอะไร:** RPC create/update/soft delete · อัปเดต CONTACT-MASTER-FIELDS §log · DATA-CHANGE-LOG
- **Migration:** `20260608120039_contacts_crud_rpc.sql`
- **Phase:** 1

### 2026-06-16 — CONTACT-MASTER-FIELDS + customer relation

- **ทำอะไร:** spec ฟอร์มผู้ติดต่อ · `company_id` → Customer · migration ฟิลด์ใหม่
- **ไฟล์ที่กระทบ:** `CONTACT-MASTER-FIELDS.md`, `tables.md`, `20260608120038_*`
- **Phase:** 1

### 2026-06-16 — tax_vat = WHT rates (§6.5)

- **ทำอะไร:** เปลี่ยน dropdown เป็นอัตราหัก ณ ที่จ่าย (ไม่หัก, 3%, 5%, 0.5%, …)
- **Migration:** `20260608120037_companies_tax_vat_wht_rates.sql`
- **Phase:** 1

### 2026-06-16 — Customer soft delete + DATA-CHANGE-LOG

- **ทำอะไร:** RPC `soft_delete_company` · entity_type `companies` ใน activity log
- **ไฟล์ที่กระทบ:** `20260608120032_*`, `DATA-CHANGE-LOG.md`
- **Phase:** 1

### 2026-06-16 — Customer master: migration + save ครบฟิลด์

- **ทำอะไร:** `20260608120031_*` — companies columns + `company_ship_addresses` · frontend payload/sync
- **ไฟล์ที่กระทบ:** migration, `masterCustomer.ts`, `useCompanies.ts`, `CUSTOMER-MASTER-FIELDS.md`, `tables.md`
- **Phase:** 1

### 2026-06-16 — CUSTOMER-MASTER-FIELDS: Tax & Payment (§6)

- **ทำอะไร:** spec ฟิลด์ภาษี + Payment Code / VAT dropdown · layout 3 คอลัมน์
- **ไฟล์ที่กระทบ:** `CUSTOMER-MASTER-FIELDS.md`, `masterCustomer.ts`, `MasterDataCustomerForm.vue`, `i18n`
- **Phase:** 1

### 2026-06-16 — CUSTOMER-MASTER-FIELDS: Customer Owner (§5)

- **ทำอะไร:** จด spec `owner_id` · UI dropdown จาก profiles · รอ confirm business rules
- **ไฟล์ที่กระทบ:** `CUSTOMER-MASTER-FIELDS.md`, `MasterDataCustomerForm.vue`, `i18n/en.json`
- **Phase:** 1

### 2026-06-16 — CUSTOMER-MASTER-FIELDS: Status lifecycle (§4)

- **ทำอะไร:** 5 สถานะ + Phase 1 manual · migration CHECK constraint
- **ไฟล์ที่กระทบ:** `CUSTOMER-MASTER-FIELDS.md`, `tables.md`, `20260608120030_*`
- **Phase:** 1

### 2026-06-16 — CUSTOMER-MASTER-FIELDS: Sales Grade (§3)

- **ทำอะไร:** spec `sales_grade` — vip, a, b, c, prospect ตาม mockup
- **ไฟล์ที่กระทบ:** `CUSTOMER-MASTER-FIELDS.md`, `masterCustomer.ts`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-16 — CUSTOMER-MASTER-FIELDS.md (Industry Segment + Industry)

- **ทำอะไร:** spec slug / i18n / ตัวอย่าง CHECK constraint สำหรับฟอร์มลูกค้า — อ้างอิง mockup UI
- **ไฟล์ที่กระทบ:** `CUSTOMER-MASTER-FIELDS.md`, `tables.md` (หมายเหตุ `industry`)
- **Phase:** 1

### 2026-06-08 — add DATA-CHANGE-LOG.md + data_change_logs table

- **ทำอะไร:** กฎเหล็ก §13 — บันทึกทุก data change ในตารางแยก + `write_data_change_log()`
- **ไฟล์ที่กระทบ:** `DATA-CHANGE-LOG.md`, `tables.md`, `IRON-RULES.md`, migration `20260608120005_*`
- **Phase:** 1

### 2026-06-08 — create tables.md + permissions.md (schema source of truth)

- **ทำอะไร:** column definitions ครบทุกตาราง Phase 1 + role × table matrix
- **ไฟล์ที่กระทบ:** `tables.md`, `permissions.md`, `README.md`
- **Phase:** 1
- **ผลกระทบ:** implement migration ใช้ tables.md เป็น authoritative

### 2026-06-08 — create เอกสาร CRM schema

- **ทำอะไร:** สร้าง README ตาราง CRM, RLS, roles
- **ไฟล์ที่กระทบ:** `README.md`
- **Phase:** 1
- **หมายเหตุ:** เมื่อ deploy migration จริง บันทึกที่ DB-CHANGELOG ไม่ใช่แค่ที่นี่
