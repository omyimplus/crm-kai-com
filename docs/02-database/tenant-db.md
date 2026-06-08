# Tenant DB (กลุ่ม 2)

**จำนวน:** 1 Supabase project **ต่อ 1 organization**

**บทบาท:** CRM ทั้งหมดของ org นั้น

---

## ตาราง (CRM)

| ตาราง | หน้าที่ |
|-------|---------|
| `profiles` | user ใน org (role, full_name) |
| `companies` | ลูกค้า/บัญชีใน CRM |
| `contacts` | ผู้ติดต่อ |
| `pipelines` | pipeline ขาย |
| `pipeline_stages` | stages |
| `deals` | ดีล |
| `activities` | note, call, meeting, task |
| `deal_stage_history` | ประวัติ stage (optional) |

## ไม่มี `org_id`

ทั้ง database = org เดียว — ไม่ต้อง column `org_id` ในตาราง CRM

## การเข้าถึง

- Nuxt → Supabase **โดยตรง**
- **anon key + RLS**
- ได้ config (URL + anon key) จาก Node API หลัง verify สิทธิ์

## Migration

- ใช้ชุดเดียวกันทุก tenant: `supabase/migrations/tenant/`
- อัปเดตทุก org ผ่าน migration runner (Phase 5)

## เอกสารที่เกี่ยวข้อง

- [06-crm-schema](../06-crm-schema/) — fields, RLS, roles รายละเอียด
