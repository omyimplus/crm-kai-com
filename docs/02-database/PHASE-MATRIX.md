# Phase Matrix — ตาราง / DB อยู่ที่ไหนในแต่ละ Phase

> อ่านเมื่อไม่แน่ใจว่า table อยู่ DB ไหน หรือใช้โหมดไหน  
> **Phase ปัจจุบัน: 1** — ใช้แถว "Phase 1–2" เท่านั้น

---

## 🔴 ใช้ตอนนี้ (Phase 1–2)

| รายการ | ค่า |
|--------|-----|
| จำนวน DB | **1** Supabase project |
| มี `org_id` ในตาราง CRM | **ใช่** |
| Control DB แยก | **ไม่** |
| Node API | **ไม่** |
| Auth | Supabase Auth + `profiles.org_id` |

---

## ตาราง × Phase

| ตาราง | Phase 1–2 (ตอนนี้) | Phase 3+ Control DB | Phase 3+ Tenant DB |
|-------|-------------------|-------------------|---------------------|
| `auth.users` | Supabase เดียว | Control | — (sync/profile ใน tenant) |
| `organizations` | Supabase เดียว | Control | — |
| `organization_members` | ❌ ไม่ใช้ | Control | — |
| `subscriptions` | ❌ ไม่ใช้ | Control | — |
| `tenant_projects` | ❌ ไม่ใช้ | Control | — |
| `provision_jobs` | ❌ ไม่ใช้ | Control | — |
| `profiles` | Supabase เดียว (มี org_id) | — | Tenant (ไม่มี org_id) |
| `companies` | Supabase เดียว (org_id) | ❌ | Tenant |
| `contacts` | Supabase เดียว (org_id) | ❌ | Tenant |
| `pipelines` | Supabase เดียว (org_id) | ❌ | Tenant |
| `pipeline_stages` | Supabase เดียว (org_id) | ❌ | Tenant |
| `deals` | Supabase เดียว (org_id) | ❌ | Tenant |
| `activities` | Supabase เดียว (org_id) | ❌ | Tenant |
| `deal_stage_history` | Supabase เดียว (org_id) | ❌ | Tenant |

---

## การเข้าถึง × Phase

| ข้อมูล | Phase 1–2 | Phase 3+ |
|--------|-----------|----------|
| CRM (contacts, deals, …) | Nuxt → Supabase ตรง | Nuxt → **Tenant** Supabase ตรง |
| org / trial / tenant config | Nuxt → Supabase ตรง (same) | Nuxt → **Node API** → Control DB |
| Secrets (service role) | ไม่มีใน client | API only |

---

## Migration paths × Phase

| Phase | Path migrations |
|-------|-----------------|
| 1–2 | `supabase/migrations/` |
| 3+ control | `supabase/migrations/control/` |
| 3+ tenant | `supabase/migrations/tenant/` (ซ้ำทุก org) |

---

## เอกสารที่เกี่ยวข้อง

- [phase1-single-db.md](./phase1-single-db.md) — รายละเอียด Phase 1
- [control-db.md](./control-db.md) — Phase 3+ Control
- [tenant-db.md](./tenant-db.md) — Phase 3+ Tenant
- [../06-crm-schema/tables.md](../06-crm-schema/tables.md) — column definitions
