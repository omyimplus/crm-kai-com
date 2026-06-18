# Project Status — สถานะจริงของโปรเจกต์

> **อัปเดตทุกครั้งที่ milestone เปลี่ยน**  
> ประวัติ → [CHANGELOG.md](./CHANGELOG.md)

---

## สรุปเร็ว

| รายการ | ค่า |
|--------|-----|
| **Phase ปัจจุบัน** | **1** — CRM Core |
| **Code status** | ✅ Master Data ครบ 11 เมนู · legacy CRM routes ยังอยู่ |
| **Stack** | Nuxt 4 + Nuxt UI + Supabase |
| **Node** | **24 LTS** (>= 24.11.0) — `.nvmrc` |
| **อัปเดตล่าสุด** | 2026-06-08 |

---

## สถานะตามส่วน

| ส่วน | Docs | Code | หมายเหตุ |
|------|------|------|----------|
| Frontend (Nuxt) | ✅ | ✅ | `frontend/` |
| Supabase migrations | ✅ | ✅ | 69 files · ล่าสุด `20260608120068_*` |
| Auth login/logout/signup | ✅ | ✅ | pending user flow |
| Setup (roles, users, activity) | ✅ | ✅ | `/app/setup/**` |
| **Master Data (ข้อมูลหลัก)** | ✅ | ✅ | 11 เมนู — ดู [MASTER-DATA-MENU.md](../05-frontend/MASTER-DATA-MENU.md) |
| Legacy Contacts/Companies/Deals | ✅ | ✅ | `/app/contacts` · `/app/companies` · `/app/deals` |
| CRM Menu (Tasks, Lead, …) | ✅ design | ⏳ | Coming soon scaffold |
| Node API | ✅ design | ✅ scaffold | Phase 3+ |

---

## Master Data — Phase 1 ✅

| # | เมนู | Route |
|---|------|-------|
| 1 | Customer | `/app/customer` |
| 2 | Contact | `/app/contact` |
| 3 | Sales target | `/app/sales-target` |
| 4 | Products | `/app/product` |
| 5 | Category | `/app/category` |
| 6 | Unit | `/app/unit` |
| 7 | Lead source | `/app/lead-source` |
| 8 | Partner | `/app/partner` |
| 9 | Sales team | `/app/sales-team` |
| 10 | Module statuses | `/app/module-status` |
| 11 | Job code | `/app/job-code` |

Legacy redirect: `/app/master-data/*` → route ใหม่ (ดู `pages/app/master-data/`)

---

## Migration ที่ต้อง apply (remote / local)

รัน migrations ทั้งหมดใน `supabase/migrations/` ตามลำดับ — ดู [DB-README.md](../../supabase/DB-README.md)

ชุดล่าสุด (2026-06-08): `20260608120065` … `20260608120068` (module statuses · job code)

---

## Data change logs (§13)

| โมดูล | create | update | soft delete |
|--------|--------|--------|-------------|
| Customer (companies) | ✅ RPC | ✅ RPC | ✅ RPC |
| Contact | ✅ RPC | ✅ RPC | ✅ RPC |
| Sales target · Product · Category · Unit · Lead source · Partner · Sales team | ✅ RPC | ✅ RPC | ✅ RPC |
| Module statuses · Job code sequences | ✅ RPC | ✅ RPC | ✅ RPC |
| System users / roles | ✅ RPC | ✅ RPC | ✅ RPC |

→ [DATA-CHANGE-LOG.md](../06-crm-schema/DATA-CHANGE-LOG.md)

---

## รัน local

```bash
supabase start && supabase db reset   # หรือ db push บน cloud

cd frontend && cp .env.example .env
pnpm install && pnpm dev              # http://localhost:3000
```

→ [11-dev-setup/README.md](../11-dev-setup/README.md)

---

## Phase 1 checklist

→ [PHASE-1-CHECKLIST.md](../07-phases/PHASE-1-CHECKLIST.md)  
**ค้าง:** manual QA 2 users ใน org เดียว · apply migrations บน Supabase ที่ใช้จริง · smoke test Master Data 11 เมนู

→ **อัปเดต 2026-06-08:** smoke test + 2-user QA PASS — [QA-MASTER-DATA.md](../11-dev-setup/QA-MASTER-DATA.md)

---

## เอกสารที่เกี่ยวข้อง

- [ONBOARDING.md](./ONBOARDING.md)
- [DECISIONS.md](./DECISIONS.md)
- [MASTER-DATA-MENU.md](../05-frontend/MASTER-DATA-MENU.md)
- [CUSTOMER-MASTER-FIELDS.md](../06-crm-schema/CUSTOMER-MASTER-FIELDS.md)
- [CONTACT-MASTER-FIELDS.md](../06-crm-schema/CONTACT-MASTER-FIELDS.md)
- [../02-database/DB-SCHEMA.md](../02-database/DB-SCHEMA.md)
