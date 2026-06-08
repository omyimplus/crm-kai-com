# 08 — Repo Structure

โครงสร้างไฟล์ใน repository ตาม phase

---

## Phase 1–2 (ปัจจุบัน)

```
crm-kai-com/
├── .nvmrc                    # Node 22 — ทั้งระบบ
├── frontend/                 # Nuxt 4 + Tailwind
│   ├── pages/
│   │   ├── login.vue
│   │   └── app/
│   ├── components/
│   ├── composables/
│   └── middleware/
├── api/                      # ⚪ scaffold — Control Plane (Phase 3+ logic)
│   ├── src/routes/
│   ├── src/services/
│   └── src/workers/
├── supabase/
│   ├── migrations/
│   ├── seed.sql
│   └── config.toml
├── docs/
└── README.md
```

## Phase 3+

```
crm-kai-com/
├── frontend/
├── api/                      # Node Control Plane
│   ├── routes/
│   ├── services/
│   └── workers/
├── supabase/
│   ├── migrations/
│   │   ├── control/
│   │   └── tenant/
│   └── seed.sql
├── scripts/
│   ├── provision-tenant.ts
│   └── migrate-all-tenants.ts
└── docs/
```

## Mapping: code → docs

| โฟลเดอร์ code | เอกสาร |
|---------------|--------|
| `frontend/` | `docs/05-frontend/` |
| `api/` | `docs/04-api/` |
| `supabase/migrations/` | `docs/02-database/` + `docs/06-crm-schema/` |
| `supabase/migrations/control/` | `docs/02-database/control-db.md` |
| `supabase/migrations/tenant/` | `docs/02-database/tenant-db.md` |
| `scripts/provision-*` | `docs/04-api/` + `docs/09-flows/` |

## ห้าม implement ก่อน phase

| โฟลเดอร์ | Phase ที่ implement logic |
|----------|---------------------------|
| `api/` (routes/services จริง) | 3+ |
| `supabase/migrations/control/` | 3+ |
| `supabase/migrations/tenant/` | 3+ |
| `scripts/provision-*` | 3+ |

> **หมายเหตุ:** `api/` มี scaffold + `/health` ได้ใน Phase 1 — ห้าม register/provision/proxy CRM
