# CRM Tables — Column Definitions (Source of Truth)

> **Phase 1 migrations:** `supabase/migrations/`  
> Snapshot deploy แล้ว → [../02-database/DB-SCHEMA.md](../02-database/DB-SCHEMA.md)  
> ประวัติ DB → [../02-database/DB-CHANGELOG.md](../02-database/DB-CHANGELOG.md)

---

## 🔴 ใช้ตอนนี้ (Phase 1)

- ทุกตารางด้านล่างอยู่ **Supabase project เดียว**
- ทุกตาราง CRM มี **`org_id`** (ยกเว้น `organizations` เป็นต้นทาง)
- `profiles`: **1 user = 1 org** (ดู [DECISIONS D-004](../00-overview/DECISIONS.md))

---

## organizations

ลูกค้า SaaS (tenant) — **ไม่ใช่** company ใน CRM

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| name | text | NO | | ชื่อ org |
| slug | text | NO | | UNIQUE, เช่น `acme` |
| logo_url | text | YES | | |
| settings | jsonb | NO | `'{}'` | timezone, currency |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |

---

## profiles

เชื่อม Supabase Auth กับ org + role

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | | PK, FK → auth.users(id) |
| org_id | uuid | NO | | FK → organizations(id) |
| full_name | text | YES | | |
| username | text | YES | | unique ต่อ org (lower) |
| avatar_url | text | YES | | |
| role | text | NO | `'sales'` | owner \| admin \| sales \| readonly (system role) |
| org_role_id | uuid | YES | | FK → org_roles — บทบาทองค์กร (กำหนดเอง) |
| is_active | boolean | NO | true | status |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |

**Constraints:** UNIQUE (id, org_id) — Phase 1 มี 1 org ต่อ user

---

## companies

ลูกค้า/บัญชีใน CRM

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| name | text | NO | | |
| industry | text | YES | | |
| website | text | YES | | |
| phone | text | YES | | |
| address | text | YES | | |
| owner_id | uuid | YES | | FK → profiles(id) |
| status | text | NO | `'active'` | active \| inactive |
| created_by | uuid | YES | | FK → profiles(id) |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | soft delete |

---

## contacts

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| company_id | uuid | YES | | FK → companies (nullable) |
| first_name | text | NO | | |
| last_name | text | YES | | |
| email | text | YES | | |
| phone | text | YES | | |
| job_title | text | YES | | |
| owner_id | uuid | YES | | FK → profiles |
| source | text | YES | | web, referral, import |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | |

---

## pipelines

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| name | text | NO | | เช่น Sales |
| is_default | boolean | NO | false | |
| sort_order | int | NO | 0 | |
| created_at | timestamptz | NO | now() | |

---

## pipeline_stages

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| pipeline_id | uuid | NO | | FK → pipelines |
| name | text | NO | | Lead, Won, Lost |
| sort_order | int | NO | | |
| probability | int | NO | 0 | 0–100 |
| is_won | boolean | NO | false | |
| is_lost | boolean | NO | false | |
| color | text | YES | | hex สำหรับ Kanban |

**Default seed:** Lead → Qualified → Proposal → Negotiation → Won / Lost

---

## deals

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| title | text | NO | | |
| company_id | uuid | YES | | FK → companies |
| contact_id | uuid | YES | | FK → contacts (primary) |
| pipeline_id | uuid | NO | | FK → pipelines |
| stage_id | uuid | NO | | FK → pipeline_stages |
| owner_id | uuid | YES | | FK → profiles |
| amount | numeric(15,2) | NO | 0 | |
| currency | text | NO | `'THB'` | |
| expected_close_date | date | YES | | |
| status | text | NO | `'open'` | open \| won \| lost |
| lost_reason | text | YES | | |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| closed_at | timestamptz | YES | | |
| deleted_at | timestamptz | YES | | |

---

## activities

Polymorphic timeline

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| type | text | NO | | note \| call \| meeting \| email \| task |
| subject | text | YES | | |
| body | text | YES | | |
| related_type | text | NO | | deal \| contact \| company |
| related_id | uuid | NO | | |
| owner_id | uuid | YES | | FK → profiles |
| due_at | timestamptz | YES | | task/meeting |
| completed_at | timestamptz | YES | | |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |

---

## org_roles

บทบาทองค์กรที่กำหนดเอง — Master Data → กำหนด Role

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| code | text | NO | | unique ต่อ org, `^[a-z][a-z0-9_]{1,48}$` |
| label | text | NO | | ชื่อแสดง |
| description | text | YES | | |
| permissions | jsonb | NO | `'{}'` | สิทธิ์ต่อโมดูล (Phase 2+) |
| is_system | boolean | NO | false | role ระบบ (ลบ/ปิดไม่ได้) |
| is_active | boolean | NO | true | |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |

**RPC:** `list_org_roles`, `create_org_role`, `update_org_role`

---

## data_change_logs

บันทึกการเปลี่ยนแปลงข้อมูลทุก flow (กฎเหล็ก §13) — ดู [DATA-CHANGE-LOG.md](./DATA-CHANGE-LOG.md)

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| actor_id | uuid | YES | | FK → profiles (ผู้ทำรายการ) |
| action | text | NO | | create \| update \| delete |
| entity_type | text | NO | | ชื่อตาราง/โมดูล |
| entity_id | uuid | NO | | PK ของแถวที่เปลี่ยน |
| summary | text | YES | | ข้อความสั้น |
| old_data | jsonb | YES | | snapshot ก่อนเปลี่ยน |
| new_data | jsonb | YES | | snapshot หลังเปลี่ยน |
| metadata | jsonb | NO | `'{}'` | source RPC, ฯลฯ |
| created_at | timestamptz | NO | now() | |

**Functions:** `write_data_change_log(...)`, `profile_log_snapshot(uuid)`

---

## deal_stage_history

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| deal_id | uuid | NO | | FK → deals |
| from_stage_id | uuid | YES | | FK → pipeline_stages |
| to_stage_id | uuid | NO | | FK → pipeline_stages |
| changed_by | uuid | YES | | FK → profiles |
| changed_at | timestamptz | NO | now() | |

---

## Indexes (แนะนำ)

```sql
-- ทุกตาราง CRM ที่มี deleted_at
CREATE INDEX idx_<table>_org ON <table>(org_id) WHERE deleted_at IS NULL;

-- เพิ่มเติม
CREATE INDEX idx_contacts_company ON contacts(company_id);
CREATE INDEX idx_deals_stage ON deals(stage_id);
CREATE INDEX idx_deals_owner ON deals(owner_id);
CREATE INDEX idx_activities_related ON activities(org_id, related_type, related_id);
```

---

## เอกสารที่เกี่ยวข้อง

- [DATA-CHANGE-LOG.md](./DATA-CHANGE-LOG.md) — กฎบันทึกการเปลี่ยนแปลง
- [permissions.md](./permissions.md) — role × table
- [../02-database/PHASE-MATRIX.md](../02-database/PHASE-MATRIX.md)
- [README.md](./README.md)
