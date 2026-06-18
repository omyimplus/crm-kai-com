# Tasks Module — Phase 2 Design Spec

> **Phase:** 2 — CRM Menu โมดูลแรก  
> **Route:** `/app/tasks`  
> **สถานะ:** 📋 ออกแบบล็อกแล้ว — ยังไม่ implement  
> **อ้างอิง UI เก่า:** รายการงาน · Create Task modal · สรุปตามสถานะ · filter ประเภท · ปฏิทิน

---

## เป้าหมาย

หน้า **Tasks** สำหรับติดตามงานข้ามโมดูล (โทร, นัด, follow-up, งานภายใน) — ทีมขายใช้ประจำวัน  
เป็นจุดเริ่มของ **CRM Menu** ใน Phase 2 (แทน `AppMenuComingSoon`)

---

## ข้อจำกัด / หลักการ

| หัวข้อ | กำหนด |
|--------|--------|
| Phase | 2 — user ยืนยันรวม CRM Menu ใน Phase 2 |
| สถานะ workflow | จาก **`module_statuses`** (`module_key = task`) — ไม่ hardcode enum ใน UI |
| เลขที่งาน | **`job_code_sequences`** — running อัตโนมัติ ไม่ให้ผู้ใช้กรอกเอง |
| ประเภทงาน | enum — **Task / Call / Email / Meeting / Visit** (แถบเลือกด้านบน modal) |
| Priority | enum — High / Medium / Low (v1 คงที่ ไม่ seed Master Data) |
| สิทธิ์ | `app.tasks` — view / create / edit (มีใน org role templates แล้ว) |
| DB | RLS + `org_id` + `data_change_logs` ทุก CRUD |
| i18n | th + en เสมอ — key `appMenu.tasks.*` / `tasks.*` |

**ไม่ใช้ตาราง `activities` เป็นหลัก** — `activities` เป็น timeline ผูก deal/contact/company; หน้า Tasks ต้องการ customer, contact, assigned, priority, สรุปตามสถานะ → ใช้ตาราง **`tasks`** ใหม่

---

## การตัดสินใจที่ล็อกแล้ว

### 1. เลขที่งาน (Job code)

- **Running อัตโนมัติ** ตาม Master Data → Job code → module `task`
- ตัวอย่าง: `TSK-20260608-0001`
- ฟิลด์ `task_code` **read-only** ในฟอร์มและตาราง — admin ปรับรูปแบบที่ `/app/job-code?module=task` เท่านั้น
- ต้องมี RPC **`generate_job_code(p_module_key)`** (ยังไม่มีใน codebase — ทำพร้อม Tasks)
- Lazy seed default sequence: prefix `TSK`, pad 4, separator `-`, reset `never`

### 2. ปฏิทิน — **ไม่ใช่แท็บสถานะ**

ระบบเก่าวาง Calendar เป็นแท็บคู่ Open / In Progress / … — **เราไม่ทำแบบนั้น** เพราะ:

- แท็บใน layout มาตรฐานของโปรเจกต์ = **filter ข้อมูลชนิดเดียวกัน** (สถานะ, archive active/deleted)
- ปฏิทิน = **มุมมอง (view) คนละประเภท** ไม่ใช่สถานะ workflow
- ใส่เป็นแท็บจะสับสนกับ pattern ที่ใช้ใน Customer, Module statuses, ฯลฯ

**แนวทางที่ใช้ (สอดคล้อง table/grid toggle ใน Setup Roles, Company profiles):**

```
┌──────────────────────────────────────────────────────────────┐
│  Tasks                                    [ + New Task ]     │
│  Summary cards: Open | Completed | In Progress | Cancelled   │
├──────────────────────────────────────────────────────────────┤
│  [ค้นหา...]  [All Types ▼]  [Filter]     [ List ] [ 📅 ]   │  ← view switcher
├──────────────────────────────────────────────────────────────┤
│  LIST VIEW:                                                  │
│    Tabs: Open | In Progress | Completed | Cancelled          │  ← เฉพาะ list
│    ตาราง / grid                                              │
├──────────────────────────────────────────────────────────────┤
│  CALENDAR VIEW:                                              │
│    Month calendar (lib) — ไม่มีแท็บสถานะ                     │
│    แสดงงานจาก start_at · คลิก event → เปิดฟอร์มแก้ไข         │
│    Filter ประเภท/ค้นหา ใช้ toolbar เดิมได้                   │
└──────────────────────────────────────────────────────────────┘
```

