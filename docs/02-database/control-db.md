# Control DB (กลุ่ม 1)

**จำนวน:** 1 database (Supabase project กลาง)

**บทบาท:** ระบบกลาง — ไม่เก็บ CRM data

---

## ตาราง

| ตาราง | หน้าที่ |
|-------|---------|
| `auth.users` | Login (email/password) |
| `organizations` | ทะเบียน org: name, slug, status |
| `organization_members` | user อยู่ org ไหน, role |
| `subscriptions` | plan, status, trial_ends_at |
| `tenant_projects` | Supabase URL, anon key, encrypted service key, schema_version |
| `provision_jobs` | queued / running / done / failed |

## การเข้าถึง

- **Phase 3+:** Node API + service role **เท่านั้น**
- **ห้าม** frontend อ่าน `tenant_projects` หรือ secrets ตรง

## เหตุผลที่แยกจาก Tenant

- มี secrets (service role, management API token)
- business logic: trial, billing, provisioning
- tenant resolution ต้อง verify ฝั่ง server

## เอกสารที่เกี่ยวข้อง

- [04-api](../04-api/) — endpoints ที่คุยกับ Control DB
- [03-auth](../03-auth/) — auth.users อยู่ที่นี่ (Phase 3+)
- [09-flows](../09-flows/) — register, provision
