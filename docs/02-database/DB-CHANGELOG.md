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

### 2026-06-18 — Opportunities module v1

- **ประเภท:** migration `20260608120081_opportunities_module.sql`
- **ทำอะไร:** ตาราง `opportunities` · RPC CRUD · `create_opportunity_from_lead` (1 ลีด = 1 opp) · lazy seed job code `opportunity` (prefix `OPP`) · trigger stage → status won/lost
- **Docs:** [OPPORTUNITIES-MODULE.md](../05-frontend/OPPORTUNITIES-MODULE.md) · [tables.md](../06-crm-schema/tables.md)

### 2026-06-18 — opportunity lead field rules

- **ประเภท:** migration `20260608120082_opportunity_lead_field_rules.sql`
- **ทำอะไร:** `create_opportunity_from_lead` / `update_opportunity` — ฟิลด์จากลีดอ่านอย่างเดียว · `probability` จาก stage · `estimated_value` sync จาก `leads.lead_value`
- **Docs:** [OPPORTUNITIES-MODULE.md](../05-frontend/OPPORTUNITIES-MODULE.md)

### 2026-06-18 — opportunity bill-to from customer

- **ประเภท:** migration `20260608120083_opportunity_bill_address_from_customer.sql`
- **ทำอะไร:** `address_bill_to` prefill จาก `get_company_default_bill_address` · แก้ไขได้ตอน update · UI เลือกจากรายการที่อยู่ออกบิลของลูกค้า
- **Docs:** [OPPORTUNITIES-MODULE.md](../05-frontend/OPPORTUNITIES-MODULE.md) · [CUSTOMER-MASTER-FIELDS.md](../06-crm-schema/CUSTOMER-MASTER-FIELDS.md) §8

### 2026-06-18 — opportunity estimated value sync lead

- **ประเภท:** migration `20260608120084_opportunity_estimated_value_sync_lead.sql`
- **ทำอะไร:** `estimated_value` แก้ได้บน opp · `create_opportunity_from_lead` / `update_opportunity` sync `leads.lead_value` + data change log
- **Docs:** [OPPORTUNITIES-MODULE.md](../05-frontend/OPPORTUNITIES-MODULE.md)

### 2026-06-18 — opportunity project fields editable

- **ประเภท:** migration `20260608120085_opportunity_project_name_editable.sql`
- **ทำอะไร:** `project_name` รับจาก payload ตอนสร้าง/แก้ไข — ส่วนโปรเจกต์เป็นข้อมูล opp ทั้งหมด
- **Docs:** [OPPORTUNITIES-MODULE.md](../05-frontend/OPPORTUNITIES-MODULE.md)

### 2026-06-18 — opportunity_projects (multi-project per opp)

- **ประเภท:** migration `20260608120086_opportunity_projects.sql`
- **ทำอะไร:** ตาราง `opportunity_projects` · RPC `list_opportunity_projects` / `sync_opportunity_projects` · `estimated_value` = ผลรวมมูลค่าโปรเจกต์
- **Docs:** [OPPORTUNITIES-MODULE.md](../05-frontend/OPPORTUNITIES-MODULE.md) · [tables.md](../06-crm-schema/tables.md)

### 2026-06-18 — revert customer_type + lead_type channel catalog

- **ประเภท:** migration `20260608120080_restore_customer_type_lead_type_channel.sql`
- **ทำอะไร:** `customer_type` กลับ `company`/`individual` · `lead_type` → end_user … other

### 2026-06-18 — industry segment catalog (mockup)

- **ประเภท:** migration `20260608120079_industry_segment_catalog.sql`
- **ทำอะไร:** `industry_segment` จาก enterprise/sme/startup/individual → agriculture … transportation

### 2026-06-18 — customer type channel catalog

- **ประเภท:** migration `20260608120078_customer_type_channel.sql`
- **ทำอะไร:** `customer_type` จาก `company`/`individual` → `end_user` · `dealer` · `contractor` · `distributor` · `oem` · `other` (companies + leads)

