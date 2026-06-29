# Changelog — i18n

→ [README.md](./README.md)

---

## ประวัติ

### 2026-06-25 — KuTo: รายชื่อผู้ติดต่อ

- **ทำอะไร:** `frontend-kuto` — `/app/customers/contacts` mock · keys `kuto.customers.contacts.list.*`

### 2026-06-25 — KuTo: แยกคำ Leads (เป้าหมาย) vs ลูกค้า (prospect status)

- **ทำอะไร:** `frontend-kuto` — Leads เมนู/หน้าใช้ **เป้าหมาย** · แท็บลูกค้า `status=prospect` → **สถานะ: เป้าหมาย** / EN Prospect
- **ไฟล์:** `frontend-kuto/i18n/locales/{th,en}.json` · keys `kuto.nav.sub.leads.*`, `kuto.leads.*`, `kuto.customers.list.tabs.target`

### 2026-06-22 — Body weight 500 (Medium)

- **ทำอะไร:** เนื้อหา/UI ใช้ IBM Plex Sans Thai **500** แทน 400 · โหลด `wght@400;500;600`
- **อ้างอิง:** D-010 · [TYPOGRAPHY.md](./TYPOGRAPHY.md)

### 2026-06-16 — Customer Status i18n (5 lifecycle)

- **ทำอะไร:** `masterData.customer.options.status` — active … pending (th + en)
- **ไฟล์ที่กระทบ:** `i18n/locales/{th,en}.json`
- **Phase:** 1

### 2026-06-16 — Customer form i18n ภาษาไทยครบ

- **ทำอะไร:** แปล `masterData.customer.*` ใน `th.json` (sections, fields, ship, options) · placeholder ผ่าน i18n
- **ไฟล์ที่กระทบ:** `i18n/locales/th.json`, `i18n/locales/en.json`, `MasterDataCustomerForm.vue`
- **Phase:** 1

### 2026-06-16 — IBM Plex Sans Thai ทั้งระบบ

- **ทำอะไร:** Headline SemiBold (600) · Body Regular (400) — แทน Noto/Sarabun
- **ไฟล์ที่กระทบ:** `TYPOGRAPHY.md`, `app.vue`, `main.css`, D-010
- **Phase:** 1

### 2026-06-08 — default Noto Sans Thai ทั้งระบบ (interim)

- **ทำอะไร:** อัปเดต TYPOGRAPHY + README — Noto default, Taviraj/Prompt รอสั่ง user
- **ไฟล์ที่กระทบ:** `TYPOGRAPHY.md`, `README.md`
- **Phase:** 1

### 2026-06-08 — create TYPOGRAPHY.md (เอกสารฟอนต์เต็ม)

- **ทำอะไร:** MD กฎฟอนต์ — ไทย: Noto Sans Thai (หัวข้อ) + Taviraj (คำอธิบาย), EN: Prompt เท่านั้น
- **ไฟล์ที่กระทบ:** `TYPOGRAPHY.md`, `README.md`, `IRON-RULES.md`, `docs/README.md`, `05-frontend/`, `DECISIONS.md`, `.cursor/rules/`
- **Phase:** 1

### 2026-06-08 — add typography ตาม locale (Noto Sans Thai / Taviraj / Prompt)

- **ทำอะไร:** ฟอนต์ Google Fonts — ไทย: Noto Sans Thai (หัวข้อ) + Taviraj (เนื้อหา), EN: Prompt ทั้งหมด
- **ไฟล์ที่กระทบ:** `frontend/app/assets/css/main.css`, `app.vue`, `layouts/app.vue`, `README.md`
- **Phase:** 1

### 2026-06-08 — create ระบบ 2 ภาษา (th + en) Phase 1

- **ทำอะไร:** บังคับ UI 2 ภาษา login + CRM — `@nuxtjs/i18n`, locale files, LocaleSwitcher, useFormat, เอกสารกฎ
- **ไฟล์ที่กระทบ:** `frontend/i18n/**`, `frontend/app/**`, `docs/12-i18n/`, `IRON-RULES.md`, `DECISIONS.md` (D-009)
- **Phase:** 1
- **หมายเหตุ:** pipeline stage names ใน seed ยังเป็นภาษาอังกฤษ (user content — Phase 2+)
