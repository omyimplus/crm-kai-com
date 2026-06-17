# Project Status — สถานะจริงของโปรเจกต์

> **อัปเดตทุกครั้งที่ milestone เปลี่ยน**  
> ประวัติ → [CHANGELOG.md](./CHANGELOG.md)

---

## สรุปเร็ว

| รายการ | ค่า |
|--------|-----|
| **Phase ปัจจุบัน** | **1** — CRM Core |
| **Code status** | ✅ Master Data Customer + Contact พร้อม · legacy CRM routes ยังอยู่ |
| **Stack** | Nuxt 4 + Nuxt UI + Supabase |
| **Node** | **22 LTS** (>= 22.16.0) — `.nvmrc` |
| **อัปเดตล่าสุด** | 2026-06-16 |

---

## สถานะตามส่วน

| ส่วน | Docs | Code | หมายเหตุ |
|------|------|------|----------|
| Frontend (Nuxt) | ✅ | ✅ | `frontend/` |
| Supabase migrations | ✅ | ✅ | 40 files · ล่าสุด `20260608120039_*` |
| Auth login/logout/signup | ✅ | ✅ | pending user flow |
| Setup (roles, users, activity) | ✅ | ✅ | `/app/setup/**` |
| **Master Data — Customer** | ✅ | ✅ | `/app/customer` · spec `CUSTOMER-MASTER-FIELDS.md` |
| **Master Data — Contact** | ✅ | ✅ | `/app/contact` · FK `company_id` · RPC + logs |
| Master Data อื่น ๆ | ✅ design | ⏳ | Coming soon badge |
| Legacy Contacts/Companies/Deals | ✅ | ✅ | `/app/contacts` · `/app/companies` · `/app/deals` |
| Node API | ✅ design | ✅ scaffold | Phase 3+ |

---

## Migration ที่ต้อง apply (remote / local)

ชุด Customer + Contact (2026-06-16) — รันตามลำดับ:

`20260608120030` … `20260608120039` (ดู [DB-README.md](../../supabase/DB-README.md))

---

## Data change logs (§13)

| โมดูล | create | update | soft delete |
|--------|--------|--------|-------------|
| Contact | ✅ RPC | ✅ RPC | ✅ RPC |
| Customer (companies) | ✅ RPC | ✅ RPC | ✅ RPC |
| System users / roles | ✅ RPC | ✅ RPC | ✅ RPC |

→ [DATA-CHANGE-LOG.md](../06-crm-schema/DATA-CHANGE-LOG.md)

---

## รัน local

```bash
supabase start && supabase db reset   # หรือ db push บน cloud

cd frontend && cp .env.example .env
npm install && npm run dev            # http://localhost:3000
```

→ [11-dev-setup/README.md](../11-dev-setup/README.md)

---

## Phase 1 checklist

→ [PHASE-1-CHECKLIST.md](../07-phases/PHASE-1-CHECKLIST.md)  
**ค้าง:** manual QA 2 users ใน org เดียว · apply migrations บน Supabase ที่ใช้จริง

---

## เอกสารที่เกี่ยวข้อง

- [ONBOARDING.md](./ONBOARDING.md)
- [DECISIONS.md](./DECISIONS.md)
- [CUSTOMER-MASTER-FIELDS.md](../06-crm-schema/CUSTOMER-MASTER-FIELDS.md)
- [CONTACT-MASTER-FIELDS.md](../06-crm-schema/CONTACT-MASTER-FIELDS.md)
- [../02-database/DB-SCHEMA.md](../02-database/DB-SCHEMA.md)