### 2026-06-18 — lead status catalog (8 statuses)

- **ประเภท:** migration `20260608120077_lead_status_catalog.sql`
- **สถานะ:** NEW · OPEN · CONTACTED · NURTURING · QUALIFIED · UNQUALIFIED · CANCELLED · CONVERTED

### 2026-06-18 — leads.contact_id

- **ประเภท:** migration `20260608120076_leads_contact_id.sql`
- **ทำอะไร:** FK `contact_id` · RPC list/create/update รองรับผู้ติดต่อ

### 2026-06-18 — leads module

- **ประเภท:** migration `20260608120075_leads_module.sql`
- **ทำอะไร:** ตาราง `leads` · seed `module_key = lead` · RPC `list/create/update/soft_delete_lead` · block delete module status ถ้ามี lead

### 2026-06-08 — tasks.sales_team_id

- **ประเภท:** migration `20260608120074_tasks_sales_team.sql`
- **ทำอะไร:** FK `sales_team_id` → `sales_teams` · อัปเดต `list_tasks` / `create_task` / `update_task` / `task_log_snapshot`

### 2026-06-08 — Task status change log (not pipeline stepper)

- **ประเภท:** migration `20260608120073_task_status_history_changelog.sql`
- **ทำอะไร:** เอา unique (task, status) · append เมื่อเปลี่ยนสถานะจริง · แก้วันที่แถวเดิม by id · ไม่เติมสถานะกลางอัตโนมัติ

### 2026-06-08 — Task status history (ordered timeline + dates)

- **ประเภท:** migration `20260608120072_task_status_history.sql`
- **ทำอะไร:** ตาราง `task_status_history` · RPC `list_task_status_history` · sync ใน `create_task`/`update_task` · backfill งานเดิม

### 2026-06-08 — Tasks dynamic statuses + block delete in use

- **ประเภท:** migration `20260608120071_module_status_block_delete_tasks.sql` · frontend Tasks
- **ทำอะไร:** `soft_delete_module_status` ห้ามลบเมื่อมีงาน active อ้างอิง · การ์ดสรุป/list tab จาก `module_statuses` ที่ **active** · สร้างงานใช้ `is_default` · แก้ไขงานที่สถานะ inactive ยังเลือกสถานะเดิมได้ · i18n `inUseByTasks`

### 2026-06-08 — Fix list_tasks read-only error

- **ประเภท:** migration `20260608120070_fix_list_tasks_readonly.sql`
- **ทำอะไร:** เอา `ensure_task_module_defaults()` ออกจาก `list_tasks` (STABLE + INSERT → PostgREST read-only txn error) · seed ผ่าน RPC `ensure_task_module_defaults` / `create_task` แทน

### 2026-06-08 — Tasks module (Phase 2)

- **ประเภท:** migration `20260608120069_tasks_module.sql` · frontend `/app/tasks`
- **ทำอะไร:** ตาราง `tasks` · lazy seed สถานะ+job code โมดูล `task` · `generate_job_code` · RPC CRUD · หน้า list/calendar + form modal · i18n th/en

### 2026-06-08 — job_code separator toggle + date part order UX

- **ประเภท:** migration `20260608120068_job_code_separator_enabled.sql` · frontend job code form
- **ทำอะไร:** `separator_enabled` · ตัวคั่นเลือกจาก `- _ . / :` · สลับลำดับวันที่แสดงเฉพาะส่วนที่เลือก

### 2026-06-08 — job_code_sequences master

- **ประเภท:** migration `20260608120067_job_code_sequences.sql`
- **ทำอะไร:** ตาราง `job_code_sequences` · รูปแบบรหัสต่อโมดูล · RPC CRUD · permission `master.jobCode` มีอยู่แล้ว

### 2026-06-08 — module_statuses status_code format (UPPER_SNAKE_CASE)

- **ประเภท:** migration `20260608120066_module_status_code_format.sql`
- **ทำอะไร:** CHECK `^[A-Z][A-Z0-9_]{1,48}$` · RPC upper(trim) + validate · frontend auto-uppercase + validation

