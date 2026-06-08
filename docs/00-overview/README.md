# 00 — Overview

> **เปิด Cursor ครั้งแรก:** [ONBOARDING.md](./ONBOARDING.md)  
> **สถานะจริง:** [PROJECT-STATUS.md](./PROJECT-STATUS.md)

---

## ไฟล์สำคัญ

| ไฟล์ | อ่านเมื่อ |
|------|-----------|
| [ONBOARDING.md](./ONBOARDING.md) | ครั้งแรก — เข้าใจโปรเจกต์ |
| [PROJECT-STATUS.md](./PROJECT-STATUS.md) | docs vs code ทำถึงไหน |
| [DECISIONS.md](./DECISIONS.md) | ตัดสินใจแล้ว — ห้ามเดา |
| [GLOSSARY.md](./GLOSSARY.md) | org vs company |
| [README.md](./README.md) | ภาพรวม architecture |
| [CHANGELOG.md](./CHANGELOG.md) | เปลี่ยนล่าสุด |

---

## ภาพรวม

CRM Kai = Multi-tenant SaaS CRM — **Phase 1:** CRM core บน Supabase 1 project

## เป้าหมายระยะยาว

1. CRM: contacts, companies, deals, pipeline
2. SaaS: สมัคร, trial, แยก DB ต่อ org (Phase 3+)
3. Control plane: login, org, billing (Phase 3+)

## สถาปัตยกรการแยก DB (Phase 3+)

```
Control DB + Node API  →  login · org · trial · routing
         ↓
Tenant DB (1/org)      →  CRM
```

**Phase 1:** ยังไม่แยก — ดู [PHASE-MATRIX.md](../02-database/PHASE-MATRIX.md)

## เอกสารที่เกี่ยวข้อง

- [../07-phases/PHASE-1-CHECKLIST.md](../07-phases/PHASE-1-CHECKLIST.md)
- [../IRON-RULES.md](../IRON-RULES.md)
