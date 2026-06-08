# Setup Menu — System Administration (Scaffold)

> **สถานะ:** System Users พร้อมใช้งาน — หน้าอื่นยัง Coming soon  
> **Phase:** 2+ (บางส่วนอาจเริ่ม late Phase 1)  
> **Config แหล่งเดียว:** `frontend/app/config/setupMenu.ts`

---

## ภาพรวม

เมนู **Setup** ใน sidebar CRM สำหรับผู้ดูแลระบบ (owner / admin) — แยกจากเมนู CRM หลัก (contacts, deals ฯลฯ)

| # | เมนู | Route | สถานะ UI |
|---|------|-------|----------|
| 1 | System Users | `/app/setup/system-users` | ✅ |
| 2 | **Roles (กำหนด Role)** | `/app/setup/roles` | ✅ |
| 3 | Data Management | `/app/setup/data-management` | ⏳ Coming soon |
| 4 | User Activity | `/app/setup/user-activity` | ✅ (อ่าน `data_change_logs`) |
| 5 | Active Sessions | `/app/setup/active-sessions` | ⏳ Coming soon |
| 6 | User Approvals | `/app/setup/user-approvals` | ⏳ Coming soon |
| 7 | Settings | `/app/setup/settings` | ⏳ Coming soon |

**แผน implement:** ไล่ทีละหน้า — แทนที่ `SetupComingSoon` ด้วยหน้าจริงเมื่อพร้อม

---

## 1 — System Users

**วัตถุประสงค์:** จัดการผู้ใช้ในระบบ (ภายใน org)

| ฟิลด์ | คอลัมน์ / แหล่ง |
|------|----------------|
| Full name | `profiles.full_name` |
| Email | `auth.users.email` |
| Username | `profiles.username` (unique ต่อ org) |
| Password | `auth.users` (สร้าง/เปลี่ยนผ่าน RPC) |
| System role | `profiles.role` — owner, admin, sales, readonly |
| Org role | `profiles.org_role_id` → `org_roles` — กำหนดที่ Setup → กำหนด Role |
| Status | `profiles.is_active` |