### 2026-06-08 — module_statuses RLS policies idempotent

- **ประเภท:** แก้ migration `20260608120065_module_statuses.sql`
- **ทำอะไร:** `DROP POLICY IF EXISTS` ก่อน `CREATE POLICY` — รันซ้ำใน SQL Editor / retry migration ไม่ error 42710

### 2026-06-08 — module_statuses master table + RPC

- **ประเภท:** migration `20260608120065_module_statuses.sql`
- **ทำอะไร:** ตาราง `module_statuses` · สถานะต่อโมดูล · RPC CRUD · permission `master.moduleStatuses` มีอยู่แล้ว

### 2026-06-08 — sales_teams + sales_team_members

- **ประเภท:** migration `20260608120064_sales_teams.sql`
- **ทำอะไร:** ตารางทีมขาย + junction สมาชิก (profiles) · RPC CRUD · permission `master.salesTeam` มีอยู่แล้ว

### 2026-06-08 — ยกเลิก employee_positions master + master.employee permission

- **ประเภท:** migration `20260608120063_drop_employee_position_master.sql`
- **ทำอะไร:** drop ตาราง `employee_positions` + RPC · ลบ permission keys `master.employeePosition` และ `master.employee` จาก org role templates
- **เหตุผล:** ใช้ **Setup → ผู้ใช้งานในระบบ** แทน master menu พนักงาน/ตำแหน่ง

### 2026-06-08 — employee_positions master table + RPC (ยกเลิกแล้ว — ดู migration 63)

- **ประเภท:** migration `20260608120061_employee_positions.sql` · `20260608120062_employee_position_permissions.sql`
- **ทำอะไร:** ตาราง `employee_positions` + RPC CRUD · permission `master.employeePosition` · org กำหนดตำแหน่งเอง
- **สถานะ:** superseded โดย `20260608120063`

### 2026-06-08 — partners legacy form fields

- **ประเภท:** migration `20260608120060_partners_legacy_fields.sql`
- **ทำอะไร:** partner_type, tier, partner_since, contact, email, phone, website, commission_rate · อัปเดต RPC
- **Docs:** `PARTNER-MASTER-FIELDS.md`

### 2026-06-08 — partners master table + RPC

- **ประเภท:** migration `20260608120058_partners.sql` · `20260608120059_partner_permissions.sql`
- **ทำอะไร:** ตาราง `partners` + RPC CRUD · permission `master.partner`
- **Docs:** `PARTNER-MASTER-FIELDS.md`

### 2026-06-08 — lead_sources seed (demo org)

- **ประเภท:** `supabase/seed.sql`
- **ทำอะไร:** insert แหล่งที่มาลีด 13 รายการเริ่มต้นให้ demo org (WEB, GOOGLE, …) เมื่อ `db reset` · ไม่มี RPC seed ใน runtime

### 2026-06-08 — lead_sources master (org-defined)

- **ประเภท:** migration `20260608120056_lead_sources.sql` · fix `20260608120057_lead_sources_drop_channel_seed.sql` (ถ้ารัน variant เก่า)
- **ทำอะไร:** ตาราง `lead_sources` + RPC CRUD · **ไม่มี seed ค่าเริ่มต้น** · org กำหนดเองใช้กับ Lead
- **Docs:** `LEAD-SOURCE-MASTER-FIELDS.md`

### 2026-06-08 — product_gallery_images table + RPC

- **ประเภท:** migration `20260608120055_product_gallery_images.sql`
- **ทำอะไร:** ตาราง `product_gallery_images` · RPC add/remove/reorder · RLS select · สูงสุด 20 รูป/สินค้า
- **Docs:** `PRODUCT-MASTER-FIELDS.md` · `IMAGE-UPLOAD.md`

### 2026-06-08 — units master + products.unit_id FK