| องค์ประกอบ | List view | Calendar view |
|-----------|-----------|---------------|
| แท็บสถานะ | ✅ Open / In Progress / Completed / Cancelled | ❌ ไม่แสดง |
| ตาราง / grid | ✅ | ❌ |
| ปฏิทิน | ❌ | ✅ month view |
| Summary cards | ✅ | ✅ (optional — นับรวมทั้ง org) |
| Search / type filter | ✅ | ✅ |

**v1 ปฏิทิน:** month view จาก lib (เช่น `@fullcalendar/vue3` หรือ `v-calendar`) — ยังไม่ drag-reschedule / สร้างจากปฏิทิน (v1.1)

**State:** `viewMode: 'list' | 'calendar'` — เก็บใน query `?view=calendar` ได้เพื่อ deep link

### 3. Seed Master Data — lazy per module

**ฟังก์ชัน:** `seed_org_module_defaults(p_org_id, p_module_key)` — idempotent (`ON CONFLICT DO NOTHING`)

**เรียกเมื่อ:**

1. ครั้งแรกที่ RPC Tasks ทำงาน (`list_tasks` / `create_task`) — org ใหม่ได้ default อัตโนมัติ
2. Migration backfill — org ที่มีอยู่แล้วตอน deploy Tasks

**ไม่ seed ทุกโมดูลตอนสร้าง org** — seed เฉพาะโมดูลที่ ship แล้ว (เริ่มที่ `task`)

**Default สำหรับ `module_key = task`:**

| ประเภท | รายการ |
|--------|--------|
| Module statuses | `OPEN` (is_default), `IN_PROGRESS`, `COMPLETED`, `CANCELLED` |
| Job code sequence | prefix `TSK`, รูปแบบมาตรฐาน |
| ไม่ seed | task type, priority |

**ช่องว่างที่ต้องแก้ก่อน implement:** เพิ่ม `task` ใน CHECK ของ `module_statuses` + `MODULE_STATUS_MODULE_KEYS` (ตอนนี้ job code มี `task` แล้ว แต่ module status ยังไม่มี)

### 4. Create / Edit Task modal (ระบบเก่า)

Modal **Create Task** ระบบเก่า — ใช้เป็น reference layout และฟิลด์ (ไม่ copy pixel-perfect)

```
┌──────────────── Create Task ────────────────────────────────┐
│  [ Task ] [ Call ] [ Email ] [ Meeting ] [ Visit ]          │  ← activity type (segment)
├──────────────────┬──────────────────┬─────────────────────────┤
│ Task Info        │ People & Related │ Details                 │
│ · Subject *      │ · Assigned By    │ · Description           │
│ · Status         │ · Assigned To    │ · Products Group (multi)│
│ · Priority       │ · Customer       │                         │
│ · Start Date     │ · Contact        │                         │
│ · End Date       │ · Opportunity    │                         │
│                  │ · Lead           │                         │
│                  │ · Project        │                         │
├──────────────────┴──────────────────┴─────────────────────────┤
│                              [ Cancel ]  [ Create Task ]      │
└───────────────────────────────────────────────────────────────┘
```

**สังเกตจากระบบเก่า**

| หัวข้อ | ระบบเก่า | ระบบใหม่ |
|--------|----------|----------|
| เลขที่งาน | ไม่มีในฟอร์ม create | **generate ตอน save** — แสดง read-only หลังสร้าง / ใน edit |
| Activity type | 5 แบบ (Task, Call, Email, Meeting, Visit) | ใช้ครบ 5 แบบ — แถบ segment ด้านบน modal |
| Status | dropdown (Open) | จาก `module_statuses` · default = `OPEN` |
| Priority | dropdown + สี (Medium) | enum high / medium / low |
| วันที่ | Start Date + End Date | `start_at` + `end_at` (timestamptz) — ปฏิทินใช้ `start_at` เป็นหลัก |
| Assigned By | มี (creator / ผู้มอบหมาย) | `assigned_by` → profiles · default = user ปัจจุบัน |
| Assigned To | มี | `assigned_to` → profiles |
| Customer / Contact | dropdown | FK → `companies` / `contacts` (Master Data Phase 1) |
| Opportunity / Lead / Project | dropdown (None) | **v1:** คอลัมน์ nullable พร้อมไว้ · **UI เปิดเมื่อ ship โมดูลนั้น** |
| Products Group | chip multi-select (HVAC, Electrical, …) | **v1.1** — junction `task_categories` จาก Master Category (product) หรือ master ใหม่ถ้าต้องแยก |
| Layout | 3 คอลัมน์ | ใช้ `AppDialog` + section themes (pattern Master Data / Setup modals) |

