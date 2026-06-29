# 07 — Development Phases

Roadmap — **Phase ปัจจุบัน: 1** (เริ่ม CRM ก่อน)

---

## Phase 1 — CRM Core ✅ เริ่มที่นี่

**Checklist เต็ม:** [PHASE-1-CHECKLIST.md](./PHASE-1-CHECKLIST.md)

**เป้าหมาย:** CRM ใช้ได้ใน 1 org

- Supabase เดียว + migration CRM
- Nuxt + Tailwind + login
- CRUD contacts, companies, deals
- Pipeline Kanban
- RLS + org_id

**ห้าม:** landing, register, Node API, multi-tenant, queue, billing

---

## Phase 2 — CRM Production-ready

**เป้าหมาย:** ทีมขายใช้จริง + **CRM Menu** (เริ่มที่ Tasks)

- **CRM Menu** — implement ทีละโมดูล เริ่ม [Tasks](../05-frontend/TASKS-MODULE.md)
- **Customer 360** (spec ลูกค้า) — [CUSTOMER-360-FUNCTIONAL-SPEC.md](./CUSTOMER-360-FUNCTIONAL-SPEC.md)
- Roles, activities, search/filter
- Owner assignment, org settings
- CSV import (optional), UX polish

**ห้าม:** auto provision, Control API แยก

**Tasks v1 (โมดูลแรก):** ดู [TASKS-MODULE.md](../05-frontend/TASKS-MODULE.md)

---

## Phase 3 — Multi-tenant (Manual)

**เป้าหมาย:** หลาย org, สร้าง tenant ด้วย script

- Control DB schema
- Node API (tenant config)
- Scripts: provision-tenant, migrate-tenant
- Subdomain / slug routing

---

## Phase 4 — Register + Trial

**เป้าหมาย:** สมัครเอง, trial 90 วัน

- Landing, pricing, register
- Auto provisioning + queue
- Email, trial enforcement
- Admin console ขั้นต่ำ

---

## Phase 5 — Billing + Ops

**เป้าหมาย:** รายได้ + scale

- Stripe / Omise
- Migration runner ทุก tenant
- Sentry, backup, E2E tests

---

## Phase Gate (สำหรับ Agent)

ก่อน implement feature ใหม่:

1. เปิดไฟล์นี้
2. ตรวจว่า feature อยู่ phase ปัจจุบันหรือไม่
3. ถ้าเกิน phase → แจ้ง user + ขอ confirm

## เอกสารที่เกี่ยวข้อง

- [IRON-RULES.md](../IRON-RULES.md) — กฎที่ 5
- [08-repo-structure](../08-repo-structure/)
