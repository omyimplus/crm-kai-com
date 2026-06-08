# 02 — Database Architecture

Database แยก **2 กลุ่ม** (Phase 3+)

---

## ภาพรวม

```
กลุ่ม 1: Control DB (1 ตัว)
  → login, org registry, subscription, tenant config

กลุ่ม 2: Tenant DB (1 org = 1 Supabase project)
  → CRM: contacts, deals, pipelines, ...
```

## ไฟล์ในโฟลเดอร์นี้

| ไฟล์ | เนื้อหา |
|------|---------|
| **[PHASE-MATRIX.md](./PHASE-MATRIX.md)** | 🔴 ตาราง × phase × DB อยู่ที่ไหน |
| **[DB-CHANGELOG.md](./DB-CHANGELOG.md)** | 🔴 บันทึกทุก action DB |
| **[DB-SCHEMA.md](./DB-SCHEMA.md)** | 🔴 snapshot schema deploy แล้ว |
| [CHANGELOG.md](./CHANGELOG.md) | บันทึกการเปลี่ยนเอกสาร/โครงสร้าง DB |
| [control-db.md](./control-db.md) | กลุ่ม 1 — ตาราง, การเข้าถึง |
| [tenant-db.md](./tenant-db.md) | กลุ่ม 2 — CRM ต่อ org |
| [phase1-single-db.md](./phase1-single-db.md) | Phase 1–2 — DB เดียว + org_id |

## กฎสำคัญ

- Control DB → **Node API เท่านั้น** (Phase 3+)
- Tenant DB → **Nuxt → Supabase ตรง** (anon + RLS)
- Phase 1–2 → ดู `phase1-single-db.md` ไม่ใช่ control/tenant แยกจริง

## Migration paths ใน repo

| Phase | Path |
|-------|------|
| 1–2 | `supabase/migrations/` |
| 3+ control | `supabase/migrations/control/` |
| 3+ tenant | `supabase/migrations/tenant/` (ใช้ซ้ำทุก org) |
