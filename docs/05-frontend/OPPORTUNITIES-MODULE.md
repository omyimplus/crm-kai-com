# Opportunities Module — Phase 2 Design Spec

> **Phase:** 2 — CRM Menu (ถัดจาก Lead ✅)  
> **Route:** `/app/opportunities` · สร้าง `/app/opportunities/from-lead/:leadId` · ดู/แก้ `/app/opportunities/:id`  
> **สถานะ:** ✅ implement v1 — migration `20260608120081_opportunities_module.sql`  
> **อ้างอิง UI เก่า:** รายการโอกาส · สรุป Pipeline/Won/Open · ฟอร์ม 3 คอลัมน์ + ที่อยู่

---

## เป้าหมาย

หน้า **Opportunity** สำหรับติดตามดีลที่ผ่านการคัดกรองจากลีดแล้ว — มูลค่า · stage · ทีมขาย · ข้อมูลโปรเจกต์

Flow: **Lead → Opportunity → Quotation → …** (ดู [APP-MENU.md](./APP-MENU.md))

---

## ข้อจำกัด / หลักการ

| หัวข้อ | กำหนด |
|--------|--------|
| Phase | 2 |
| **สร้างได้จากลีดเท่านั้น** | ไม่มี `/app/opportunities/new` แบบ standalone · ปุ่ม Convert บนหน้าดูลีด → `/app/opportunities/from-lead/:leadId` |
| Stage workflow | **`pipeline_stages`** ของ default pipeline (เช่น Lead → Qualified → … → Won/Lost) — มี `probability` ต่อ stage |
| เลขที่โอกาส | **`job_code_sequences`** — module `opportunity` · prefix `OPP` · read-only หลังสร้าง |
| สิทธิ์ | `app.opportunity` — view / create / edit / delete |
| DB | RLS + `org_id` + `data_change_logs` ทุก CRUD |
| i18n | th + en — key `appMenu.opportunity.*` / `opportunities.*` |
| ฟอร์ม | **หน้าเต็ม** (pattern Lead) — sidebar Actions |

**1 ลีด → 1 โอกาส** (unique `lead_id` ขณะ active) — หลัง convert ลีดเปลี่ยนสถานะเป็น `CONVERTED`

---

## หน้ารายการ (`/app/opportunities`)

| การ์ดสรุป | นิยาม v1 |
|-----------|----------|
| **มูลค่า Pipeline** | ผลรวม `estimated_value` ของ opp `status = open` ในชุดที่ตรง filter |
| **ชนะช่วงนี้** | ผลรวม opp `status = won` ที่ `closed_at` อยู่ในช่วงวันที่ filter (default เดือนปัจจุบัน) |
| **โอกาสเปิด** | จำนวน opp `status = open` ในชุดที่ตรง filter |

**ไม่มีปุ่ม + New Opportunity** — สร้างจากลีดเท่านั้น

### ตาราง

| คอลัมน์ | ฟิลด์ |
|--------|--------|
| ชื่อ | `title` + `opportunity_code` |
| ลูกค้า | `company_name` |
| มูลค่า | `estimated_value` |
| วันปิดการขาย | `close_date` |
| ผู้รับผิดชอบ | `owner_name` |
| Stage | badge จาก `pipeline_stages` |
| Actions | ดู · แก้ไข · ลบ |

### Filter

ค้นหา · stage · ช่วงวันที่ (created / close_date) · table/grid toggle

---

## ฟอร์ม (จากลีด / แก้ไข)

### Opportunity

| ฟิลด์ | คีย์ DB | หมายเหตุ |
|--------|---------|----------|
| Opportunity Name* | `title` | จากลีด · **แก้ไม่ได้** |
| Customer* | `company_id` | จากลีด · **แก้ไม่ได้** |
| Stage* | `stage_id` | default = stage แรกที่ไม่ won/lost · **แก้ได้** |
| Probability (%) | `probability` | **อ่านอย่างเดียว** — sync จาก stage |
| Estimated Value | `estimated_value` | **ผลรวมมูลค่าโปรเจกต์** · sync `leads.lead_value` ตอนสร้าง/บันทึก |
| Close Date | `close_date` | **แก้ได้** |
| Description | `description` | จากลีด · **แก้ไม่ได้** |

### Projects (`opportunity_projects`) — หลายโปรเจกต์ต่อ 1 opp

| ฟิลด์ | คีย์ DB | หมายเหตุ |
|--------|---------|----------|
| Project Name | `project_name` | **แก้ได้** · เพิ่มได้หลายรายการ |
| Project Type | `project_type` | dropdown enum |
| Project Sub-Type | `project_sub_type` | dropdown enum |
| Products Group | `products_group` | dropdown จาก `categories` (module `product`) |
| Estimated Value | `estimated_value` | มูลค่าต่อโปรเจกต์ |
| Project Costs | `project_costs` | ต้นทุนต่อโปรเจกต์ |

**UI:** ส่วนโปรเจกต์อยู่ด้านล่างฟอร์ม · ปุ่ม「เพิ่มโปรเจกต์」· แสดงยอดรวม · `opportunities.estimated_value` = SUM โปรเจกต์

### People

| ฟิลด์ | คีย์ DB | หมายเหตุ |
|--------|---------|----------|
| Opportunities Owner* | `owner_id` | จากลีด · **แก้ไม่ได้** |
| Sales Owner | `sales_owner_id` | จากลีด · **แก้ไม่ได้** |
| Sales Designer | `sales_designer_id` | **แก้ได้** |
| Sales Team | `sales_team_id` | **แก้ได้** |

### Address (v1)

| ฟิลด์ | v1 |
|--------|-----|
| Bill to | `address_bill_to` | dropdown จาก `company_bill_addresses` · ถ้ายังไม่มี → ปุ่ม「เพิ่ม」เปิด modal บันทึกลงลูกค้าแล้วเลือกให้อัตโนมัติ |
| Ship to | v1.1 — หลังบันทึก opp แรก (pattern ระบบเก่า) |

---

## RPC

| RPC | หมายเหตุ |
|-----|----------|
| `ensure_opportunity_module_defaults` | lazy seed job code `opportunity` |
| `list_opportunities` | filter stage optional |
| `create_opportunity_from_lead` | **ทางสร้างเดียว** · convert ลีด → CONVERTED |
| `update_opportunity` | |
| `soft_delete_opportunity` | |
| `get_opportunity_by_lead` | ตรวจว่าลีด convert แล้วหรือยัง |
| `list_opportunity_projects` | รายการโปรเจกต์ของ opp |
| `sync_opportunity_projects` | replace โปรเจกต์ + คำนวณ `estimated_value` (internal) |

---

## Scope v1 vs v1.1

| รายการ | v1 | v1.1+ |
|--------|----|-------|
| List + summary + filter | ✅ | |
| Create from lead only | ✅ | |
| Edit หน้าเต็ม | ✅ | |
| Bill to address | ✅ | |
| Ship to multi-address | | ✅ |
| Stage history table | | พิจารณา |
| Urgency smart filter | | ✅ |
| Link จาก Tasks | | ✅ เปิด dropdown |
