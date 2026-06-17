# DB Changelog — บันทึก Database ทุกครั้ง

> ประวัติการเปลี่ยน → ด้านล่าง  
> Snapshot → [DB-SCHEMA.md](./DB-SCHEMA.md)

---

## สถานะ DB ปัจจุบัน

| รายการ | ค่า |
|--------|-----|
| Phase | 1 |
| Engine | Supabase (Postgres 15) |
| Migrations | 11 files (schema + RLS + grants + system users + audit log + org roles + permissions + list logs + signup owner + remove master.roles) |
| Seed | demo org + Sales pipeline |

---

## ประวัติ

## ประวัติ

### 2026-06-17 — companies create/update RPC + data_change_logs

- **ประเภท:** migration — `create_company`, `update_company`
- **Migration file:** `supabase/migrations/20260608120040_companies_crud_rpc.sql`

### 2026-06-16 — Contact CRUD RPC + data_change_logs

- **ประเภท:** migration — `create_contact`, `update_contact`, `soft_delete_contact`, `contact_log_snapshot`
- **Migration file:** `supabase/migrations/20260608120039_contacts_crud_rpc.sql`

### 2026-06-16 — Contact master + customer relation

- **ประเภท:** migration + UI — `contacts` fields · `/app/contact` · FK `company_id` → customer
- **Migration file:** `supabase/migrations/20260608120038_contacts_master_fields.sql`
- **Spec:** `docs/06-crm-schema/CONTACT-MASTER-FIELDS.md`

### 2026-06-16 — companies.tax_vat = WHT rate slugs

- **ประเภท:** migration — แทน VAT dropdown ด้วยอัตราหัก ณ ที่จ่าย
- **Migration file:** `supabase/migrations/20260608120037_companies_tax_vat_wht_rates.sql`

### 2026-06-16 — company_bill_addresses (Bill To หลายที่อยู่ + default)

- **ประเภท:** migration + UI — ตาราง `company_bill_addresses` · component ร่วมกับ Ship To
- **Migration file:** `supabase/migrations/20260608120035_company_bill_addresses.sql`

### 2026-06-16 — companies individual type rules

- **ประเภท:** migration — CHECK บุคคลธรรมดา → `industry_segment = individual`, `industry IS NULL`
- **Migration file:** `supabase/migrations/20260608120034_companies_individual_type_rules.sql`

### 2026-06-16 — company_ship_addresses.is_default

- **ประเภท:** migration — default ship-to ต่อ company + RPC สำหรับโมดูลอื่น
- **Migration file:** `supabase/migrations/20260608120033_company_ship_addresses_is_default.sql`

### 2026-06-16 — companies soft delete RPC + audit log

- **ประเภท:** migration — `soft_delete_company`, `company_log_snapshot` → `data_change_logs`
- **Migration file:** `supabase/migrations/20260608120032_companies_soft_delete_rpc.sql`
- **Frontend:** หน้าดูลูกค้า + modal ลบ (soft delete)

### 2026-06-16 — companies customer master + ship addresses

- **ประเภท:** migration — คอลัมน์ General/Tax/Grade/Segment + CHECK industry + ตาราง `company_ship_addresses` + RLS
- **Migration file:** `supabase/migrations/20260608120031_companies_customer_master_fields.sql`
- **Docs:** `CUSTOMER-MASTER-FIELDS.md` · `tables.md`
- **Frontend:** `formToCompanyPayload` / `syncShipAddresses` บันทึกครบ (ยกเว้น `credit_balance`)

### 2026-06-16 — companies.status: 5 lifecycle values

- **ประเภท:** migration — ขยาย CHECK `active|inactive` → + `prospect`, `churned`, `pending`
- **Migration file:** `supabase/migrations/20260608120030_companies_customer_status.sql`
- **Docs:** `CUSTOMER-MASTER-FIELDS.md` §4

