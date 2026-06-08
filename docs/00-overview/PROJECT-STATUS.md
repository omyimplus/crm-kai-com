# Project Status — สถานะจริงของโปรเจกต์

> **อัปเดตทุกครั้งที่ milestone เปลี่ยน**  
> ประวัติ → [CHANGELOG.md](./CHANGELOG.md)

---

## สรุปเร็ว

| รายการ | ค่า |
|--------|-----|
| **Phase ปัจจุบัน** | **1** — CRM Core |
| **Code status** | ✅ Phase 1 scaffold เสร็จ — รอ Supabase local/cloud |
| **Stack** | Nuxt 4 + Nuxt UI + Supabase + API scaffold (Hono) |
| **Node** | **22 LTS** (>= 22.12.0) — `.nvmrc` |
| **อัปเดตล่าสุด** | 2026-06-08 |

---

## สถานะตามส่วน

| ส่วน | Docs | Code | หมายเหตุ |
|------|------|------|----------|
| Frontend (Nuxt) | ✅ | ✅ | `frontend/` — build ผ่าน |
| Supabase migrations | ✅ | ✅ | `supabase/migrations/` — รัน `supabase db reset` |
| Auth login/logout | ✅ | ✅ | `/login` |
| Signup → demo org | ✅ | ✅ | `/signup` (Phase 1 dev only) |
| Dashboard | ✅ | ✅ | `/app` |
| Contacts CRUD | ✅ | ✅ | `/app/contacts` |
| Companies CRUD | ✅ | ✅ | `/app/companies` |
| Deals + Kanban | ✅ | ✅ | `/app/deals` drag stage |
| Node API | ✅ design | ✅ scaffold | `api/` — health only, logic Phase 3+ |
| Landing / SaaS register | ✅ design | ❌ | Phase 4+ |

---

## รัน local

```bash
# Terminal 1 — Supabase (ต้องติดตั้ง CLI + Docker)
supabase start && supabase db reset

# Terminal 2 — Frontend
cd frontend && cp .env.example .env
# ใส่ URL + anon key จาก supabase status
npm install && npm run dev
```

→ รายละเอียด [11-dev-setup/README.md](../11-dev-setup/README.md)

---

## Phase 1 checklist

→ [PHASE-1-CHECKLIST.md](../07-phases/PHASE-1-CHECKLIST.md)

---

## เอกสารที่เกี่ยวข้อง

- [ONBOARDING.md](./ONBOARDING.md)
- [DECISIONS.md](./DECISIONS.md)
- [../02-database/DB-SCHEMA.md](../02-database/DB-SCHEMA.md)
