# CRM Kai

Multi-tenant SaaS CRM — **Phase 1 code ready**

## Quick start

```bash
nvm use   # Node 22 — ดู .nvmrc

supabase start && supabase db reset

cd frontend
cp .env.example .env   # ใส่ keys จาก supabase status
npm install && npm run dev
```

Open http://localhost:3000 → **Sign up** → ใช้ CRM

API scaffold (optional): `cd api && npm install && npm run dev` → http://localhost:4000/health

## Docs

1. [docs/00-overview/ONBOARDING.md](./docs/00-overview/ONBOARDING.md)
2. [docs/00-overview/PROJECT-STATUS.md](./docs/00-overview/PROJECT-STATUS.md)
3. [docs/07-phases/PHASE-1-CHECKLIST.md](./docs/07-phases/PHASE-1-CHECKLIST.md)

## Structure

```
crm-kai-com/
├── .nvmrc        # Node 22 — ทั้งระบบ
├── frontend/     # Nuxt + CRM UI
├── api/          # Node API scaffold (Phase 3+)
├── supabase/     # migrations + seed
└── docs/         # architecture
```
