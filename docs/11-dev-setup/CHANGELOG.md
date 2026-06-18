# Changelog — Dev Setup

→ [README.md](./README.md)

---

## ประวัติ

### 2026-06-18 — กฎ QA: Claude agent เท่านั้น

- **ทำอะไร:** บังคับรอบ tester ใช้ Cursor Agent = Claude · อัปเดต `qa-testing.mdc` + `QA-GUIDE.md`
- **ไฟล์ที่กระทบ:** `.cursor/rules/qa-testing.mdc`, `QA-GUIDE.md`

### 2026-06-18 — QA-LEADS.md (สร้างลีด 2 โหมด)

- **ทำอะไร:** Checklist tester ชั้น 0–7 · Flow A ลูกค้าในระบบ · Flow B ลูกค้าใหม่ · SQL verify · รายการที่ควรมีเพิ่ม
- **ไฟล์ที่กระทบ:** `QA-LEADS.md`, `QA-GUIDE.md`, `README.md`

### 2026-06-08 — QA Master Data smoke + 2-user

- **ทำอะไร:** Smoke test 11 เมนู · admin vs employee (archive tabs, Setup, RLS restore)
- **ไฟล์ที่กระทบ:** `QA-MASTER-DATA.md`, `TEST-ACCOUNTS.md`, `PHASE-1-CHECKLIST.md`
- **Phase:** 1

### 2026-06-08 — อัปเกรด Node 24 LTS ทั้งระบบ

- **ทำอะไร:** `.nvmrc` → `24`; `engines` frontend/api → `>=24.11.0`; CI matrix → 24; อัปเดต D-011, NODE-VERSION.md
- **ไฟล์ที่กระทบ:** `.nvmrc`, `frontend/package.json`, `api/package.json`, `frontend/.github/workflows/ci.yml`, docs
- **Phase:** 1

### 2026-06-17 — QA-GUIDE ชั้น 7 (Bypass / API นอกระบบ)

- **ทำอะไร:** tester ยิง endpoint/RPC ที่ Phase 1 ไม่มี + ทะลุ auth/RLS — ต้องทะลุไม่ได้ (X1–X18)
- **ไฟล์ที่กระทบ:** `QA-GUIDE.md`, `QA-CUSTOMER-CONTACT.md`, `qa-testing.mdc`
- **Phase:** 1

### 2026-06-17 — qa-testing.mdc (กฎ tester อ่าน QA-GUIDE)

- **ทำอะไร:** Cursor rule + แถวใน `crm-kai-docs.mdc` — งาน QA/tester ต้องอ่าน `QA-GUIDE.md` ก่อน
- **ไฟล์ที่กระทบ:** `.cursor/rules/qa-testing.mdc`, `crm-kai-docs.mdc`, `QA-GUIDE.md`
- **Phase:** 1

### 2026-06-17 — QA-GUIDE.md (ชั้นทดสอบ 0–6)

- **ทำอะไร:** คู่มือ tester — ชั้น Environment → DB → API → UI → Permission → E2E → Audit
- **ไฟล์ที่กระทบ:** `QA-GUIDE.md`, อัปเดต `QA-CUSTOMER-CONTACT.md` เป็น checklist ตามชั้น
- **Phase:** 1

### 2026-06-17 — QA-CUSTOMER-CONTACT.md

- **ทำอะไร:** รายงาน QA Master Data ลูกค้า + ผู้ติดต่อ (API + Browser) · บัค migration 39/42
- **ไฟล์ที่กระทบ:** `QA-CUSTOMER-CONTACT.md`, `TEST-ACCOUNTS.md`, `README.md`
- **Phase:** 1

### 2026-06-08 — Node 20 + Supabase Realtime WebSocket

- **ทำอะไร:** บันทึกใน NODE-VERSION — frontend ตั้ง `ws` transport สำหรับ SSR บน Node < 22
- **ไฟล์ที่กระทบ:** `NODE-VERSION.md`
- **Phase:** 1

### 2026-06-08 — TEST-ACCOUNTS.md (username login tester1)

- **ทำอะไร:** บันทึกบัญชีทดสอบ Browser Tester + checklist login email/username
- **ไฟล์ที่กระทบ:** `TEST-ACCOUNTS.md`, `README.md`, `phase1-only.md`, `login.md`, `03-auth/README.md`
- **Phase:** 1
- **หมายเหตุ:** username login ต้องรัน migration 17 บน Supabase ก่อน

### 2026-06-08 — add NODE-VERSION.md + Node 22 ทั้งระบบ

- **ทำอะไร:** กำหนด Node >=22.12.0, `.nvmrc`, อัปเดต prerequisites
- **ไฟล์ที่กระทบ:** `NODE-VERSION.md`, `README.md`, `DECISIONS D-011`
- **Phase:** 1

### 2026-06-08 — create dev setup guide (แผน)

- **ทำอะไร:** สร้าง README local dev, env, migration workflow
- **ไฟล์ที่กระทบ:** `README.md`
- **Phase:** 1
- **หมายเหตุ:** ยังไม่มี code — ใช้เมื่อ scaffold
