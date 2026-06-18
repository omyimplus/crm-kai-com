# QA Checklist — Master Data (11 menus)

> **ใช้คู่กับ:** [QA-GUIDE.md](./QA-GUIDE.md)  
> **อัปเดต:** 2026-06-08 · รอบ smoke test หลัง deploy migrations 65–68

---

## บัญชีที่ใช้ทดสอบ

| บัญชี | Platform role | Org role | ใช้ทดสอบ |
|--------|---------------|----------|----------|
| `browser-test-owner@crm-kai.test` | admin | — | Owner smoke · archive tabs · Setup |
| `qa-smoke-employee@crm-kai.test` | employee | sales | Employee permission · ไม่มี archive tabs |

รหัสผ่านทั้งคู่: `testpass123` (ดู [TEST-ACCOUNTS.md](./TEST-ACCOUNTS.md))

---

## ชั้น 0 — Environment

- [x] Dev server `http://localhost:3000` — HTTP 200 `/login`
- [x] Login admin → `/app`
- [x] Migrations deploy แล้ว (user confirm) — RPC master data ใช้งานได้จาก UI

---

## Smoke test — 11 เมนู (admin)

| # | Route | หัวข้อ | ผล | หมายเหตุ |
|---|-------|--------|-----|----------|
| 1 | `/app/customer` | Customers | PASS | รายการ + archive tabs |
| 2 | `/app/contact` | Contacts | PASS | 2 รายการ |
| 3 | `/app/sales-target` | Sales targets | PASS | |
| 4 | `/app/product` | Products | PASS | |
| 5 | `/app/category` | Product categories | PASS | 5 รายการ |
| 6 | `/app/unit` | Units of measure | PASS | |
| 7 | `/app/lead-source` | Lead sources | PASS | 14 รายการ |
| 8 | `/app/partner` | Partners | PASS | |
| 9 | `/app/sales-team` | Sales teams | PASS | |
| 10 | `/app/module-status?module=lead` | Module statuses | PASS | split-pane · empty state OK |
| 11 | `/app/job-code?module=lead` | Job code | PASS | form + preview สด |

- [x] Sidebar แสดง 11 เมนู · ไม่มี badge Coming soon
- [x] Legacy `/app/master-data/customer` → redirect (เพิ่มในรอบปิดงาน)

---

## ชั้น 4 — 2 users org เดียว (Demo Corp)

### Admin (`browser-test-owner@crm-kai.test`)

- [x] เห็น archive tabs **Active / Deleted** บน `/app/customer`
- [x] เห็น **System setup** ใน sidebar
- [x] เข้า `/app/setup/system-users` ได้

### Employee (`qa-smoke-employee@crm-kai.test` + org role **sales**)

- [x] Login ได้ · org เดียวกับ admin
- [x] **ไม่มี** archive tab Deleted บน `/app/customer` และ `/app/contact`
- [x] **ไม่มี** System setup ใน sidebar
- [x] เข้า `/app/setup/system-users` → redirect `/app`
- [x] API `restore_company` → **Forbidden**
- [x] REST อ่าน `companies` ที่ `deleted_at IS NOT NULL` → **0 แถว** (RLS)

---

## บัค / ข้อสังเกต

| รายการ | ความรุนแรง | สถานะ |
|--------|------------|--------|
| Dev WARN `normalizeSelectValue` duplicated imports | — | **แก้แล้ว** — `utils/normalizeSelectValue.ts` |
| Employee ต้องมี org role ถึงจะเห็นเมนู Master Data | — | By design |
| สร้าง `qa-smoke-employee@crm-kai.test` บน Supabase จริงในรอบ QA นี้ | — | เก็บไว้ทดสอบซ้ำได้ |

---

## รอบถัดไป (ถ้าต้องการลึกขึ้น)

- [ ] E2E CRUD ทุกเมนู (create → edit → soft delete → restore) ต่อ admin
- [ ] i18n สลับ th/en ทุกเมนู
- [ ] Employee ตาม org role อื่น (view-only customer)
