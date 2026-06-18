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

- [x] ทดสอบ user 2 คนใน org เดียว — [QA-MASTER-DATA.md](../11-dev-setup/QA-MASTER-DATA.md) (2026-06-08)
- [x] RLS ตาม org_id (migration)
- [x] Soft delete (deleted_at)

---

## Master Data (ข้อมูลหลัก)

- [x] 11 เมนู CRUD + permissions + i18n th/en — ดู [MASTER-DATA-MENU.md](../05-frontend/MASTER-DATA-MENU.md)
- [x] Smoke test ทุกเมนู — [QA-MASTER-DATA.md](../11-dev-setup/QA-MASTER-DATA.md) (2026-06-08)

---

## Phase 1 code complete ✅

รัน Supabase + ทดสอบ E2E ด้วยมือ → แล้วถือว่า Phase 1 ปิด

**ถัดไป:** Phase 2 — roles ละเอียด, activities, polish