### 2026-06-08 — org auth providers RPC

- **ประเภท:** migration — `get/update_org_auth_providers` → `organizations.settings.authProviders`
- **Migration file:** `supabase/migrations/20260608120029_org_auth_providers.sql`
- **Frontend:** Settings → แท็บผู้ให้บริการเข้าสู่ระบบ

### 2026-06-08 — org email (SMTP) settings RPC

- **ประเภท:** migration — `get/update_org_email_settings`, `test_org_email_connection`; ปรับ `send_org_notification_email`
- **Migration file:** `supabase/migrations/20260608120028_org_email_settings.sql`
- **Frontend:** Settings → แท็บบริการอีเมล

### 2026-06-08 — org notification settings RPC

- **ประเภท:** migration — `get/update_org_notification_settings`, `send_org_notification_email` → `organizations.settings.notifications`
- **Migration file:** `supabase/migrations/20260608120027_org_notification_settings.sql`
- **Frontend:** Settings → แท็บการแจ้งเตือน

### 2026-06-08 — org-images storage + company logo RPC

- **ประเภท:** migration — bucket `org-images`; `create/update_org_company_profile` รองรับ `logoUrl` / `setLogo`
- **Migration file:** `supabase/migrations/20260608120026_org_images_storage.sql`
- **Frontend:** `useImageUpload`, `AppImageUpload`, โลโก้บริษัทใน Settings

### 2026-06-08 — org_company_profiles (หลายสาขา)

- **ประเภท:** migration — ตาราง `org_company_profiles` + RPC list/create/update/delete; ย้ายข้อมูลจาก `settings.companyInfo`; ลบ `update_org_company_info`
- **Migration file:** `supabase/migrations/20260608120025_org_company_profiles.sql`
- **Frontend:** Settings → แท็บข้อมูลบริษัท — รายการหลายโปรไฟล์ (สำนักงานใหญ่/สาขา)

### 2026-06-08 — org settings company info RPC

- **ประเภท:** migration — `get_org_settings`, `update_org_company_info` → `organizations.settings.companyInfo`
- **Migration file:** `supabase/migrations/20260608120024_org_settings_company_info.sql`
- **Frontend:** `/app/setup/settings` — แท็บข้อมูลบริษัท

### 2026-06-08 — list_org_login_sessions + ended_at

- **ประเภท:** migration — RPC คืน `ended_at` สำหรับคอลัมน์สิ้นสุดเซสชัน
- **Migration file:** `supabase/migrations/20260608120023_user_login_sessions_list_ended.sql`

### 2026-06-08 — user_login_sessions (Active Sessions)

- **ประเภท:** migration — ตาราง `user_login_sessions` + RPC บันทึก/heartbeat/logout/list
- **Migration file:** `supabase/migrations/20260608120022_user_login_sessions.sql`
- **Frontend:** `/app/setup/active-sessions` — owner/admin ดูรายการเซสชัน

### 2026-06-08 — profile_org_roles (หลายบทบาททีมต่อ user)

- **ประเภท:** migration — junction `profile_org_roles`, merge permissions, RPC `p_org_role_ids uuid[]`
- **Migration file:** `supabase/migrations/20260608120019_profile_org_roles_multi.sql`
- **Frontend:** chip multi-select บทบาททีมใน Setup → ผู้ใช้ในระบบ
- **หมายเหตุ:** ต้องรันบน remote ก่อนใช้ save user — มิฉะนั้น schema cache หา `admin_update_org_user(..., p_org_role_ids, ...)` ไม่เจอ

### 2026-06-08 — fix auth.users NULL tokens (admin-created users)

- **ประเภท:** migration — แก้ `Database error querying schema` ตอน login
- **Migration file:** `supabase/migrations/20260608120018_fix_auth_users_admin_create.sql`
- **สาเหตุ:** `admin_create_org_user` ไม่ได้ตั้ง `recovery_token`, `email_change*` เป็น `''`

