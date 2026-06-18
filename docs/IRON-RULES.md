# กฎเหล็ก (Iron Rules) — CRM Kai Documentation

> **บังคับ:** AI Agent และ developer ต้องอ่านไฟล์นี้ก่อนทำงานทุกครั้ง  
> ฝ่าฝืน = ออกแบบผิดชั้น (Control vs Tenant) หรือ implement เกิน phase

---

## กฎที่ 1 — อ่านเอกสารตามโฟลเดอร์ ห้ามเดา

| งานที่ทำ | ต้องอ่าน |
|----------|----------|
| เริ่ม session / ไม่รู้โปรเจกต์ | [ONBOARDING.md](./00-overview/ONBOARDING.md) → [PROJECT-STATUS.md](./00-overview/PROJECT-STATUS.md) |
| ตัดสินใจแล้วห้ามเดา | [DECISIONS.md](./00-overview/DECISIONS.md) |
| ศัพท์ org vs company | [GLOSSARY.md](./00-overview/GLOSSARY.md) |
| สร้าง/แก้ migration, SQL, RLS | [tables.md](./06-crm-schema/tables.md) + [DATA-CHANGE-LOG.md](./06-crm-schema/DATA-CHANGE-LOG.md) + [PHASE-MATRIX.md](./02-database/PHASE-MATRIX.md) + DB-CHANGELOG |
| Login, session, role | `docs/03-auth/` + [permissions.md](./06-crm-schema/permissions.md) |
| Node API, provision | `docs/04-api/` (Phase 3+ เท่านั้น) |
| Nuxt pages, composables | `docs/05-frontend/` + [PHASE-1-CHECKLIST.md](./07-phases/PHASE-1-CHECKLIST.md) |
| CRM sidebar menu | [05-frontend/APP-MENU.md](./05-frontend/APP-MENU.md) |
| Setup / admin menu | [05-frontend/SETUP-MENU.md](./05-frontend/SETUP-MENU.md) |
| Master data menu | [05-frontend/MASTER-DATA-MENU.md](./05-frontend/MASTER-DATA-MENU.md) |
| Logo / brand assets | [05-frontend/BRAND-ASSETS.md](./05-frontend/BRAND-ASSETS.md) |
| วางโฟลเดอร์ใหม่ | `docs/08-repo-structure/` + `docs/07-phases/` |
| Local dev | `docs/11-dev-setup/` |
| UI string, ภาษา, locale | `docs/12-i18n/` + [DECISIONS D-009](./00-overview/DECISIONS.md) |
| ฟอนต์ / typography | [12-i18n/TYPOGRAPHY.md](./12-i18n/TYPOGRAPHY.md) + [D-010](./00-overview/DECISIONS.md) |
| ไม่แน่ใจ feature ทำได้ไหม | `docs/07-phases/` ก่อนเสมอ |

**ห้าม** อ้าง architecture จาก memory อย่างเดียว — เปิดไฟล์ในโฟลเดอร์ที่เกี่ยวข้องก่อน implement

---

## กฎที่ 2 — Database 2 กลุ่ม (Phase 3+)

```
กลุ่ม 1: Control DB (1 ตัว)     → login, org registry, trial, tenant routing
กลุ่ม 2: Tenant DB (1 ต่อ org)  → CRM เท่านั้น (contacts, deals, ...)
```

| ห้าม | ต้อง |
|-----|------|
| เก็บ deals/contacts ใน Control DB | CRM อยู่ Tenant DB เท่านั้น |
| Frontend ต่อ Control DB ตรง (Phase 3+) | Control DB ผ่าน Node API |
| ใส่ service role key ใน frontend | encrypt ใน Control DB, ใช้ใน API |
| ใส่ `org_id` ใน Tenant DB (Phase 3+) | ทั้ง DB = 1 org แล้ว |

**Phase 1–2 ข้อยกเว้น:** ใช้ Supabase **project เดียว** — ทุกตาราง CRM มี `org_id` → ดู `02-database/phase1-single-db.md`

---

## กฎที่ 3 — การเข้าถึง Data

| ชั้น | Phase 1–2 | Phase 3+ |
|------|-----------|----------|
| CRM (contacts, deals, …) | Nuxt → Supabase ตรง (anon + RLS) | Nuxt → **Tenant** Supabase ตรง |
| Control (org, trial, config) | Nuxt → Supabase ตรง (same project) | Nuxt → **Node API** → Control DB |

**ห้าม** Node API proxy ทุก CRM request — ใช้ Supabase + RLS

---

## กฎที่ 4 — คำศัพท์ (ห้ามสลับ)

