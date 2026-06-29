# Decisions (ADR) — การตัดสินใจที่ปิดแล้ว

> Agent **ห้ามเดาใหม่** ถ้าขัดกับรายการนี้ — ต้องถาม user ก่อนเปลี่ยน  
> ประวัติ → [CHANGELOG.md](./CHANGELOG.md)

---

## D-001: เริ่ม CRM ก่อน SaaS onboarding

| | |
|--|--|
| **ตัดสินใจ** | Phase 1 = CRM core ใน 1 org ก่อน landing/register/multi-tenant |
| **เหตุผล** | validate product เร็ว ไม่ติด infra |
| **Phase** | 1 |
| **สถานะ** | ✅ ใช้งาน |

---

## D-002: Supabase ก่อน ไม่ใช่ Postgres เปล่าตั้งแต่ Phase 1

| | |
|--|--|
| **ตัดสินใจ** | Phase 1–2 ใช้ **Supabase Cloud** (Auth + RLS + migrations) |
| **เหตุผล** | Auth ย้ายยาก — ใช้ Supabase ประหยัดเวลา; schema/RLS ย้ายไป Postgres ทีหลังได้ |
| **ย้ายเมื่อ** | Phase 3+ พิจารณา Postgres self-host ถ้า tenant เยอะ |
| **อ้างอิง** | [migration-supabase-to-postgres.md](../01-tech-stack/migration-supabase-to-postgres.md) |
| **สถานะ** | ✅ ใช้งาน |

---

## D-003: Phase 1 — 1 Supabase project + org_id ทุกตาราง CRM

| | |
|--|--|
| **ตัดสินใจ** | DB เดียว ไม่แยก Control/Tenant จริง |
| **เหตุผล** | ย้ายไป multi-tenant ได้โดย export ตาม org_id |
| **อ้างอิง** | [phase1-single-db.md](../02-database/phase1-single-db.md) |
| **สถานะ** | ✅ ใช้งาน |

---

## D-004: Phase 1 — 1 user = 1 org (ยังไม่ multi-org)

| | |
|--|--|
| **ตัดสินใจ** | ใช้ `profiles.org_id` เท่านั้น — **ยังไม่มี** `organization_members` |
| **เหตุผล** | ลด complexity Phase 1 |
| **Phase 3+** | เพิ่ม `organization_members` สำหรับ user หลาย org |
| **สถานะ** | ✅ ใช้งาน |

---

## D-005: CRM data ไม่ผ่าน Node API proxy

| | |
|--|--|
| **ตัดสินใจ** | Nuxt → Supabase ตรง (anon + RLS) สำหรับ CRM |
| **เหตุผล** | เร็ว, ไม่ซ้ำ layer |
| **Phase 3+** | CRM ยังต่อ Tenant Supabase ตรง — Control ผ่าน API เท่านั้น |
| **สถานะ** | ✅ ใช้งาน |

---

## D-006: UI library — Nuxt UI

| | |
|--|--|
| **ตัดสินใจ** | ใช้ **Nuxt UI** (ไม่ใช่ shadcn-vue) |
| **เหตุผล** | integrate กับ Nuxt 3 ได้ดี ทีมเล็ก setup เร็ว |
| **สถานะ** | ✅ ใช้งาน — เปลี่ยนได้ถ้า user สั่ง |

---

## D-007: คำศัพท์ org vs company

| | |
|--|--|
| **ตัดสินใจ** | `org` = tenant SaaS · `company` = ลูกค้าใน CRM |
| **อ้างอิง** | [GLOSSARY.md](./GLOSSARY.md) |
| **สถานะ** | ✅ ใช้งาน |

---

## ยังไม่ตัดสินใจ (อย่า assume)

| หัวข้อ | ตัดสินเมื่อ |
|--------|-------------|
| Deploy frontend (Vercel vs Cloudflare) | ก่อน deploy ครั้งแรก |
| Postgres self-host vs Supabase ต่อ tenant | Phase 3 |
| Payment (Stripe vs Omise) | Phase 5 |
| Subdomain vs path สำหรับ tenant | Phase 3 |

---

## D-008: Phase 1 — `/signup` สำหรับ demo org (ไม่ใช่ SaaS register)

| | |
|--|--|
| **ตัดสินใจ** | มี `/signup` ผูก user กับ demo org ผ่าน `signup_profile()` RPC |
| **เหตุผล** | Phase 1 ห้าม landing/register แต่ต้องสร้าง user ได้ — ไม่ใช่ trial SaaS |
| **Phase 4** | แทนที่ด้วย `/register` + provision |
| **สถานะ** | ✅ ใช้งาน Phase 1 |

---

## D-009: UI 2 ภาษา — ไทย + English (บังคับทุก phase)

| | |
|--|--|
| **ตัดสินใจ** | ทุกหน้า UI รองรับ **ไทย (default)** และ **English** — login, signup, CRM |
| **เหตุผล** | ผู้ใช้ไทย + ทีม/ลูกค้าต่างชาติ; ไม่เพิ่ม URL prefix (`no_prefix`) |
| **Implementation** | `@nuxtjs/i18n`, `frontend/i18n/locales/{th,en}.json`, `LocaleSwitcher`, `useFormat()` |
| **อ้างอิง** | [12-i18n/README.md](../12-i18n/README.md) · IRON-RULES §12 |
| **สถานะ** | ✅ ใช้งาน Phase 1 |

---

## D-010: Typography

| | |
|--|--|
| **ตัดสินใจ (ปัจจุบัน)** | **IBM Plex Sans Thai** — Headline SemiBold (600) · Body Medium (500) · ทุก locale + auth |
| **เปลี่ยนเมื่อ** | user สั่งเท่านั้น |
| **Implementation** | Google Fonts ใน `app.vue`, `--font-sans` / `--font-heading` ใน `main.css` |
| **อ้างอิง** | [TYPOGRAPHY.md](../12-i18n/TYPOGRAPHY.md) |
| **สถานะ** | ✅ ใช้งาน |

---

## D-012: Data change log — ตารางแยกทุก flow

| | |
|--|--|
| **ตัดสินใจ** | ทุก create/update/delete ข้อมูล → บันทึก `data_change_logs` ผ่าน `write_data_change_log()` |
| **เหตุผล** | audit trail สม่ำเสมอ แยกจาก `activities` (CRM timeline) |
| **ห้าม** | เก็บ password/secret ใน log · แก้/ลบ log ย้อนหลัง |
| **อ้างอิง** | [DATA-CHANGE-LOG.md](../06-crm-schema/DATA-CHANGE-LOG.md) · IRON-RULES §13 |
| **สถานะ** | ✅ ใช้งาน (system users) · โมดูลอื่น Phase 2+ |

---

## D-011: Node.js 24 LTS — ทั้งระบบ

| | |
|--|--|
| **ตัดสินใจ** | ใช้ **Node >= 24.11.0** ทุก package (`frontend`, `api`, CI) |
| **เหตุผล** | Latest LTS (Node 24); Nuxt 4 รองรับ `^24.11.0`; API ใช้ runtime เดียวกันลดความสับสน |
| **Source of truth** | [`.nvmrc`](../../.nvmrc) · [NODE-VERSION.md](../11-dev-setup/NODE-VERSION.md) |
| **สถานะ** | ✅ ใช้งาน |
