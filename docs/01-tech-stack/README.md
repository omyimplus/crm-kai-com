# 01 — Tech Stack

> **🔴 Phase 1 (ตอนนี้):** แถวแรกด้านล่าง  
> **⚪ Phase 3+:** แถวที่สอง

## สถานะปัจจุบัน

| รายการ | ค่า |
|--------|-----|
| Phase | 1 |
| DB | Supabase Cloud ([DECISIONS D-002](../00-overview/DECISIONS.md)) |
| UI | **Nuxt UI** ([DECISIONS D-006](../00-overview/DECISIONS.md)) |

---

## 🔴 Phase 1–2 (ใช้ตอนนี้)

| ชั้น | เทคโนโลยี |
|------|-----------|
| Frontend | Nuxt 3, Tailwind CSS, TypeScript, Pinia, **Nuxt UI** |
| Validation | VeeValidate + Zod |
| Database & Auth | Supabase (Postgres + Auth + RLS + Migrations) |
| Backend API | **Scaffold** `api/` — Hono, Node 22 — logic Phase 3+ |
| Deploy Frontend | Vercel หรือ Cloudflare Pages (ยังไม่ตัดสิน) |
| Local Dev | Supabase CLI — [11-dev-setup](../11-dev-setup/) |

## ⚪ Phase 3+ (อนาคต)

| ชั้น | เทคโนโลยี |
|------|-----------|
| Backend API | Node.js **22 LTS** + Hono/Fastify + TypeScript |
| Queue | BullMQ + Redis หรือ Inngest |
| Email | Resend / Postmark |
| Payment | Stripe / Omise |
| Tenant Provisioning | Supabase Management API |
| Observability | Sentry, GitHub Actions |

---

## ย้าย Supabase → Postgres (อนาคต)

→ [migration-supabase-to-postgres.md](./migration-supabase-to-postgres.md)

---

## ไม่ใช้

Next.js, Prisma แยก, MongoDB, Microservices, GraphQL

---

## ดูการเปลี่ยนแปลงล่าสุด

→ [CHANGELOG.md](./CHANGELOG.md)
