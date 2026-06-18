# Lead Source Master — ฟิลด์ UI และ spec สำหรับ SQL

> **Route:** `/app/lead-source` · **Phase 1:** แหล่งที่มาลีด (องค์กรกำหนดเอง)  
> **Relation:** ใช้เลือกใน Lead (เมื่อโมดูล Lead พร้อม)  
> **Code:** `frontend/app/config/masterLeadSource.ts` · **ฟอร์ม:** `MasterDataLeadSourceForm.vue`

---

## แนวคิด

- **UI / org ใหม่:** กำหนดรายการเองผ่าน `/app/lead-source` (ไม่มีปุ่มโหลดค่าเริ่มต้นในแอป)
- **Dev / demo:** `seed.sql` ใส่ 13 รายการให้ demo org ตอน `db reset` — แก้ไขใน SQL ได้
- โครงสร้างเดียวกับ **หน่วย** (unit master): รหัส · ชื่อ · รายละเอียด · ลำดับ · สถานะ

---

## สถานะ DB ปัจจุบัน (`lead_sources`)

| Column | Type | บันทึกจาก UI | หมายเหตุ |
|--------|------|-------------|----------|
| `source_code` | text NOT NULL | ✅ | รหัสแหล่งที่มา · unique ต่อ org |
| `name` | text NOT NULL | ✅ | ชื่อแสดงใน dropdown ลีด |
| `description` | text NULL | ✅ | |
| `sort_order` | int NOT NULL | ✅ | เรียงในรายการ · default 0 |
| `status` | text NOT NULL | ✅ | `active` \| `inactive` |
| `notes` | text NULL | ✅ | |

→ รายละเอียดตาราง: [tables.md](./tables.md#lead_sources)

**Unique (active):** `(org_id, lower(trim(source_code)))`

---

## ค่าเริ่มต้นใน `seed.sql` (demo org เท่านั้น)

รัน `supabase db reset` จะ insert 13 รายการถ้า org ยังไม่มีแหล่งที่มา active:

WEB, GOOGLE, FACEBOOK, LINE, INSTAGRAM, TIKTOK, REFERRAL, PARTNER, EVENT, WALKIN, PHONE, EMAIL, OTHER

→ เป็นข้อมูลเริ่มต้นสำหรับ dev/demo · org อื่นกำหนดเองผ่าน UI · แก้/ลบ/เพิ่มได้ตามต้องการ

---

## Data change log

| action | RPC |
|--------|-----|
| create | `create_lead_source` |
| update | `update_lead_source` |
| delete | `soft_delete_lead_source` |
| restore | `restore_lead_source` |

**Migration:** `20260608120056_lead_sources.sql`  
**Fix (ถ้ารัน migration เก่าที่มี channel/seed แล้ว):** `20260608120057_lead_sources_drop_channel_seed.sql`