### 2026-06-08 — resolve_login_email (username login)

- **ประเภท:** migration — RPC แปลง username → email ก่อน `signInWithPassword`
- **Migration file:** `supabase/migrations/20260608120017_resolve_login_email.sql`
- **ทดสอบ:** [TEST-ACCOUNTS.md](../11-dev-setup/TEST-ACCOUNTS.md) — `tester1` + `testpass123`

### 2026-06-08 — move Roles to Setup; drop master.roles permission key

- **ประเภท:** migration + frontend — กำหนด Role อยู่ Setup; ลบ `master.roles` จาก org permission matrix
- **Migration file:** `supabase/migrations/20260608120011_remove_master_roles_permission.sql`
- **Frontend:** `/app/setup/roles`, `/app/setup/roles/:id` (redirect จาก `/app/master-data/roles*`)

### 2026-06-08 — User Activity UI + list_data_change_logs

- **ประเภท:** migration + frontend — อ่าน `data_change_logs` ใน Setup → กิจกรรมผู้ใช้
- **Migration file:** `supabase/migrations/20260608120008_list_data_change_logs.sql`
- **Frontend:** `/app/setup/user-activity`

### 2026-06-08 — org role permissions page + delete role

- **ประเภท:** migration — `normalize_org_role_permissions`, `get_org_role`, `delete_org_role`, backfill keys
- **Migration file:** `supabase/migrations/20260608120007_org_role_permissions.sql`
- **Frontend:** `/app/setup/roles/:id`, `permissionModules.ts` (เดิมอยู่ Master Data)

### 2026-06-08 — add org_roles (Setup → กำหนด Role)

- **ประเภท:** migration — `org_roles`, `profiles.org_role_id`, RPC CRUD + wire system users
- **Migration file:** `supabase/migrations/20260608120006_org_roles.sql`
- **Frontend:** `/app/setup/roles`, org role select ใน System Users

### 2026-06-08 — add data_change_logs (กฎเหล็ก §13)

- **ประเภท:** migration — ตาราง `data_change_logs` + `write_data_change_log()`
- **wire:** `admin_create_org_user`, `admin_update_org_user` เขียน log ทุกครั้ง
- **Migration file:** `supabase/migrations/20260608120005_data_change_logs.sql`
- **เอกสาร:** `docs/06-crm-schema/DATA-CHANGE-LOG.md`, `IRON-RULES.md` §13

### 2026-06-08 — system users fields (username, password, create user)

- **ประเภท:** migration — `profiles.username` + RPC สร้าง/แก้ user ครบฟิลด์
- **ฟังก์ชัน:** `admin_create_org_user`, `admin_update_org_user` (แทน `admin_update_profile`)
- **Migration file:** `supabase/migrations/20260608120004_system_users_fields.sql`

### 2026-06-08 — add system users admin RPCs

- **ประเภท:** migration (functions)
- **ฟังก์ชัน:** `is_admin_or_owner()`, `list_org_users()`, `admin_update_profile()`
- **Migration file:** `supabase/migrations/20260608120003_system_users_admin.sql`
- **เหตุผล:** หน้า Setup → ผู้ใช้ในระบบ (owner/admin จัดการ role + is_active)

### 2026-06-08 — create Phase 1 CRM schema + RLS

- **ประเภท:** migration + seed + function
- **ตารางที่กระทบ:** organizations, profiles, companies, contacts, pipelines, pipeline_stages, deals, activities, deal_stage_history
- **Migration file:** `supabase/migrations/20260608120000_crm_schema.sql`, `20260608120001_rls_and_helpers.sql`
- **SQL สรุป:** CREATE TABLE ทั้งหมด, RLS, current_org_id(), signup_profile(), deal stage trigger
- **Rollback:** drop schema manual
- **Phase:** 1
- **อัปเดต DB-SCHEMA.md:** ใช่
