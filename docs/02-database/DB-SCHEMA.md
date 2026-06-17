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
| อัปเดตล่าสุด | 2026-06-17 |
| Migration ล่าสุด | `20260608120040_companies_crud_rpc.sql` |
| จำนวน migrations | 41 files |

---

## ตาราง (deployed via migration)

| ตาราง | RLS | หมายเหตุ |
|-------|-----|----------|
| organizations | ✅ | tenant SaaS |
| profiles | ✅ | FK auth.users |
| companies | ✅ | customer master · soft delete |
| company_bill_addresses | ✅ | Bill To 1:N |
| company_ship_addresses | ✅ | Ship To 1:N |
| contacts | ✅ | contact master · soft delete |
| pipelines | ✅ | |
| pipeline_stages | ✅ | seed 6 stages |
| deals | ✅ | stage trigger → history |
| activities | ✅ | Phase 2 UI |
| deal_stage_history | ✅ | auto insert |
| data_change_logs | ✅ | audit ทุก data change (§13) |
| org_roles | ✅ | custom org roles |
| org_role_templates | ✅ | seed templates |
| user_login_sessions | ✅ | |
| org_* settings | ✅ | email, auth, notification, company profiles |

---

## Functions (CRM audit)

| ชื่อ | หมายเหตุ |
|------|----------|
| `write_data_change_log(...)` | audit core |
| `company_log_snapshot(uuid)` | |
| `create_company(jsonb)` | + log |
| `update_company(uuid, jsonb)` | + log |
| `soft_delete_company(uuid)` | + log |
| `contact_log_snapshot(uuid)` | |
| `create_contact(jsonb)` | + log |
| `update_contact(uuid, jsonb)` | + log |
| `soft_delete_contact(uuid)` | + log |
| `list_data_change_logs(...)` | User Activity UI |

→ รายการ functions อื่น (auth, roles, users) ดู [DB-README.md](../../supabase/DB-README.md)

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
- [CUSTOMER-MASTER-FIELDS.md](../06-crm-schema/CUSTOMER-MASTER-FIELDS.md)
- [CONTACT-MASTER-FIELDS.md](../06-crm-schema/CONTACT-MASTER-FIELDS.md)