- **ประเภท:** migration `20260608120053_units.sql` · `20260608120054_products_unit_id.sql`
- **ทำอะไร:** ตาราง `units` + RPC CRUD · FK `products.unit_id` · migrate legacy text · block ลบหน่วยถ้ามีสินค้า
- **Docs:** `UNIT-MASTER-FIELDS.md` · `PRODUCT-MASTER-FIELDS.md`

### 2026-06-08 — products image_url + storage policies

- **ประเภท:** migration `20260608120052_product_image.sql`
- **ทำอะไร:** column `image_url` · RPC `set_image` · Storage RLS `org-images/.../products/`
- **Docs:** `PRODUCT-MASTER-FIELDS.md` · `IMAGE-UPLOAD.md`

### 2026-06-08 — products.category_id FK

- **ประเภท:** migration `20260608120051_products_category_id.sql`
- **ทำอะไร:** FK → categories · migrate legacy text · `soft_delete_category` ตรวจสินค้า
- **Docs:** `PRODUCT-MASTER-FIELDS.md` · `CATEGORY-MASTER-FIELDS.md`

### 2026-06-08 — categories image_url + storage policies

- **ประเภท:** migration `20260608120050_category_image.sql`
- **ทำอะไร:** column `image_url` · RPC `set_image` · Storage RLS `org-images/.../categories/`
- **Docs:** `CATEGORY-MASTER-FIELDS.md` · `IMAGE-UPLOAD.md`

### 2026-06-08 — categories master table + CRUD RPC

- **ประเภท:** migration `20260608120049_categories.sql`
- **ทำอะไร:** ตาราง `categories` (module_key product) + hierarchy + RPC + restore
- **Docs:** `CATEGORY-MASTER-FIELDS.md`

### 2026-06-08 — products master table + CRUD RPC

- **ประเภท:** migration `20260608120048_products.sql`
- **ทำอะไร:** ตาราง `products` + RLS + create/update/soft delete/restore + `data_change_logs`
- **Docs:** `PRODUCT-MASTER-FIELDS.md`

### 2026-06-17 — sales_targets current_amount

- **ประเภท:** migration — `current_amount` manual · อัปเดต RPC snapshot/create/update
- **Migration file:** `supabase/migrations/20260608120047_sales_targets_current_amount.sql`

### 2026-06-17 — Sales targets master data

- **ประเภท:** migration — `sales_targets` + CRUD/restore RPC + actual from won deals
- **Migration file:** `supabase/migrations/20260608120046_sales_targets.sql`

### 2026-06-17 — ผู้ติดต่อหลัก 1 คนต่อลูกค้า

- **ประเภท:** migration — unique index + `ensure_single_main_contact` · อัปเดต create/update/restore RPC
- **Migration file:** `supabase/migrations/20260608120045_contacts_single_main_contact.sql`

### 2026-06-17 — deleted records admin/owner only

- **ประเภท:** migration — RLS ซ่อน soft-deleted จาก employee · restore RPC ต้อง `is_admin_or_owner`
- **Migration file:** `supabase/migrations/20260608120044_deleted_records_admin_only.sql`

### 2026-06-17 — restore master data (ลูกค้า + ผู้ติดต่อ)

- **ประเภท:** migration — `restore_company` / `restore_contact` · tab Deleted ใน UI · cascade restore contacts จาก log
- **Migration file:** `supabase/migrations/20260608120043_restore_master_data.sql`

### 2026-06-17 — fix contact_log_snapshot สำหรับ soft_delete_company

- **ประเภท:** migration — สร้าง `contact_log_snapshot` ถ้า migration 39 ยังไม่รัน แต่ 41 รันแล้ว
- **Migration file:** `supabase/migrations/20260608120042_fix_soft_delete_contact_snapshot.sql`

### 2026-06-17 — soft_delete_company cascade contacts

- **ประเภท:** migration — ลบลูกค้า → soft delete ผู้ติดต่อที่ผูกอยู่ + trigger กัน FK ค้าง
- **Migration file:** `supabase/migrations/20260608120041_soft_delete_company_cascade_contacts.sql`

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
