# Changelog — CRM Schema

→ ออกแบบปัจจุบัน: [README.md](./README.md)  
→ **DB snapshot:** [../02-database/DB-SCHEMA.md](../02-database/DB-SCHEMA.md)  
→ **DB changes:** [../02-database/DB-CHANGELOG.md](../02-database/DB-CHANGELOG.md)

---

## ประวัติ

### 2026-06-08 — add DATA-CHANGE-LOG.md + data_change_logs table

- **ทำอะไร:** กฎเหล็ก §13 — บันทึกทุก data change ในตารางแยก + `write_data_change_log()`
- **ไฟล์ที่กระทบ:** `DATA-CHANGE-LOG.md`, `tables.md`, `IRON-RULES.md`, migration `20260608120005_*`
- **Phase:** 1

### 2026-06-08 — create tables.md + permissions.md (schema source of truth)

- **ทำอะไร:** column definitions ครบทุกตาราง Phase 1 + role × table matrix
- **ไฟล์ที่กระทบ:** `tables.md`, `permissions.md`, `README.md`
- **Phase:** 1
- **ผลกระทบ:** implement migration ใช้ tables.md เป็น authoritative

### 2026-06-08 — create เอกสาร CRM schema

- **ทำอะไร:** สร้าง README ตาราง CRM, RLS, roles
- **ไฟล์ที่กระทบ:** `README.md`
- **Phase:** 1
- **หมายเหตุ:** เมื่อ deploy migration จริง บันทึกที่ DB-CHANGELOG ไม่ใช่แค่ที่นี่
