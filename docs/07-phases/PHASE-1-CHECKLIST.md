# Phase 1 Checklist — Definition of Done

> **Phase ปัจจุบัน** — CRM Core  
> สถานะ → [../00-overview/PROJECT-STATUS.md](../00-overview/PROJECT-STATUS.md)

---

## Infrastructure

- [x] สร้าง `frontend/` — Nuxt + Nuxt UI + Supabase module
- [x] สร้าง `supabase/` — config.toml, migrations, seed
- [x] Migration ครบตาม tables.md
- [x] RLS + `current_org_id()` + `signup_profile()`
- [x] Seed: demo org + default pipeline
- [x] อัปเดต DB-SCHEMA.md + DB-CHANGELOG.md

---

## Auth

- [x] `/login` — email/password
- [x] `/signup` — ผูก demo org ผ่าน RPC (Phase 1 dev)
- [x] Middleware auth / guest
- [x] Logout

---

## CRM Pages

- [x] `/app` — dashboard
- [x] `/app/contacts` — list + create/edit + soft delete
- [x] `/app/companies` — list + create/edit + soft delete
- [x] `/app/deals` — Kanban drag stage
- [x] `/app/deals/:id` — detail + edit

---

## Data integrity

- [ ] ทดสอบ user 2 คนใน org เดียว (manual QA หลังรัน Supabase)
- [x] RLS ตาม org_id (migration)
- [x] Soft delete (deleted_at)

---

## Phase 1 code complete ✅

รัน Supabase + ทดสอบ E2E ด้วยมือ → แล้วถือว่า Phase 1 ปิด

**ถัดไป:** Phase 2 — roles ละเอียด, activities, polish