| ฟีเจอร์ UI |
|------------|
| ✅ รายชื่อ + แก้ไข + เพิ่มผู้ใช้ (owner/admin) |
| Role องค์กรแบบกำหนดเอง → [§ 2 Roles](#2--roles--กำหนด-role) |

**RPC:** `list_org_users`, `admin_create_org_user`, `admin_update_org_user`

---

## 2 — Roles / กำหนด Role

**วัตถุประสงค์:** กำหนด **บทบาทขององค์กร** และสิทธิ์ต่อโมดูล CRM / Master Data — **แยกจาก system role (owner/admin)**

| ส่วน | รายละเอียด |
|------|------------|
| **Setup → ผู้ใช้ในระบบ** | บทบาทระบบ + เลือก Org role |
| **Setup → กำหนด Role** | CRUD role + กำหนดสิทธิ์รายโมดูล |

**Route:** `/app/setup/roles`, `/app/setup/roles/:id`

**DB:** `org_roles` + `profiles.org_role_id` — migration `20260608120006_org_roles.sql`

**RPC:** `list_org_roles`, `get_org_role`, `create_org_role`, `update_org_role`, `delete_org_role`

**เอกสารสิทธิ์:** [ORG-ROLE-PERMISSIONS.md](../06-crm-schema/ORG-ROLE-PERMISSIONS.md)

**Redirect เก่า:** `/app/master-data/roles*` → `/app/setup/roles*`

---

## 3 — Data Management

**วัตถุประสงค์:** นำเข้าข้อมูล CRM จากไฟล์สเปรดชีต

| ฟีเจอร์ที่วางแผน |
|-----------------|
| อัปโหลด `.xlsx`, `.xls`, `.csv` |
| เลือกประเภท: contacts, companies, deals |
| Validate / preview ก่อน import |
| บันทึกประวัติการนำเข้า |

**หมายเหตุ:** import = bulk insert/update ใน Tenant data (Phase 1: same Supabase + `org_id`)

---

## 4 — User Activity

**วัตถุประสงค์:** audit trail กิจกรรมผู้ใช้

| ฟีเจอร์ที่วางแผน |
|-----------------|
| บันทึก create / update / delete |
| กรองตาม user, ช่วงเวลา, entity |
| รายละเอียดกิจกรรม |
| ส่งออกรายงาน |

**DB ที่เกี่ยวข้อง:** `data_change_logs` — ดู [DATA-CHANGE-LOG.md](../06-crm-schema/DATA-CHANGE-LOG.md)

---

## 5 — Active Sessions

**วัตถุประสงค์:** ดู session ที่ login อยู่และจุดเข้าใช้งานล่าสุด

| ฟีเจอร์ที่วางแผน |
|-----------------|
| รายการ session active |
| IP, device, browser, เวลา login ล่าสุด |
| บังคับ logout session อื่น |

**แหล่งข้อมูล:** Supabase Auth sessions / custom session log (ออกแบบ Phase 2+)

---

## 6 — User Approvals

**วัตถุประสงค์:** อนุมัติผู้สมัครใหม่ก่อนเข้า CRM

| ฟีเจอร์ที่วางแผน |
|-----------------|
| คิวรออนุมัติจาก register |
| อนุมัติ / ปฏิเสธ + เหตุผล |
| แจ้งเตือนเมื่ออนุมัติแล้ว |
| เปิด-ปิดโหมดต้อง approve |

**เชื่อมกับ:** [register-provision.md](../09-flows/register-provision.md) (Phase 4+), signup flow ปัจจุบัน

---

## 7 — Settings

**วัตถุประสงค์:** ตั้งค่าองค์กรและระบบ auth / notification

### 6.1 Company profile

- ชื่อ org, logo, timezone, สกุลเงิน  
- อ่าน/เขียน `organizations.settings` (jsonb)

### 6.2 Notifications

- เปิด-ปิดการแจ้งเตือนแต่ละประเภท (deal assigned, approval, import done ฯลฯ)

### 6.3 Email service

- ตั้งค่า SMTP (host, port, user, password, from address)  
- ใช้ส่ง transactional email แทน Supabase default (production)

### 6.4 Auth providers

| Provider | สถานะแผน |
|----------|-----------|
| Username & password | ✅ มีอยู่ (Supabase Email) |
| Google | ⏳ OAuth |
| Microsoft 365 | ⏳ OAuth |
| Azure AD | ⏳ OIDC / SAML |

---

## โครงสร้าง Frontend

```
frontend/app/
├── config/setupMenu.ts          ← รายการเมนู (แก้ที่เดียว)
├── components/setup/
│   └── SetupComingSoon.vue      ← placeholder ร่วม
└── pages/app/setup/
    ├── index.vue                ← hub
    ├── system-users.vue
    ├── data-management.vue
    ├── user-activity.vue
    ├── active-sessions.vue
    ├── user-approvals.vue
    └── settings.vue
```

**i18n:** `setup.*` ใน `frontend/i18n/locales/{th,en}.json`

---

## สิทธิ์การเข้าถึง (แผน)

| Role | Setup menu |
|------|------------|
| owner | ✅ ทั้งหมด |
| admin | ✅ ส่วนใหญ่ (ยกเว้น billing/delete org — Phase 2+) |
| sales | ❌ ซ่อนเมนู |
| readonly | ❌ ซ่อนเมนู |

**Phase 1 scaffold:** แสดงเมนูให้ทุก role ที่ login ได้ — จำกัดสิทธิ์เมื่อ implement จริง

---

## เอกสารที่เกี่ยวข้อง

- [permissions.md](../06-crm-schema/permissions.md)
- [03-auth/README.md](../03-auth/README.md)
- [PHASE-1-CHECKLIST.md](../07-phases/PHASE-1-CHECKLIST.md)

## ดูการเปลี่ยนแปลงล่าสุด

→ [CHANGELOG.md](./CHANGELOG.md)
