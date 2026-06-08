# DB Schema — Snapshot ปัจจุบัน

> Living document — sync กับ migrations ใน `supabase/migrations/`  
> Column detail → [../06-crm-schema/tables.md](../06-crm-schema/tables.md)  
> Changelog → [DB-CHANGELOG.md](./DB-CHANGELOG.md)

---

## สถานะ

| รายการ | ค่า |
|--------|-----|
| Phase | 1 |
| โหมด | Single Supabase + org_id |
| อัปเดตล่าสุด | 2026-06-08 |
| Migration ล่าสุด | `20260608120008_list_data_change_logs.sql` |

---

## ตาราง (deployed via migration)

| ตาราง | RLS | หมายเหตุ |
|-------|-----|----------|
| organizations | ✅ | tenant SaaS |
| profiles | ✅ | FK auth.users |
| companies | ✅ | soft delete |
| contacts | ✅ | soft delete |
| pipelines | ✅ | |
| pipeline_stages | ✅ | seed 6 stages |
| deals | ✅ | stage trigger → history |
| activities | ✅ | Phase 2 UI |
| deal_stage_history | ✅ | auto insert |
| data_change_logs | ✅ | audit ทุก data change (§13) |
| org_roles | ✅ | custom org roles |

---

## Functions

| ชื่อ | สถานะ |
|------|--------|
| `current_org_id()` | ✅ |
| `current_user_role()` | ✅ |
| `is_readonly()` | ✅ |
| `is_admin_or_owner()` | ✅ |
| `signup_profile(text)` | ✅ |
| `set_updated_at()` | ✅ |
| `log_deal_stage_change()` | ✅ |
| `write_data_change_log(...)` | ✅ |
| `list_org_users()` | ✅ |
| `admin_create_org_user(...)` | ✅ |
| `admin_update_org_user(...)` | ✅ |
| `list_org_roles()` | ✅ |
| `create_org_role(...)` | ✅ |
| `update_org_role(...)` | ✅ |
| `get_org_role(uuid)` | ✅ |
| `delete_org_role(uuid)` | ✅ |
| `normalize_org_role_permissions(jsonb)` | ✅ |
| `list_data_change_logs(...)` | ✅ |

---

## Seed

| รายการ | ค่า |
|--------|-----|
| Demo org id | `11111111-1111-1111-1111-111111111111` |
| Demo org slug | `demo` |
| Default pipeline | Lead → Qualified → Proposal → Negotiation → Won / Lost |

---

## เอกสารออกแบบ

- [phase1-single-db.md](./phase1-single-db.md)
- [PHASE-MATRIX.md](./PHASE-MATRIX.md)
