# Unit Master — ฟิลด์ UI และ spec สำหรับ SQL

> **Route:** `/app/unit` · **Phase 1:** หน่วยนับสินค้า  
> **Relation:** ผูก `products.unit_id` → `units.id`  
> **Code:** `frontend/app/config/masterUnit.ts` · **ฟอร์ม:** `MasterDataUnitForm.vue`

---

## สถานะ DB ปัจจุบัน (`units`)

| Column | Type | บันทึกจาก UI | หมายเหตุ |
|--------|------|-------------|----------|
| `unit_code` | text NOT NULL | ✅ | รหัสหน่วย · unique ต่อ org |
| `name` | text NOT NULL | ✅ | ชื่อหน่วย (เช่น ชิ้น, กล่อง) |
| `description` | text NULL | ✅ | |
| `sort_order` | int NOT NULL | ✅ | เรียงในรายการ · default 0 |
| `status` | text NOT NULL | ✅ | `active` \| `inactive` |
| `notes` | text NULL | ✅ | |

→ รายละเอียดตาราง: [tables.md](./tables.md#units)

**Unique (active):** `(org_id, lower(trim(unit_code)))`

---

## ความสัมพันธ์กับสินค้า

| ฟิลด์ | รายละเอียด |
|-------|------------|
| `products.unit_id` | FK → `units.id` · ลบหน่วย (soft) ห้ามถ้ามีสินค้า active |
| UI สินค้า | `USelectMenu` จาก `useUnits()` · แสดงชื่อหน่วย/ลิงก์ใน list และ view |

---

## Data change log

| action | RPC |
|--------|-----|
| create | `create_unit` |
| update | `update_unit` |
| delete | `soft_delete_unit` |
| restore | `restore_unit` |

**Migration:** `20260608120053_units.sql` · FK สินค้า: `20260608120054_products_unit_id.sql`
