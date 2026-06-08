# 06 — CRM Schema

Schema ข้อมูล CRM — **source of truth อยู่ที่ [tables.md](./tables.md)**

> **🔴 Phase 1:** ทุกตารางมี `org_id` ใน Supabase project เดียว  
> **⚪ Phase 3+:** CRM ใน Tenant DB — ไม่มี `org_id`

## สถานะปัจจุบัน

| รายการ | สถานะ |
|--------|--------|
| Phase | 1 |
| Schema ออกแบบ | ✅ [tables.md](./tables.md) |
| Migration deploy | ❌ ยังไม่มี |
| RLS | ❌ ยังไม่ implement |

---

## ไฟล์ในโฟลเดอร์นี้

| ไฟล์ | อ่านเมื่อ |
|------|-----------|
| **[tables.md](./tables.md)** | 🔴 column definitions — implement migration |
| **[DATA-CHANGE-LOG.md](./DATA-CHANGE-LOG.md)** | 🔴 บันทึกทุก create/update/delete (กฎ §13) |
| **[ORG-ROLE-PERMISSIONS.md](./ORG-ROLE-PERMISSIONS.md)** | สิทธิ์ต่อเมนูใน `org_roles.permissions` |
| [permissions.md](./permissions.md) | role × table + RLS |
| [CHANGELOG.md](./CHANGELOG.md) | เปลี่ยน design ล่าสุด |

---

## Core Tables (สรุป)

```
organizations → profiles → companies, contacts, pipelines, deals, activities
```

รายละเอียด column → **tables.md**

---

## 🔴 RLS Pattern (Phase 1)

```sql
current_org_id() → org_id FROM profiles WHERE id = auth.uid()

USING (org_id = current_org_id() AND deleted_at IS NULL)
```

→ [permissions.md](./permissions.md)

---

## Default Pipeline (seed)

```
Lead → Qualified → Proposal → Negotiation → Won / Lost
```

---

## DB snapshot (หลัง deploy)

→ [../02-database/DB-SCHEMA.md](../02-database/DB-SCHEMA.md)  
→ [../02-database/DB-CHANGELOG.md](../02-database/DB-CHANGELOG.md)

## เอกสารที่เกี่ยวข้อง

- [../02-database/PHASE-MATRIX.md](../02-database/PHASE-MATRIX.md)
- [../02-database/phase1-single-db.md](../02-database/phase1-single-db.md)

## ดูการเปลี่ยนแปลงล่าสุด

→ [CHANGELOG.md](./CHANGELOG.md)
