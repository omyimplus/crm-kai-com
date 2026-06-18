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
| customer_type | text | NO | `'company'` | `company` \| `individual` — [CUSTOMER-MASTER-FIELDS §0](./CUSTOMER-MASTER-FIELDS.md#0-general-customer_type-email-mobile-notes) |
| email | text | YES | | |
| mobile | text | YES | | |
| notes | text | YES | | |
| industry | text | YES | | slug — [§2 Industry](./CUSTOMER-MASTER-FIELDS.md#2-industry-industry) |
| industry_segment | text | YES | `'sme'` | slug — [§1](./CUSTOMER-MASTER-FIELDS.md#1-industry-segment-industry_segment) |
| sales_grade | text | YES | | slug — [§3](./CUSTOMER-MASTER-FIELDS.md#3-sales-classification--grade-sales_grade) |
| website | text | YES | | |
| phone | text | YES | | |
| address | text | YES | | Bill To |
| owner_id | uuid | YES | | FK → profiles — [§5 Customer Owner](./CUSTOMER-MASTER-FIELDS.md#5-customer-owner-owner_id) |
| status | text | NO | `'active'` | lifecycle — [§4](./CUSTOMER-MASTER-FIELDS.md#4-status-status) |
| tax_id | text | YES | | [§6 Tax & Payment](./CUSTOMER-MASTER-FIELDS.md#6-tax--payment-section) |
| tax_branch | text | YES | | |
| tax_vat | text | YES | | WHT rate slug — `none` \| `wht_*` · [§6.5](./CUSTOMER-MASTER-FIELDS.md#65-withholding-tax--wht-tax_vat) |
| vat_currency | text | NO | `'THB'` | `THB` \| `USD` |
| payment_code | text | YES | | `transfer` \| `credit` \| `cash` \| `cheque` |
| credit_term_days | integer | NO | `30` | |
| credit_limit | numeric(18,2) | NO | `0` | |
| credit_balance | numeric(18,2) | NO | `0` | readonly UI — AR Phase 2+ |
| created_by | uuid | YES | | FK → profiles(id) |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | soft delete |

---

## company_ship_addresses

ที่อยู่จัดส่ง (Ship To) — หลายรายการต่อ company

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| company_id | uuid | NO | | FK → companies ON DELETE CASCADE |
| label | text | YES | | ชื่อสาขา/คลัง |
| address | text | NO | | |
| is_default | boolean | NO | `false` | 1 รายการต่อ company — RPC `get_company_default_ship_address` |
| sort_order | integer | NO | `0` | ลำดับใน UI |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |

→ [CUSTOMER-MASTER-FIELDS §7](./CUSTOMER-MASTER-FIELDS.md#7-address-ship-to-company_ship_addresses)

---

## company_bill_addresses

ที่อยู่ออกใบแจ้งหนี้ (Bill To) — หลายรายการต่อ company

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| company_id | uuid | NO | | FK → companies ON DELETE CASCADE |
| label | text | YES | | ชื่อสาขา/ป้าย |
| address | text | NO | | |
| is_default | boolean | NO | `false` | 1 รายการต่อ company — RPC `get_company_default_bill_address` |
| sort_order | integer | NO | `0` | ลำดับใน UI |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |

→ `companies.address` = snapshot ของ default bill (backward compat) · [§8](./CUSTOMER-MASTER-FIELDS.md#8-address-bill-to-company_bill_addresses)

---

## contacts

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| company_id | uuid | YES | | FK → companies (Customer) · [§relation](./CONTACT-MASTER-FIELDS.md#customer-relation-company_id) |
| first_name | text | NO | | |
| last_name | text | YES | | |
| email | text | YES | | |
| phone | text | YES | | |
| job_title | text | YES | | |
| mobile | text | YES | | |
| department | text | YES | | |
| contact_role | text | YES | `'other'` | slug · [CONTACT-MASTER-FIELDS.md](./CONTACT-MASTER-FIELDS.md) |
| is_main_contact | boolean | NO | `false` | Main Contact — **unique 1 ต่อ `company_id`** (active) |
| notes | text | YES | | |
| owner_id | uuid | YES | | FK → profiles |
| source | text | YES | | web, referral, import |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | |

---

## sales_targets

เป้ายอดขายต่อพนักงาน × ช่วงเวลา — [SALES-TARGET-MASTER-FIELDS.md](./SALES-TARGET-MASTER-FIELDS.md)

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| profile_id | uuid | NO | | FK → profiles (ผู้รับเป้า) |
| period_type | text | NO | | `month` \| `quarter` \| `year` |
| period_year | integer | NO | | |
| period_month | integer | YES | | 1–12 ถ้า month |
| period_quarter | integer | YES | | 1–4 ถ้า quarter |
| target_amount | numeric(15,2) | NO | 0 | เป้าหมาย |
| current_amount | numeric(15,2) | NO | 0 | ยอดปัจจุบัน (manual) |
| currency | text | NO | `'THB'` | |
| notes | text | YES | | |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | soft delete |

**Unique (active):** `(org_id, profile_id, period_type, period_year, period_month, period_quarter)`  
**% ทำได้:** UI จาก `current_amount / target_amount` · ผูกยอดขาย Phase ถัดไป

---

## products

สินค้าและบริการ — [PRODUCT-MASTER-FIELDS.md](./PRODUCT-MASTER-FIELDS.md)

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| product_code | text | NO | | unique ต่อ org (active) |
| name | text | NO | | |
| description | text | YES | | |
| category_id | uuid | YES | | FK → categories |
| unit_id | uuid | YES | | FK → units |
| list_price | numeric(15,2) | NO | 0 | ราคาขาย |
| cost_price | numeric(15,2) | YES | | ต้นทุน |
| currency | text | NO | `'THB'` | `THB` \| `USD` |
| barcode | text | YES | | |
| status | text | NO | `'active'` | `active` \| `inactive` |
| is_sellable | boolean | NO | true | เปิดขาย |
| notes | text | YES | | |
| image_url | text | YES | | รูปหลัก · bucket `org-images` |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | soft delete |

**Unique (active):** `(org_id, lower(trim(product_code)))`

---

## units

หน่วยนับ master — [UNIT-MASTER-FIELDS.md](./UNIT-MASTER-FIELDS.md)

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| unit_code | text | NO | | unique ต่อ org (active) |
| name | text | NO | | |
| description | text | YES | | |
| sort_order | integer | NO | 0 | |
| status | text | NO | `'active'` | `active` \| `inactive` |
| notes | text | YES | | |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | soft delete |

**Unique (active):** `(org_id, lower(trim(unit_code)))`

---

## lead_sources

แหล่งที่มาลีด master — [LEAD-SOURCE-MASTER-FIELDS.md](./LEAD-SOURCE-MASTER-FIELDS.md)

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| source_code | text | NO | | unique ต่อ org (active) |
| name | text | NO | | ชื่อใน dropdown ลีด |
| description | text | YES | | |
| sort_order | integer | NO | 0 | |
| status | text | NO | `'active'` | `active` \| `inactive` |
| notes | text | YES | | |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | soft delete |

**Unique (active):** `(org_id, lower(trim(source_code)))`

---

## partners

พาร์ตเนอร์ master — [PARTNER-MASTER-FIELDS.md](./PARTNER-MASTER-FIELDS.md)

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| partner_code | text | NO | | unique ต่อ org (active) |
| name | text | NO | | ชื่อบริษัท |
| partner_type | text | NO | `'distributor'` | distributor · reseller · agent · vendor · strategic · other |
| tier | text | NO | `'silver'` | platinum · gold · silver · bronze · standard |
| partner_since | date | YES | | |
| status | text | NO | `'active'` | active · inactive |
| contact_person | text | NO | `''` | |
| email | text | NO | `''` | |
| phone | text | NO | `''` | |
| website | text | YES | | |
| commission_rate | numeric(5,2) | NO | 0 | 0–100 |
| description | text | YES | | legacy · ไม่ใช้ใน UI |
| sort_order | integer | NO | 0 | legacy · ไม่ใช้ใน UI |
| notes | text | YES | | legacy · ไม่ใช้ใน UI |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | soft delete |

**Unique (active):** `(org_id, lower(trim(partner_code)))`

---

## sales_teams

ทีมขาย — สมาชิกมาจาก `profiles` (ผู้ใช้งานในระบบ) ผ่าน `sales_team_members`

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| team_code | text | NO | | unique ต่อ org (active) |
| name | text | NO | | ชื่อทีม |
| description | text | YES | | |
| team_lead_id | uuid | YES | | FK → profiles |
| sort_order | integer | NO | 0 | |
| status | text | NO | `'active'` | `active` \| `inactive` |
| notes | text | YES | | |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | soft delete |

**Unique (active):** `(org_id, lower(trim(team_code)))`

---

## sales_team_members

สมาชิกทีมขาย (M:N กับ profiles)

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| sales_team_id | uuid | NO | | FK → sales_teams · PK |
| profile_id | uuid | NO | | FK → profiles · PK |
| created_at | timestamptz | NO | now() | |

**Migration:** `20260608120064_sales_teams.sql`

---

## module_statuses

สถานะที่ org กำหนดต่อโมดูล — ใช้เป็นตัวเลือกใน workflow CRM

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| module_key | text | NO | | customer, lead, pipeline, … |
| status_code | text | NO | | `^[A-Z][A-Z0-9_]{1,48}$` · unique ต่อ org + module (active, case-insensitive) |
| name | text | NO | | ชื่อแสดงผล |
| description | text | YES | | |
| color | text | YES | | hex สำหรับ badge |
| sort_order | integer | NO | 0 | |
| is_default | boolean | NO | false | หนึ่งค่าเริ่มต้นต่อ module |
| status | text | NO | `'active'` | `active` \| `inactive` |
| notes | text | YES | | |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | soft delete |

**Unique (active):** `(org_id, module_key, lower(trim(status_code)))`

**Migration:** `20260608120065_module_statuses.sql`

---

## job_code_sequences

รูปแบบเลขที่เอกสาร/รหัสงานต่อโมดูล — [MASTER-DATA-MENU.md](../05-frontend/MASTER-DATA-MENU.md) §12

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| module_key | text | NO | | task, lead, opportunity, … |
| prefix | text | NO | | `^[A-Z][A-Z0-9]{0,9}$` |
| date_enabled | boolean | NO | true | |
| date_include_year | boolean | NO | true | |
| date_include_month | boolean | NO | true | |
| date_include_day | boolean | NO | true | |
| date_part_order | text[] | NO | year,month,day | ลำดับส่วนวันที่ |
| date_style | text | NO | compact | compact / dash / iso |
| segment_order | text[] | NO | prefix,date,number | ลำดับส่วนรหัส |
| segment_separator | text | NO | `-` | `-` `_` `.` `/` `:` · ใช้เมื่อ `separator_enabled` |
| separator_enabled | boolean | NO | true | เปิด/ปิดตัวคั่นระหว่างส่วน |
| pad_length | integer | NO | 4 | 1–10 |
| start_number | integer | NO | 1 | |
| last_number | integer | NO | 0 | ตัวนับปัจจุบัน |
| reset_rule | text | NO | never | never / daily / monthly / yearly |
| status | text | NO | active | active / inactive |
| notes | text | YES | | |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | soft delete |

**Unique (active):** `(org_id, module_key)`

**Migration:** `20260608120067_job_code_sequences.sql` · `20260608120068_job_code_separator_enabled.sql`

---

## product_gallery_images

รูปเพิ่มเติมของสินค้า (แยกจาก `products.image_url`) — [PRODUCT-MASTER-FIELDS.md](./PRODUCT-MASTER-FIELDS.md)

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK · ใช้เป็นชื่อไฟล์ใน Storage |
| org_id | uuid | NO | | FK → organizations |
| product_id | uuid | NO | | FK → products |
| image_url | text | NO | | รูปใน gallery |
| sort_order | integer | NO | 0 | ลำดับแสดงผล |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |

**Migration:** `20260608120055_product_gallery_images.sql`

---

## categories

หมวดหมู่ master — [CATEGORY-MASTER-FIELDS.md](./CATEGORY-MASTER-FIELDS.md)

| Column | Type | Null | Default | หมายเหตุ |
|--------|------|------|---------|----------|
| id | uuid | NO | gen_random_uuid() | PK |
| org_id | uuid | NO | | FK → organizations |
| module_key | text | NO | `'product'` | Phase 1: product only |
| category_code | text | NO | | unique ต่อ org+module |
| name | text | NO | | |
| description | text | YES | | |
| parent_id | uuid | YES | | FK → categories |
| sort_order | integer | NO | 0 | |
| color | text | YES | | hex สำหรับ UI |
| status | text | NO | `'active'` | `active` \| `inactive` |
| notes | text | YES | | |
| image_url | text | YES | | รูปหลัก · bucket `org-images` |
| created_by | uuid | YES | | FK → profiles |
| created_at | timestamptz | NO | now() | |
| updated_at | timestamptz | NO | now() | |
| deleted_at | timestamptz | YES | | soft delete |

**Unique (active):** `(org_id, module_key, lower(trim(category_code)))`

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
