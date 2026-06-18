# Category Master — ฟิลด์ UI และ spec สำหรับ SQL

> **Route:** `/app/category` · **Phase 1:** หมวดสินค้า (`module_key = product`)  
> **ถัดไป:** ผูก `products.category_id` → `categories.id`  
> **Code:** `frontend/app/config/masterCategory.ts` · **ฟอร์ม:** `MasterDataCategoryForm.vue`

---

## สถานะ DB ปัจจุบัน (`categories`)

| Column | Type | บันทึกจาก UI | หมายเหตุ |
|--------|------|-------------|----------|
| `module_key` | text NOT NULL | — (ค่า `product`) | ขยายโมดูลอื่น Phase 2+ |
| `category_code` | text NOT NULL | ✅ | รหัสหมวด · unique ต่อ org+module |
| `name` | text NOT NULL | ✅ | ชื่อหมวด |
| `description` | text NULL | ✅ | |
| `parent_id` | uuid NULL | ✅ | FK → categories · ลำดับชั้น |
| `sort_order` | int NOT NULL | ✅ | เรียงในรายการ · default 0 |
| `color` | text NULL | ✅ | สีแสดงใน UI (hex เช่น `#3b82f6`) |
| `status` | text NOT NULL | ✅ | `active` \| `inactive` |
| `notes` | text NULL | ✅ | |
| `image_url` | text NULL | ✅ | รูปหลัก · Storage `org-images/{org_id}/categories/{id}.webp` |

→ รายละเอียดตาราง: [tables.md](./tables.md#categories)

**Unique (active):** `(org_id, module_key, lower(trim(category_code)))`

---

## ลำดับชั้น (`parent_id`)

- หมวดย่อยชี้หมวดแม่ได้ 1 ชั้นต่อการเลือก ( chain ได้หลายระดับ )
- ห้ามวน loop · ห้ามเลือกตัวเองเป็นแม่
- ลบ (soft): ห้ามถ้ามีหมวดลูก active อยู่
- กู้คืน: ถ้าแม่ยังถูกลบ → กู้แม่ก่อน

---

## ความสัมพันธ์กับสินค้า

| ฟิลด์ | รายละเอียด |
|-------|------------|
| `products.category_id` | FK → `categories.id` · ลบหมวด (soft) ห้ามถ้ามีสินค้า active |
| UI สินค้า | `USelectMenu` จาก `useCategories()` · แสดงรูป/ชื่อหมวดในรายการและหน้า view |

---

## Data change log

| action | RPC |
|--------|-----|
| create | `create_category` |
| update | `update_category` |
| delete | `soft_delete_category` |
| restore | `restore_category` |

**Migration:** `20260608120049_categories.sql` · รูปหลัก: `20260608120050_category_image.sql`
