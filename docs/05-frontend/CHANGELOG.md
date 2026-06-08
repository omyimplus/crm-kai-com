# Changelog — Frontend

→ ออกแบบปัจจุบัน: [README.md](./README.md)

---

## ประวัติ

### 2026-06-08 — IMAGE-UPLOAD.md + shared image upload stack

- **ทำอะไร:** เอกสารและชุดกลาง `useImageUpload` / `AppImageUpload` — avatar + company logo
- **ไฟล์ที่กระทบ:** `IMAGE-UPLOAD.md`, `SHARED-COMPONENTS.md`, `README.md`

### 2026-06-08 — AppDataTable header rounded corners

- **ทำอะไร:** หัวตารางมนซ้าย–ขวา–บน ผ่าน `.app-data-table` ใน `main.css`
- **ไฟล์ที่กระทบ:** `AppDataTable.vue`, `frontend/app/assets/css/main.css`, `SHARED-COMPONENTS.md`

### 2026-06-08 — add SHARED-COMPONENTS.md

- **ทำอะไร:** เอกสาร component ใช้ร่วม — AppDataTable, AppPagination, AppDialog, form UI class, avatar
- **ไฟล์ที่กระทบ:** `SHARED-COMPONENTS.md`, `README.md`

### 2026-06-08 — add Master Data → Roles menu (กำหนด Role)

- **ทำอะไร:** เมนูกำหนด role ใน Master Data (นอก Setup) + route `/app/master-data/roles` + เอกสาร
- **ไฟล์ที่กระทบ:** `masterDataMenu.ts`, `pages/app/master-data/roles.vue`, `i18n`, `MASTER-DATA-MENU.md`

### 2026-06-08 — implement Setup → System Users page

- **ทำอะไร:** หน้าผู้ใช้ในระบบ — ตารางรายชื่อ, แก้ไขชื่อ/บทบาท/สถานะ (owner/admin)
- **ไฟล์ที่กระทบ:** `system-users.vue`, `SystemUserEditModal.vue`, `useSystemUsers.ts`, migration `20260608120003_*`, `i18n`, `setupMenu.ts`

### 2026-06-08 — replace sidebar with App menu (12 pages Coming soon)

- **ทำอะไร:** ลบ Setup / Master Data / CRM เดิมออกจาก sidebar — ใช้เมนู Menu 12 รายการ (dashboard → service) พร้อม routes และเอกสาร APP-MENU.md
- **ไฟล์ที่กระทบ:** `appMenu.ts`, `AppSidebar.vue`, `AppMenuComingSoon.vue`, `pages/app/{tasks,leads,...}.vue`, `i18n/locales/{th,en}.json`, `APP-MENU.md`, `README.md`, `IRON-RULES.md`
- **หมายเหตุ:** routes เดิม (`/app/setup/**`, `/app/master-data/**`, contacts/companies/deals) ยังอยู่ใน repo — legacy

### 2026-06-08 — create Master data menu scaffold (10 pages Coming soon)

- **ทำอะไร:** เมนูข้อมูลหลักใน sidebar + routes `/app/master-data/**` + เอกสาร MASTER-DATA-MENU.md (รวม module statuses)
- **ไฟล์ที่กระทบ:** `masterDataMenu.ts`, `pages/app/master-data/*`, `MasterDataComingSoon.vue`, `AppSidebar.vue`, `i18n/locales/{th,en}.json`, `MASTER-DATA-MENU.md`
- **Phase:** 2+ (scaffold)

### 2026-06-08 — create Setup menu scaffold (6 pages Coming soon)

- **ทำอะไร:** เมนู Setup ใน sidebar + routes `/app/setup/**` + component `SetupComingSoon` + เอกสาร SETUP-MENU.md
- **ไฟล์ที่กระทบ:** `frontend/app/config/setupMenu.ts`, `frontend/app/pages/app/setup/*`, `frontend/app/components/setup/SetupComingSoon.vue`, `frontend/app/layouts/app.vue`, `frontend/i18n/locales/{th,en}.json`, `SETUP-MENU.md`, `README.md`
- **เหตุผล:** เตรียมโครง admin ไว้ก่อน — implement ทีละหน้า
- **Phase:** 2+ (scaffold ใน Phase 1)

### 2026-06-08 — create BRAND-ASSETS.md (logo paths)

- **ทำอะไร:** บันทึก logo `public/images/logo/logo-kai-com-crm.webp` + `logo-kai-com-crm-icon.webp`
- **ไฟล์ที่กระทบ:** `BRAND-ASSETS.md`, `README.md`, `IRON-RULES.md`, `frontend/README.md`
- **Phase:** 1

### 2026-06-08 — update เอกสาร TYPOGRAPHY.md

- **ทำอะไร:** ลิงก์ฟอนต์ใน README
- **ไฟล์ที่กระทบ:** `README.md`
- **Phase:** 1

### 2026-06-08 — update เอกสาร i18n 2 ภาษา

- **ทำอะไร:** เพิ่ม i18n ใน README + ลิงก์ docs/12-i18n
- **ไฟล์ที่กระทบ:** `README.md`
- **Phase:** 1

### 2026-06-08 — create เอกสาร frontend

- **ทำอะไร:** สร้าง README routes + โครงโฟลเดอร์ Nuxt
- **ไฟล์ที่กระทบ:** `README.md`
- **Phase:** 1 (ยังไม่ scaffold frontend/)