**Footer:** Cancel + primary **Create Task** / **Save** — ใช้ `AppDialogFooter`

**Create vs Edit**

| โหมด | พฤติกรรม |
|------|----------|
| Create | ไม่แสดง `task_code` · type default Task · status default OPEN · assigned_by = ผู้ login |
| Edit | แสดง `task_code` read-only · โหลดค่าทั้งหมด · soft delete จาก action menu |

---

## ฟิลด์หลัก (Tasks v1)

อ้างอิง Create Task ระบบเก่า + master ที่มี Phase 1

| ฟิลด์ | แหล่ง / หมายเหตุ |
|--------|------------------|
| `task_code` | auto จาก `generate_job_code('task')` — ไม่แสดงตอน create |
| `subject` | required — placeholder "Task subject" |
| `task_type` | `task` \| `call` \| `email` \| `meeting` \| `visit` |
| `module_status_id` | FK → `module_statuses` (module `task`) · default OPEN |
| `priority` | `high` \| `medium` \| `low` · default medium |
| `start_at` | วันเริ่ม · date picker |
| `end_at` | วันสิ้นสุด · date picker |
| `assigned_by` | FK → profiles · ผู้มอบหมาย |
| `assigned_to` | FK → profiles · ผู้รับผิดชอบ |
| `company_id` | FK → companies (Customer Related) |
| `contact_id` | FK → contacts |
| `opportunity_id` | nullable — UI เมื่อมีโมดูล Opportunity |
| `lead_id` | nullable — UI เมื่อมีโมดูล Lead |
| `project_id` | nullable — UI เมื่อมีโมดูล Project |
| `description` | optional textarea |
| `org_id`, `created_by`, audit, `deleted_at` | มาตรฐาน CRM |

**ตารางเสริม (v1.1):** `task_categories` (task_id, category_id) — Products Group แบบ multi-select

---

## Scope v1 vs v1.1

| รายการ | v1 | v1.1+ |
|--------|----|-------|
| Create/Edit modal (3 คอลัมน์) | ✅ | |
| Activity type 5 แบบ | ✅ | |
| Customer + Contact + Assigned By/To | ✅ | |
| Opportunity / Lead / Project links | คอลัมน์ DB · UI ซ่อน | ✅ เปิด UI |
| Products Group multi-select | | ✅ |
| CRUD + list + summary cards | ✅ | |
| Status tabs (list view) | ✅ | |
| Search + filter type | ✅ | |
| List / grid toggle | ✅ (ถ้ามี grid) | |
| Calendar view (แยกจาก tabs) | ✅ | |
| Drag บนปฏิทิน | | ✅ |
| สร้างงานจากปฏิทิน | | ✅ |
| เชื่อม timeline `activities` | | พิจารณาภายหลัง |

---

## Backend (แผน)

```
supabase/migrations/
  YYYYMMDD_tasks_table.sql
    - tasks table + indexes
    - module_statuses CHECK + task
    - seed_org_module_defaults()
    - generate_job_code()
    - list_tasks / create_task / update_task / soft_delete_task
    - RLS + data_change_logs
    - backfill seed สำหรับ org ที่มีอยู่
```

```
frontend/app/
  config/masterTasks.ts          ← enums task_type, priority
  composables/useTasks.ts
  components/tasks/              ← form modal, calendar, summary cards
  pages/app/tasks.vue            ← แทน AppMenuComingSoon
```

---

## ความสัมพันธ์กับ Master Data

| Master | การใช้ใน Tasks |
|--------|----------------|
| Module statuses (`task`) | dropdown สถานะ · แท็บ list · badge |
| Job code (`task`) | generate `task_code` ตอน create |
| Customer / Contact | FK ในฟอร์ม |
| System users | assigned_by · assigned_to |

---

## เอกสารที่เกี่ยวข้อง

- [APP-MENU.md](./APP-MENU.md) — CRM navigation
- [MASTER-DATA-MENU.md](./MASTER-DATA-MENU.md) — module statuses · job code
- [07-phases/README.md](../07-phases/README.md) — Phase 2
- [06-crm-schema/tables.md](../06-crm-schema/tables.md) — อัปเดตเมื่อมี migration

→ [CHANGELOG.md](./CHANGELOG.md)
