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
