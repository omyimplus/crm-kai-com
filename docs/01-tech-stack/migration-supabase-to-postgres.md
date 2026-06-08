# Migration: Supabase → Postgres (อนาคต)

> **ยังไม่ทำ** — อ่านเมื่อถึง Phase 3+  
> **ตัดสินใจปัจจุบัน:** ใช้ Supabase Phase 1–2 ([DECISIONS D-002](../00-overview/DECISIONS.md))

---

## ทำไมยังใช้ Supabase ก่อน

| ส่วน | ย้ายยาก | ใช้ Supabase ก่อน |
|------|---------|-------------------|
| SQL schema, RLS | 🟢 ง่าย | |
| Supabase Auth + client | 🔴 ยาก | ✅ ประหยัด 1–2 สัปดาห์ |
| CRM composables | 🔴 ต้อง rewrite | ✅ `@nuxtjs/supabase` |

---

## ย้ายได้เกือบตรง (copy)

- SQL migrations / tables
- RLS policies (ปรับ `auth.uid()` / JWT claims)
- Seed data
- `org_id` pattern

---

## ต้องทำใหม่

- Supabase Auth → Node API + JWT / Lucia / Keycloak
- `@nuxtjs/supabase` → PostgREST หรือ custom client
- Storage / Realtime (ถ้าใช้แล้ว)

---

## จุดย้ายที่แนะนำ

| เมื่อ | เหตุผล |
|-------|--------|
| ก่อนมี user production จริง | ง่ายสุด |
| Phase 3 เริ่ม multi-tenant | ถ้า tenant เยอะ / self-host |
| **อย่า** รอ Phase 5 | ยิ่งช้ายิ่งแพง |

**ประมาณ effort:** 3–5 สัปดาห์ (ทีมเล็ก) ถ้า Phase 1 CRM เสร็จแล้ว

---

## Target stack (Phase 3+ self-host)

```
PostgreSQL (cloud ตัวเอง)
+ PostgREST (CRM + RLS)
+ Node API (auth + control plane)
+ Nuxt
```

---

## เอกสารที่เกี่ยวข้อง

- [README.md](./README.md)
- [../02-database/PHASE-MATRIX.md](../02-database/PHASE-MATRIX.md)
