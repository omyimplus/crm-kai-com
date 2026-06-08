# Changelog — Overview

บันทึกการสร้าง / แก้ไข / ลบ ในโดเมน **ภาพรวม & onboarding**

→ ออกแบบปัจจุบัน: [README.md](./README.md) | [ONBOARDING.md](./ONBOARDING.md)

---

## ประวัติ

### 2026-06-08 — add D-011 Node 22 LTS

- **ทำอะไร:** ADR Node version ทั้งระบบ + api scaffold
- **ไฟล์ที่กระทบ:** `DECISIONS.md`, `PROJECT-STATUS.md`
- **Phase:** 1

## ประวัติ

### 2026-06-08 — update D-010: Noto default ทั้งระบบ (interim)

- **ทำอะไร:** เปลี่ยนจาก locale fonts เป็น Noto Sans Thai จนกว่า user จะสั่ง
- **ไฟล์ที่กระทบ:** `DECISIONS.md`, `TYPOGRAPHY.md`
- **Phase:** 1

### 2026-06-08 — add D-010 typography ตาม locale

- **ทำอะไร:** ADR ฟอนต์ Noto Sans Thai / Taviraj / Prompt
- **ไฟล์ที่กระทบ:** `DECISIONS.md`
- **Phase:** 1

### 2026-06-08 — add D-009 UI 2 ภาษา (th + en)

- **ทำอะไร:** ADR บังคับ i18n ทุกหน้า UI
- **ไฟล์ที่กระทบ:** `DECISIONS.md`
- **Phase:** 1

### 2026-06-08 — update ปิดช่องว่าง docs (onboard + schema + phase ชัด)

- **ทำอะไร:** สร้าง PROJECT-STATUS, DECISIONS, GLOSSARY, PHASE-MATRIX, tables.md, permissions, PHASE-1-CHECKLIST, phase1-only, dev-setup, migration doc; อัปเดต READMEs ด้วยป้าย Phase 1
- **ไฟล์ที่กระทบ:** `00-overview/*`, `02-database/PHASE-MATRIX.md`, `06-crm-schema/tables.md`, `07-phases/PHASE-1-CHECKLIST.md`, `09-flows/phase1-only.md`, `11-dev-setup/`, `IRON-RULES.md`, `DOC-STANDARD.md`, `README.md`, `.cursor/rules/`
- **เหตุผล:** ลดความสับสน Phase 1 vs 3, schema source of truth, onboard ได้เอง
- **Phase:** 1

### 2026-06-08 — create ระบบ onboarding + doc standard

- **ทำอะไร:** สร้าง ONBOARDING.md สำหรับเปิด Cursor ครั้งแรกเข้าใจโปรเจกต์ได้ทันที
- **ไฟล์ที่กระทบ:** `ONBOARDING.md`, `../DOC-STANDARD.md`, `../IRON-RULES.md`
- **เหตุผล:** กฎเหล็กข้อ 3 — ไม่ต้องอธิบายซ้ำเมื่อ login Cursor บริษัท
- **Phase:** 1
- **ผลกระทบ:** จุดเริ่ม onboarding อยู่ที่ไฟล์นี้
