# CRM Kai — Documentation Index

> **เปิด Cursor ครั้งแรก:** [00-overview/ONBOARDING.md](./00-overview/ONBOARDING.md)  
> **สถานะ code จริง:** [00-overview/PROJECT-STATUS.md](./00-overview/PROJECT-STATUS.md)  
> **ก่อนทำงาน:** [IRON-RULES.md](./IRON-RULES.md)

---

## อ่านเร็ว (Agent)

| ต้องการ | ไฟล์ |
|---------|------|
| โปรเจกต์คืออะไร / ทำถึงไหน | [PROJECT-STATUS.md](./00-overview/PROJECT-STATUS.md) |
| ตัดสินใจแล้ว (Supabase, Nuxt UI, …) | [DECISIONS.md](./00-overview/DECISIONS.md) |
| ศัพท์ org vs company | [GLOSSARY.md](./00-overview/GLOSSARY.md) |
| Column ทุกตาราง CRM | [tables.md](./06-crm-schema/tables.md) |
| ตารางอยู่ DB ไหน per phase | [PHASE-MATRIX.md](./02-database/PHASE-MATRIX.md) |
| Phase 1 ต้องทำอะไร | [PHASE-1-CHECKLIST.md](./07-phases/PHASE-1-CHECKLIST.md) |
| Local dev | [11-dev-setup/](./11-dev-setup/) |
| UI 2 ภาษา (th + en) | [12-i18n/](./12-i18n/) |
| Typography (ฟอนต์) | [12-i18n/TYPOGRAPHY.md](./12-i18n/TYPOGRAPHY.md) |

---

## ลำดับการอ่าน

| # | โฟลเดอร์ | อ่านเมื่อ |
|---|----------|-----------|
| 0 | [ONBOARDING](./00-overview/ONBOARDING.md) | ครั้งแรก |
| 1 | [IRON-RULES](./IRON-RULES.md) | ทุกครั้ง |
| 2 | [07-phases/](./07-phases/) | phase gate |
| 3 | [01-tech-stack/](./01-tech-stack/) | library / deploy |
| 4 | [02-database/](./02-database/) | DB + **DB-CHANGELOG / DB-SCHEMA** |
| 5 | [06-crm-schema/](./06-crm-schema/) | **tables.md**, permissions |
| 6 | [03-auth/](./03-auth/) … [10-security/](./10-security/) | ตามงาน |
| 7 | [11-dev-setup/](./11-dev-setup/) | รัน local |
| 8 | [12-i18n/](./12-i18n/) | UI string, locale, 2 ภาษา, **[TYPOGRAPHY.md](./12-i18n/TYPOGRAPHY.md)** |

---

## โครง docs

```
docs/
├── IRON-RULES.md · DOC-STANDARD.md · CHANGELOG.md
├── 00-overview/
│   ├── ONBOARDING.md · PROJECT-STATUS.md · DECISIONS.md · GLOSSARY.md
├── 02-database/
│   ├── DB-CHANGELOG.md · DB-SCHEMA.md · PHASE-MATRIX.md
├── 06-crm-schema/
│   ├── tables.md · permissions.md
├── 07-phases/
│   └── PHASE-1-CHECKLIST.md
└── 11-dev-setup/
```

---

## Quick Reference

| คำถาม | ไปที่ |
|--------|-------|
| ตอนนี้อยู่ phase ไหน มี code อะไร | `PROJECT-STATUS.md` |
| Schema column ครบ | `06-crm-schema/tables.md` |
| DB deploy แล้วเป็นอย่างไร | `02-database/DB-SCHEMA.md` |
| 🔴 Phase 1 flow | `09-flows/phase1-only.md` |
