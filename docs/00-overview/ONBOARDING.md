# Onboarding — อ่านไฟล์นี้ก่อน (CRM Kai)

> เปิด Cursor ของบริษัทครั้งแรก **อ่านไฟล์นี้ → ไม่ต้องถามคนที่สร้างโปรเจกต์**

---

## โปรเจกต์นี้คืออะไร

**CRM Kai** = SaaS CRM ให้บริษัท/องค์กรสมัครใช้ มี trial ฟรี และแยก database CRM ต่อ org ในอนาคต

**🔴 ตอนนี้อยู่ Phase 1** — สร้าง CRM core ก่อน (contacts, companies, deals, pipeline) บน **Supabase 1 project**

---

## อ่าน 5 ไฟล์นี้ (ลำดับ)

| # | ไฟล์ | ได้อะไร |
|---|------|---------|
| 1 | [PROJECT-STATUS.md](./PROJECT-STATUS.md) | code มีอะไรแล้ว / ยังไม่มี |
| 2 | [IRON-RULES.md](../IRON-RULES.md) | กฎเหล็ก |
| 3 | [DECISIONS.md](./DECISIONS.md) | ตัดสินใจแล้ว — ห้ามเดา |
| 4 | [PHASE-1-CHECKLIST.md](../07-phases/PHASE-1-CHECKLIST.md) | ต้องทำอะไรให้ Phase 1 เสร็จ |
| 5 | [GLOSSARY.md](./GLOSSARY.md) | org vs company ฯลฯ |

---

## Tech stack ปัจจุบัน (Phase 1)

| ชั้น | ใช้ |
|------|-----|
| Frontend | Nuxt 3 + Tailwind + **Nuxt UI** + TypeScript |
| DB + Auth | Supabase (Postgres + Auth + RLS) |
| Backend API | **ยังไม่มี** — frontend ต่อ Supabase ตรง |

---

## 🔴 Phase 1 vs ⚪ Phase 3+ (อย่าสับสน)

| | Phase 1 (ตอนนี้) | Phase 3+ (อนาคต) |
|--|-----------------|------------------|
| DB | Supabase **1 project** + org_id | Control DB + Tenant DB แยก |
| Auth | Supabase Auth + profiles.org_id | Auth กลาง + API |
| API | ไม่มี | Node Control Plane |
| User / org | **1 user = 1 org** | หลาย org ได้ |

รายละเอียด → [PHASE-MATRIX.md](../02-database/PHASE-MATRIX.md)

---

## Schema CRM (source of truth)

→ [tables.md](../06-crm-schema/tables.md) — column ครบทุกตาราง

---

## โครง repo ตอนนี้

```
crm-kai-com/
├── docs/              ← เอกสารทั้งหมด (เริ่มที่นี่)
├── frontend/          ← (ยังไม่สร้าง) Nuxt
├── supabase/          ← (ยังไม่สร้าง) migrations
└── README.md
```

---

## ดูการเปลี่ยนแปลงล่าสุด

| ประเภท | ไฟล์ |
|--------|------|
| สถานะโปรเจกต์ | [PROJECT-STATUS.md](./PROJECT-STATUS.md) |
| Database | [DB-CHANGELOG.md](../02-database/DB-CHANGELOG.md) |
| Schema deploy | [DB-SCHEMA.md](../02-database/DB-SCHEMA.md) |
| โฟลเดอร์ docs | [CHANGELOG.md](./CHANGELOG.md) |

---

## Agent — ก่อนจบงาน

- [ ] CHANGELOG โฟลเดอร์ที่แก้
- [ ] DB-CHANGELOG + DB-SCHEMA ถ้าแตะ DB
- [ ] อัปเดต PROJECT-STATUS ถ้า milestone เปลี่ยน

*อัปเดต: 2026-06-08*
