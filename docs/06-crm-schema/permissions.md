# Permissions — Role × Table (Phase 1)

> **ใช้ตอนนี้ (Phase 1–2)** — enforce ที่ RLS + middleware Nuxt  
> อนาคต Phase 3+ ปรับ policy ใน Tenant DB (ไม่มี org_id)

---

## Roles

| Role | สรุป |
|------|------|
| **owner** | ทุกอย่าง + settings org + จัดการ user (Phase 2) |
| **admin** | CRM เต็ม + settings ยกเว้น billing/delete org |
| **sales** | CRUD records ที่ own หรือ assign |
| **readonly** | SELECT เท่านั้น |

---

## ตาราง × Role (Phase 1)

| ตาราง | owner | admin | sales | readonly |
|-------|-------|-------|-------|----------|
| organizations | RU (own org) | R | R | R |
| profiles | CRUD (org) | CRUD (org) | R (org) | R (org) |
| org_roles | CRUD (org) | CRUD (org) | R | R |
| data_change_logs | R | R | — | — |
| companies | CRUD | CRUD | CRUD* | R |
| contacts | CRUD | CRUD | CRUD* | R |
| deals | CRUD | CRUD | CRUD* | R |
| pipelines | CRUD | CRUD | R | R |
| pipeline_stages | CRUD | CRUD | R | R |
| activities | CRUD | CRUD | CRUD* | R |
| deal_stage_history | R (auto insert) | R | R | R |

\* **sales:** CRUD เฉพาะ `owner_id = self` หรือ `created_by = self` (Phase 2 ละเอียดขึ้น)

**ตัวย่อ:** C=Create R=Read U=Update D=Delete

---

## RLS ขั้นต่ำ (Phase 1)

ทุกตาราง CRM:

```sql
-- อ่าน: org เดียวกัน + (active หรือ owner/admin)
USING (
  org_id = current_org_id()
  AND (
    deleted_at IS NULL
    OR is_admin_or_owner()
  )
)
```

**แท็บ ใช้งาน / ถูกลบ (UI):** owner + admin เท่านั้น — `useArchiveTabs()` + `<AppArchiveTabs>` · `restore_*` RPC ต้อง `is_admin_or_owner()`

```sql
-- เขียน: org เดียวกัน
WITH CHECK (org_id = current_org_id())
```

**readonly:** แยก policy — SELECT only, ห้าม INSERT/UPDATE/DELETE

```sql
-- ตัวอย่าง helper
CREATE FUNCTION current_user_role() RETURNS text AS $$
  SELECT role FROM profiles WHERE id = auth.uid()
$$ LANGUAGE sql STABLE SECURITY DEFINER;
```

---

## Phase 1 ข้อจำกัด

- ยังไม่ enforce sales ownership ละเอียด — Phase 2
- ยังไม่มี UI จัดการ user — Phase 2
- `deal_stage_history` insert ผ่าน trigger/app เมื่อ stage เปลี่ยน

---

## เอกสารที่เกี่ยวข้อง

- [03-auth](../03-auth/)
- [tables.md](./tables.md)
- [../10-security](../10-security/)
