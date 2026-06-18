# Master Data Menu — Phase 1 Complete

> **สถานะ:** Customer · Contact · Sales target · Products · Category · Unit · Lead source · Partner · Sales team · **Module statuses** · **Job code** ✅  
> **Config:** `frontend/app/config/masterDataMenu.ts` — ทุกรายการ `ready: true`

---

## ภาพรวม

เมนู **ข้อมูลหลัก (Master Data)** อยู่ใน sidebar ถัดจาก **Menu** — เก็บข้อมูลอ้างอิงขององค์กร (ดู [APP-MENU.md](./APP-MENU.md))

| # | เมนู | Route | สถานะ |
|---|------|-------|--------|
| 1 | Customer | `/app/customer` | ✅ |
| 2 | Contact | `/app/contact` | ✅ |
| 3 | Sales target | `/app/sales-target` | ✅ |
| 4 | Products | `/app/product` | ✅ |
| 5 | Category | `/app/category` | ✅ |
| 6 | Unit | `/app/unit` | ✅ |
| 7 | Lead source | `/app/lead-source` | ✅ |
| 8 | Partner | `/app/partner` | ✅ |
| 9 | Sales team | `/app/sales-team` | ✅ |
| 10 | Module statuses | `/app/module-status` | ✅ |
| 11 | Job code (รหัสงาน) | `/app/job-code` | ✅ |

> **ผู้ใช้ในองค์กร** ใช้ **Setup → ผู้ใช้งานในระบบ** (`/app/setup/system-users`) — ไม่มี master menu พนักงาน/ตำแหน่งพนักงาน

> **กำหนด Role** ย้ายไป **Setup** → `/app/setup/roles` — ดู [SETUP-MENU.md § Roles](./SETUP-MENU.md)

---

## 11 — Module statuses ✅

**Route:** `/app/module-status` (โมดูลซ้าย + รายการขวาในหน้าเดียว · `?module=lead`) · redirect จาก `/app/module-status/module/:moduleKey` · **Migration:** `20260608120065_module_statuses.sql`

**UX:** แท็บโมดูลด้านซ้าย · รายการสถานะด้านขวา (ไม่เปิดหน้าใหม่) · เพิ่ม/ดู/แก้ไขสถานะทีละรายการ · `loadSelectOptions(moduleKey)` สำหรับ dropdown ใน CRM ภายหลัง

**วัตถุประสงค์:** ให้แต่ละองค์กรกำหนด **ตัวเลือกสถานะ** ต่อโมดูล (ลีด ลูกค้า ใบเสนอราคา ฯลฯ) เพื่อเลือกใช้ใน workflow ภายหลัง

| ฟิลด์ | หมายเหตุ |
|--------|----------|
| module_key | โมดูลที่ใช้สถานะนี้ |
| status_code | รหัสสถานะ (UPPER_SNAKE_CASE — เช่น `PENDING`, `IN_TRANSIT`) |
| name | ชื่อแสดงผล |
| color | สี badge (hex) |
| sort_order | ลำดับใน dropdown |
| is_default | ค่าเริ่มต้นต่อโมดูล (มีได้ 1) |
| status | active/inactive — เปิด/ปิดตัวเลือก |

---

## 12 — Job code / รหัสงาน ✅

**Route:** `/app/job-code` (โมดูลซ้าย + ตั้งค่าขวาในหน้าเดียว · `?module=lead`) · redirect จาก `/app/job-code/module/:moduleKey` · **Migration:** `20260608120067_job_code_sequences.sql`

**UX:** แท็บโมดูลด้านซ้าย · ฟอร์มตั้งค่าด้านขวา (ไม่เปิดหน้าใหม่) · กำหนดคำนำหน้า · ส่วนวันที่ · เลข running · preview สด

| ฟิลด์ | หมายเหตุ |
|--------|----------|
| prefix | คำนำหน้า UPPERCASE เช่น `JOB`, `QT` |
| date_* | เปิด/ปิด ปี เดือน วัน · `date_part_order` |
| date_style | compact / dash / iso |
| segment_order | ลำดับ prefix · date · number |
| segment_separator | ตัวคั่น เช่น `-` |
| pad_length | ความยาวเลข running |
| start_number | เลขเริ่มต้น |
| reset_rule | never / daily / monthly / yearly |
| last_number | ตัวนับปัจจุบัน (ใช้ตอน generate จริงใน CRM ภายหลัง) |

**ตัวอย่าง:** `JOB-20260608-0001`

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
├── composables/use{Companies,Contacts,SalesTargets,Products,...}.ts
├── components/master-data/MasterData*.vue
├── pages/app/
│   ├── customer/          → /app/customer
│   ├── contact/           → /app/contact
│   ├── sales-target/
│   ├── product/
│   ├── category/
│   ├── unit/
│   ├── lead-source/
│   ├── partner/
│   ├── sales-team/
│   ├── module-status/     → split-pane (?module=)
│   ├── job-code/          → split-pane (?module=)
│   └── master-data/       → legacy redirects → route ใหม่
```

**Sidebar:** section **ข้อมูลหลัก** เปิดค่าเริ่มต้น · **เมนู CRM** และ **ตั้งค่าระบบ** ปิด (เปิดเมื่อเข้า route นั้น)

**i18n:** `masterData.*` ใน `frontend/i18n/locales/{th,en}.json`

---

## เอกสารที่เกี่ยวข้อง

- [SETUP-MENU.md](./SETUP-MENU.md)
- [06-crm-schema/tables.md](../06-crm-schema/tables.md)

→ [CHANGELOG.md](./CHANGELOG.md)
