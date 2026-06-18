# Sales Target Master — ฟิลด์ UI และ spec สำหรับ SQL

> Mockup ฟอร์ม `/app/sales-target/new` · **Route:** `/app/sales-target`  
> **Code:** `frontend/app/config/masterSalesTarget.ts` · **ฟอร์ม:** `MasterDataSalesTargetForm.vue`

---

## สถานะ DB ปัจจุบัน (`sales_targets`)

| Column | Type | บันทึกจาก UI | หมายเหตุ |
|--------|------|-------------|----------|
| `profile_id` | uuid NOT NULL | ✅ | FK → `profiles` · ผู้รับเป้า |
| `period_type` | text NOT NULL | ✅ | `month` \| `quarter` \| `year` |
| `period_year` | int NOT NULL | ✅ | เช่น 2026 |
| `period_month` | int NULL | ✅ | 1–12 เมื่อ `period_type = month` |
| `period_quarter` | int NULL | ✅ | 1–4 เมื่อ `period_type = quarter` |
| `target_amount` | numeric(15,2) | ✅ | เป้าหมาย |
| `current_amount` | numeric(15,2) | ✅ | ยอดปัจจุบัน (กรอกมือ · ผูกยอดขาย Phase ถัดไป) |
| `currency` | text NOT NULL | ✅ | default `THB` |
| `notes` | text NULL | ✅ | textarea |

→ รายละเอียดตาราง: [tables.md](./tables.md#sales_targets)

**Unique (active):** `(org_id, profile_id, period_type, period_year, period_month, period_quarter)` — 1 เป้าต่อคนต่อช่วง

---

## ผลจริง / ยอดปัจจุบัน

| รายการ | Phase ปัจจุบัน | ถัดไป |
|--------|----------------|-------|
| **ยอดปัจจุบัน** | เก็บใน `current_amount` — กรอก/แก้ใน UI | ผูกดีล Won / ยอดขายอัตโนมัติ |
| **% ทำได้** | คำนวณ UI: `current_amount / target_amount` | เดิม |
| **กราฟความคืบหน้า** | `AppLineChart` + จำลองวันปิดดีล — ดู [CHARTS.md](../../05-frontend/CHARTS.md) | ดีล Won จริง |

ฟังก์ชัน `sales_target_actual_amount` / `compute_sales_target_actuals` ยังอยู่ใน DB สำหรับ Phase ถัดไป — **frontend ยังไม่เรียก**

---

## Layout ฟอร์ม

| ฟิลด์ | ชนิด UI |
|--------|---------|
| ผู้รับเป้า * | USelectMenu → active users ใน org |
| ประเภทช่วง * | month / quarter / year |
| ปี * | number input |
| เดือน | แสดงเมื่อ month |
| ไตรมาส | แสดงเมื่อ quarter |
| เป้ายอด * | number |
| สกุลเงิน | default THB (Phase 1 ล็อก) |
| หมายเหตุ | textarea |

---

## Validation UI

| ฟิลด์ | กฎ |
|--------|-----|
| `profile_id` | required |
| `period_type` | required |
| `period_year` | required · 2000–2100 |
| `period_month` | required ถ้า month |
| `period_quarter` | required ถ้า quarter |
| `target_amount` | required · ≥ 0 |

---

## หน้ารายการ

- Filter: ปี · ประเภทช่วง · ค้นหาชื่อผู้รับเป้า
- คอลumn: ผู้รับเป้า · ช่วง · เป้า · ผลจริง · % ทำได้ · จัดการ
- แท็บ ใช้งาน / ถูกลบ — owner + admin (`useArchiveTabs`)
- สร้าง/แก้/ลบ — owner + admin (RPC)

**RLS อ่าน:** owner/admin เห็นทั้ง org · employee เห็นเฉพาะเป้าของตัวเอง

---

## Data change log

| action | RPC | entity_type |
|--------|-----|-------------|
| create | `create_sales_target` | `sales_targets` |
| update | `update_sales_target` | `sales_targets` |
| delete (soft) | `soft_delete_sales_target` | `sales_targets` |
| restore | `restore_sales_target` | `sales_targets` |

**Migration:** `20260608120046_sales_targets.sql`

→ [DATA-CHANGE-LOG.md](./DATA-CHANGE-LOG.md)

---

## Checklist

- [x] spec ตรง `masterSalesTarget.ts`
- [x] i18n th + en
- [x] RPC + soft delete + restore
- [x] actual จาก deals won