| คำ | ความหมาย |
|----|----------|
| **organization / org** | ลูกค้า SaaS (tenant) — สมัครใช้ CRM |
| **company** | ลูกค้าของ org **ใน CRM** (ไม่ใช่ tenant) |
| **contact** | บุคคลใน CRM |
| **deal** | ดีล/โอกาสขาย |
| **Control DB** | ระบบกลาง 1 ตัว |
| **Tenant DB** | CRM ของ org หนึ่ง |

---

## กฎที่ 5 — Phase Gate (ห้ามข้าม phase)

อ่านรายละเอียดใน `docs/07-phases/`

| Phase ปัจจุบัน | ทำได้ | ห้ามทำ |
|--------------|-------|--------|
| **1** | CRM core, login, 1 Supabase, org_id | landing, register API, multi-tenant, queue, billing |
| **2** | roles, activities, polish | provision tenant, Control API |
| **3** | Control DB, Node API, manual provision | auto register, Stripe |
| **4** | landing, register, trial, email, queue | — |
| **5** | billing, ops, migration runner | — |

**ถ้า user ขอ feature ข้าม phase** → แจ้ง phase ที่เหมาะสม แล้วถามยืนยันก่อนทำ

---

## กฎที่ 6 — แก้เอกสารเมื่อ design เปลี่ยน

เมื่อเปลี่ยน architecture:

1. แก้ไฟล์ในโฟลเดอร์ย่อยที่เกี่ยวข้อง (ไม่ใส่ทุกอย่างในไฟล์เดียว)
2. ถ้ากระทบหลายระบบ → อัปเดต `00-overview/` ด้วย
3. ห้ามให้เอกสารขัดกัน — ถ้าขัด ให้ `IRON-RULES.md` และ `07-phases/` เป็น source of truth ด้านลำดับ phase

---

## กฎที่ 7 — โครง repo ตาม phase

| Phase | โฟลเดอร์ code ที่มี |
|-------|---------------------|
| 1–2 | `frontend/`, `api/` (scaffold), `supabase/migrations/` |
| 3+ | + `api/` (logic), `supabase/migrations/control/`, `supabase/migrations/tenant/`, `scripts/` |

**ห้าม** implement register/provision/proxy CRM ใน `api/` ก่อน Phase 3 — scaffold + health OK

---

## กฎที่ 8 — Security (ไม่ negotiable)

ดู checklist เต็มใน `docs/10-security/`

- RLS ทุกตาราง CRM
- Frontend = anon key เท่านั้น
- Tenant config จาก API หลัง verify member + subscription
- Rate limit `/register` และ provision

---

## กฎที่ 9 — บันทึกทุก action เป็น MD (บังคับ)

**สร้าง / แก้ / ลบ** ในระบบใดๆ → เพิ่ม entry ใน `CHANGELOG.md` ของโฟลเดอร์นั้น **ก่อนจบงาน**

| ที่แก้ | บันทึกที่ |
|--------|----------|
| `docs/05-frontend/` | `docs/05-frontend/CHANGELOG.md` |
| `frontend/` (code) | `frontend/CHANGELOG.md` |
| หลายโฟลเดอร์ | CHANGELOG ทุกโฟลเดอร์ที่กระทบ + `docs/CHANGELOG.md` ถ้ากว้าง |

รูปแบบ entry → ดู [DOC-STANDARD.md](./DOC-STANDARD.md)

**ห้าม** commit งานโดยไม่มี CHANGELOG entry

---

## กฎที่ 10 — DB ต้องมี MD แยกชัด (บังคับ)

ทุกครั้งที่ **สร้าง / แก้ / ลบ** database (migration, table, RLS, seed, function):

1. บันทึก [02-database/DB-CHANGELOG.md](./02-database/DB-CHANGELOG.md)
2. อัปเดต [02-database/DB-SCHEMA.md](./02-database/DB-SCHEMA.md) ให้ตรง schema จริง
3. บันทึก `docs/02-database/CHANGELOG.md` ด้วย
4. ถ้า schema CRM → อัปเดต `docs/06-crm-schema/README.md` ถ้า design เปลี่ยน

| ไฟล์ | หน้าที่ |
|------|---------|
| `DB-CHANGELOG.md` | ประวัติทุก action DB (เรียงใหม่สุดบน) |
| `DB-SCHEMA.md` | snapshot ปัจจุบัน — อ่านแล้วรู้ schema ทันที |

เมื่อมี `supabase/` → สร้าง `supabase/DB-README.md` ชี้มาที่ docs + list migrations

---

## กฎที่ 11 — MD ต้อง onboard ได้เอง (บังคับ)

