# Data Change Log — บันทึกการเปลี่ยนแปลงข้อมูล

> **กฎเหล็ก §13** — ทุก flow ที่สร้าง/แก้/ลบข้อมูลต้องเขียน log ตารางนี้  
> แยกจาก `activities` (timeline CRM) และ `deal_stage_history` (เฉพาะดีล)

---

## แนวคิด: ตาราง log **เดียว** สำหรับทุกตาราง

ไม่สร้าง log table แยกต่อตาราง CRM — ใช้ **`data_change_logs`** ตารางเดียว แยกประเภทด้วยคอลัมน์ `entity_type` (เช่น `profiles`, `org_roles`, `contacts`)

```
contacts  ─┐
org_roles ─┼→ data_change_logs (entity_type + entity_id + old/new snapshot)
profiles  ─┘
```

---

## ตาราง `data_change_logs`

| Column | หมายเหตุ |
|--------|----------|
| `org_id` | องค์กร |
| `actor_id` | ผู้ทำรายการ (`auth.uid()`) |
| `action` | `create` \| `update` \| `delete` |
| `entity_type` | ชื่อตาราง/โมดูล เช่น `profiles`, `contacts`, `deals` |
| `entity_id` | PK ของแถวที่เปลี่ยน |
| `summary` | ข้อความสั้น (ภาษาอังกฤษใน DB — UI แปลได้) |
| `old_data` | snapshot ก่อนเปลี่ยน (JSON) — `null` เมื่อ create |
| `new_data` | snapshot หลังเปลี่ยน (JSON) — `null` เมื่อ delete |
| `metadata` | แหล่งที่มา เช่น `{ "source": "admin_update_org_user" }` |
| `created_at` | เวลา |

**ห้ามบันทึก:** รหัสผ่าน, token, secret — ใช้ `password_changed: true` แทน

---

## วิธีเขียน log (บังคับ)

### 1) RPC / SQL (แนะนำ)

```sql
PERFORM public.write_data_change_log(
  'update',           -- action
  'contacts',         -- entity_type
  v_contact_id,       -- entity_id
  'Updated contact',  -- summary
  v_old_json,         -- old_data
  v_new_json,         -- new_data
  jsonb_build_object('source', 'my_rpc_name')
);
```

ฟังก์ชัน: `write_data_change_log(...)` — `SECURITY DEFINER`, ใส่ `org_id` + `actor_id` อัตโนมัติ

### 2) Frontend ตรง Supabase

**ห้าม** INSERT ตาราง CRM โดยไม่มี log — ใช้ RPC ที่เรียก `write_data_change_log` หรือ trigger (Phase 2+)

### 3) Checklist ก่อน merge

- [ ] มี `write_data_change_log` (หรือ trigger) ใน flow create/update/delete
- [ ] ไม่มี password/secret ใน `old_data` / `new_data`
- [ ] `entity_type` + `entity_id` ชัดเจน
- [ ] บันทึก DB-CHANGELOG + อัปเดตเอกสารนี้ถ้าเพิ่ม entity ใหม่

---

## RLS

| การกระทำ | ใคร |
|----------|-----|
| SELECT | owner / admin ใน org เดียวกัน |
| INSERT | เฉพาะ `write_data_change_log` (ไม่มี client insert ตรง) |
| UPDATE / DELETE | **ห้าม** — log แก้ไม่ได้ |

---

## ที่ implement แล้ว

| Flow | action | entity_type | source RPC |
|------|--------|-------------|------------|
| สร้างผู้ใช้ระบบ | create | `profiles` | `admin_create_org_user` |
| แก้ผู้ใช้ระบบ | update | `profiles` | `admin_update_org_user` |
| สร้าง org role | create | `org_roles` | `create_org_role` |
| แก้ org role / สิทธิ์ | update | `org_roles` | `update_org_role` |
| ลบ org role | delete | `org_roles` | `delete_org_role` |
| สร้างลูกค้า | create | `companies` | `create_company` |
| แก้ลูกค้า | update | `companies` | `update_company` |
| นำลูกค้าออก (soft delete) | delete | `companies` | `soft_delete_company` — cascade soft delete contacts ที่ผูกอยู่ (log ต่อ contact, `metadata.cascade`) |
| กู้คืนลูกค้า | update | `companies` | `restore_company` — cascade restore contacts จาก log |
| กู้คืนผู้ติดต่อ | update | `contacts` | `restore_contact` |
| สร้างผู้ติดต่อ | create | `contacts` | `create_contact` |
| แก้ผู้ติดต่อ | update | `contacts` | `update_contact` |
| นำผู้ติดต่อออก (soft delete) | delete | `contacts` | `soft_delete_contact` |
| สร้างเป้ายอดขาย | create | `sales_targets` | `create_sales_target` |
| แก้เป้ายอดขาย | update | `sales_targets` | `update_sales_target` |
| นำเป้าออก (soft delete) | delete | `sales_targets` | `soft_delete_sales_target` |
| กู้คืนเป้ายอดขาย | update | `sales_targets` | `restore_sales_target` |
| สร้างทีมขาย | create | `sales_teams` | `create_sales_team` |
| แก้ทีมขาย | update | `sales_teams` | `update_sales_team` |
| นำทีมขายออก (soft delete) | delete | `sales_teams` | `soft_delete_sales_team` |
| กู้คืนทีมขาย | update | `sales_teams` | `restore_sales_team` |
| สร้างสถานะโมดูล | create | `module_statuses` | `create_module_status` |
| แก้สถานะโมดูล | update | `module_statuses` | `update_module_status` |
| นำสถานะโมดูลออก (soft delete) | delete | `module_statuses` | `soft_delete_module_status` |
| กู้คืนสถานะโมดูล | update | `module_statuses` | `restore_module_status` |
| สร้างรหัสงานโมดูล | create | `job_code_sequences` | `create_job_code_sequence` |
| แก้รหัสงานโมดูล | update | `job_code_sequences` | `update_job_code_sequence` |
| นำรหัสงานโมดูลออก (soft delete) | delete | `job_code_sequences` | `soft_delete_job_code_sequence` |

**ดู log:** Setup → กิจกรรมผู้ใช้ (`/app/setup/user-activity`) — RPC `list_data_change_logs`

---

## แผนถัดไป (ยังไม่มี log)

| ตาราง | วิธีที่วางแผน |
|--------|--------------|
| deals | RPC หรือ trigger เมื่อ implement CRUD จริง |
| activities, pipelines | เช่นเดียวกัน |

---

## เอกสารที่เกี่ยวข้อง

- [IRON-RULES.md §13](../IRON-RULES.md)
- [tables.md](./tables.md)
- [permissions.md](./permissions.md)
