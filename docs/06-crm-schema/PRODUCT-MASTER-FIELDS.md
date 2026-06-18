# Product Master — ฟิลด์ UI และ spec สำหรับ SQL

> **Route:** `/app/product` · **Relation:** หมวด → FK `categories` · หน่วย → FK `units`  
> **Code:** `frontend/app/config/masterProduct.ts` · **ฟอร์ม:** `MasterDataProductForm.vue`

---

## สถานะ DB ปัจจุบัน (`products`)

| Column | Type | บันทึกจาก UI | หมายเหตุ |
|--------|------|-------------|----------|
| `product_code` | text NOT NULL | ✅ | รหัสสินค้า · unique ต่อ org (active) |
| `name` | text NOT NULL | ✅ | ชื่อสินค้า/บริการ |
| `description` | text NULL | ✅ | รายละเอียด |
| `category_id` | uuid NULL | ✅ | FK → `categories.id` · ON DELETE SET NULL |
| `unit_id` | uuid NULL | ✅ | FK → `units.id` · ON DELETE SET NULL |
| `list_price` | numeric(15,2) | ✅ | ราคาขาย |
| `cost_price` | numeric(15,2) NULL | ✅ | ต้นทุน (optional) |
| `currency` | text NOT NULL | ✅ | `THB` \| `USD` · default THB |
| `barcode` | text NULL | ✅ | บาร์โค้ด |
| `status` | text NOT NULL | ✅ | `active` \| `inactive` |
| `is_sellable` | boolean NOT NULL | ✅ | เปิดขายในใบเสนอราคา/ดีล (Phase ถัดไป) |
| `notes` | text NULL | ✅ | textarea |
| `image_url` | text NULL | ✅ | รูปหลัก · Storage `org-images/{org_id}/products/{id}.webp` |

→ รายละเอียดตาราง: [tables.md](./tables.md#products)

**Unique (active):** `(org_id, lower(trim(product_code)))`

---

## Layout ฟอร์ม

| ข้อมูลสินค้า | ราคาและสถานะ |
|--------------|--------------|
| รหัสสินค้า * | ราคาขาย * |
| ชื่อสินค้า * | ต้นทุน |
| รายละเอียด | สกุลเงิน |
| หมวดหมู่ (USelectMenu) | บาร์โค้ด |
| หน่วย (USelectMenu) | สถานะ |
| | เปิดการขาย (checkbox) |
| หมายเหตุ (full width) | |

---

## Validation UI

| ฟิลด์ | กฎ |
|--------|-----|
| `product_code` | required · unique ต่อ org |
| `name` | required |
| `list_price` | ≥ 0 |
| `cost_price` | null หรือ ≥ 0 |
| `category_id` | optional · ต้องเป็นหมวด active ใน org |
| `unit_id` | optional · ต้องเป็นหน่วย active ใน org |

---

## Data change log

| action | RPC | entity_type |
|--------|-----|-------------|
| create | `create_product` | `products` |
| update | `update_product` | `products` |
| delete (soft) | `soft_delete_product` | `products` |
| restore | `restore_product` | `products` |

**Migration:** `20260608120048_products.sql` · FK หมวด: `20260608120051_products_category_id.sql` · รูปหลัก: `20260608120052_product_image.sql` · FK หน่วย: `20260608120054_products_unit_id.sql` · รูปเพิ่มเติม: `20260608120055_product_gallery_images.sql`

---

## รูปเพิ่มเติม (Gallery)

| ฟิลด์ | รายละเอียด |
|-------|------------|
| `product_gallery_images` | หลายรูปต่อสินค้า · แยกจาก `image_url` (รูปหลัก) |
| UI | `AppProductGalleryUpload` · drag & drop อัปโหลด · ลากจัดลำดับ |
| Storage | `org-images/{org_id}/products/{product_id}/gallery/{image_id}.webp` |
| จำกัด | สูงสุด 20 รูป (`MAX_PRODUCT_GALLERY_IMAGES`) |

---

## Checklist

- [x] slug ตรง `masterProduct.ts`
- [x] i18n th + en
- [x] `data_change_logs` ผ่าน RPC
- [x] แท็บ ใช้งาน / ถูกลบ — owner + admin (`useArchiveTabs`)
- [x] หมวดหมู่ FK → `categories`
- [x] หน่วย FK → `units`
