# Master Data Menu — Scaffold

> **สถานะ:** Coming soon ทุกหน้า  
> **Config:** `frontend/app/config/masterDataMenu.ts`

---

## ภาพรวม

เมนู **ข้อมูลหลัก (Master Data)** อยู่ใน sidebar ถัดจาก **Menu** — เก็บข้อมูลอ้างอิงขององค์กร (ดู [APP-MENU.md](./APP-MENU.md))

| # | เมนู | Route | สถานะ |
|---|------|-------|--------|
| 1 | Customer | `/app/customer` | ✅ |
| 2 | Contact | `/app/contact` | ✅ |
| 3 | Sales target | `/app/master-data/sales-target` | ⏳ |
| 4 | Products | `/app/master-data/products` | ⏳ |
| 5 | Category | `/app/master-data/category` | ⏳ |
| 6 | Lead source | `/app/master-data/lead-source` | ⏳ |
| 7 | Unit | `/app/master-data/unit` | ⏳ |
| 8 | Employee | `/app/master-data/employee` | ⏳ |
| 9 | Sales team | `/app/master-data/sales-team` | ⏳ |
| 10 | Module statuses | `/app/master-data/module-statuses` | ⏳ |
| 11 | Job code (รหัสงาน) | `/app/master-data/job-code` | ⏳ |

> **กำหนด Role** ย้ายไป **Setup** → `/app/setup/roles` — ดู [SETUP-MENU.md § Roles](./SETUP-MENU.md)

---

## 11 — Job code / รหัสงาน

**วัตถุประสงค์:** สร้างเลขที่เอกสาร/รหัสงานอัตโนมัติ — **ทุกส่วนกำหนดได้**

| ส่วน | ตัวอย่าง | กำหนดได้ |
|------|----------|----------|
| คำนำหน้า (ตัวอักษร) | `JOB`, `QT`, `INV` | default + ต่อโมดูล |
| วันที่ | `20260608` หรือ `2026-06-08` | ปี/เดือน/วัน เปิด-ปิด แต่ละส่วน |
| Running number | `0001` | ความยาว, รีเซ็ต (รายวัน/เดือน/ปี/ไม่รีเซ็ต) |

**ตัวอย่างผลลัพธ์:** `JOB-20260608-0001`

**แผน DB (Phase 2+):** ตาราง `job_code_sequences` (org_id, module_key, prefix, date_format, pad_length, last_number, reset_rule)

---

## 11 — Module statuses (สำคัญ)

**วัตถุประสงค์:** ให้แต่ละองค์กรกำหนด **สถานะ (status)** ในแต่ละโมดูลและเมนูหลักได้เอง

| ตัวอย่าง | รายละเอียด |
|----------|------------|
| ดีล | Lead → Qualified → Won (org A) vs สั้นกว่า (org B) |
| ลูกค้า | Prospect / Active / Churned |
| ใบเสนอราคา | Draft / Sent / Accepted |

**แผน DB (Phase 2+):** ตาราง `module_statuses` (org_id, module_key, code, label, sort_order, color, is_default)

---

## ความสัมพันธ์กับ CRM ปัจจุบัน

| Master data | CRM ปัจจุบัน (Phase 1) |
|-------------|------------------------|
| Customer | `companies` (อาจ merge หรือแยก layer ภายหลัง) |
| Contact | `contacts` |
| Module statuses | `pipeline_stages`, deal `status` (hardcoded → configurable) |

**ห้าม** สับสน: master data = **อ้างอิง/ตั้งค่า** · CRM menu = **ใช้งานประจำวัน**

---

## Frontend

```
frontend/app/
├── config/masterDataMenu.ts
├── components/master-data/MasterDataComingSoon.vue
└── pages/app/master-data/
    ├── index.vue
    ├── customer.vue
    ├── contact.vue
    ├── sales-target.vue
    ├── products.vue
    ├── category.vue
    ├── lead-source.vue
    ├── unit.vue
    ├── employee.vue
    ├── sales-team.vue
    ├── module-statuses.vue
    └── job-code.vue
```

**i18n:** `masterData.*` ใน `frontend/i18n/locales/{th,en}.json`

---

## เอกสารที่เกี่ยวข้อง

- [SETUP-MENU.md](./SETUP-MENU.md)
- [06-crm-schema/tables.md](../06-crm-schema/tables.md)

→ [CHANGELOG.md](./CHANGELOG.md)
