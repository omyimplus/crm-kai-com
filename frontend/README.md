# CRM Kai Frontend

Nuxt 4 + Nuxt UI + Supabase — Phase 1 CRM

## Setup

```bash
# 1. Start Supabase (from repo root)
supabase start
supabase db reset

# 2. Copy env
cp .env.example .env
# Fill keys from: supabase status

# 3. Install & run
pnpm install
pnpm dev
```

Open http://localhost:3000 → Sign up → use CRM

## Routes

- `/login`, `/signup` — auth (signup joins demo org)
- `/app` — dashboard
- `/app/contacts`, `/app/companies`, `/app/deals`

## Docs

- [../docs/00-overview/ONBOARDING.md](../docs/00-overview/ONBOARDING.md)
- [../docs/05-frontend/BRAND-ASSETS.md](../docs/05-frontend/BRAND-ASSETS.md) — logo
- [CHANGELOG.md](./CHANGELOG.md)

## Logo

| ไฟล์ | URL |
|------|-----|
| Full | `/images/logo/logo-kai-com-crm.webp` |
| Icon | `/images/logo/logo-kai-com-crm-icon.webp` |

Path ใน repo: `public/images/logo/`
