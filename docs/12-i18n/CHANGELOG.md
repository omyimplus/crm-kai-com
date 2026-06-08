# Changelog — i18n

→ [README.md](./README.md)

---

## ประวัติ

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