ทุกไฟล์ md ต้องเขียนให้ **เปิด Cursor บริษัทแล้วเข้าใจโปรเจกต์ได้โดยไม่ถามคนสร้าง**

- มี **บริบท** (โปรเจกต์คืออะไร, phase ไหน)
- มี **สถานะปัจจุบัน** (ทำแล้ว / ยังไม่ทำ)
- มี **ลิงก์** ไปเอกสารที่เกี่ยวข้อง
- มี **CHANGELOG** สำหรับดูว่าเปลี่ยนอะไรล่าสุด

**จุดเริ่ม onboarding:** [00-overview/ONBOARDING.md](./00-overview/ONBOARDING.md) → [PROJECT-STATUS.md](./00-overview/PROJECT-STATUS.md)

**Schema CRM (column):** [06-crm-schema/tables.md](./06-crm-schema/tables.md)

**Phase 1 ต้องทำอะไร:** [07-phases/PHASE-1-CHECKLIST.md](./07-phases/PHASE-1-CHECKLIST.md)

---

## กฎที่ 12 — UI 2 ภาษาเสมอ (บังคับ)

**ทุกหน้า UI** ต้องรองรับ **ไทย + English** — รวม login, signup และ CRM ทั้งหมด

| ห้าม | ต้อง |
|-----|------|
| hardcode ข้อความ UI ใน Vue | ใช้ `$t()` / `useI18n().t()` จาก locale files |
| เพิ่ม key แค่ภาษาเดียว | แก้ **ทั้ง** `frontend/i18n/locales/th.json` และ `en.json` |
| หน้าใหม่ไม่มีสลับภาษา | ใส่ `LocaleSwitcher` (auth) หรือใช้ layout `app` (CRM) |
| hardcode `Intl` locale | ใช้ `useFormat()` สำหรับเงิน/ตัวเลข |
| hardcode `font-family` / ใช้ฟอนต์นอกกำหนด | [TYPOGRAPHY.md](./12-i18n/TYPOGRAPHY.md) — **IBM Plex Sans Thai** ตาม D-010 |

**อ่านรายละเอียด:** [12-i18n/README.md](./12-i18n/README.md) · **Typography:** [12-i18n/TYPOGRAPHY.md](./12-i18n/TYPOGRAPHY.md) · **ADR:** [D-009](./00-overview/DECISIONS.md), [D-010](./00-overview/DECISIONS.md)

**ข้อยกเว้น Phase 1:** ชื่อ pipeline stage ใน DB seed, ข้อมูล CRM (contact/company/deal), error จาก Supabase — ไม่ใช่ UI string

---

## กฎที่ 13 — Data change log ทุก flow (บังคับ)

**ทุกครั้ง** ที่สร้าง / แก้ / ลบข้อมูลในระบบ → บันทึกลงตาราง **`data_change_logs`** แยกจากตารางหลัก

| ห้าม | ต้อง |
|-----|------|
| INSERT/UPDATE/DELETE ข้อมูลโดยไม่มี log | เรียก `write_data_change_log(...)` ใน RPC หรือ trigger |
| บันทึก password, token, secret ใน log | เก็บ snapshot ฟิลด์ทั่วไป + flag เช่น `password_changed` |
| ให้ client INSERT log ตรง | INSERT ผ่าน `write_data_change_log` (SECURITY DEFINER) เท่านั้น |
| แก้/ลบแถว log ย้อนหลัง | log เป็น immutable (SELECT only สำหรับ owner/admin) |

**อ่านรายละเอียด:** [06-crm-schema/DATA-CHANGE-LOG.md](./06-crm-schema/DATA-CHANGE-LOG.md)

**แยกจาก:** `activities` (CRM timeline) · `deal_stage_history` (stage ดีล)

---

## Flowchart: Agent เริ่มงานยังไง

```
ได้รับ task
    │
    ▼
อ่าน ONBOARDING.md → PROJECT-STATUS.md → IRON-RULES.md (ไฟล์นี้)
    │
    ▼
เช็ค phase ปัจจุบัน → 07-phases/
    │
    ▼
เปิดโฟลเดอร์ docs ที่เกี่ยวกับ task + CHANGELOG ของโฟลเดอร์นั้น
    │
    ▼
implement ตามเอกสารนั้น
    │
    ▼
สร้าง/แก้/ลบอะไร → บันทึก CHANGELOG (+ DB-CHANGELOG ถ้าแตะ DB)
    │
    ▼
แตะข้อมูลใน DB? → เขียน data_change_logs (กฎที่ 13)
    │
    ▼
design เปลี่ยน? → อัปเดต README + DB-SCHEMA ในโฟลเดอร์ที่เกี่ยวข้อง
```
