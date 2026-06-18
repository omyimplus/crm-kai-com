# Customer Master — ฟิลด์ UI และ spec สำหรับ SQL

> อ้างอิง mockup ฟอร์ม `/app/customer/new` · ใช้วาง migration / enum / CHECK constraint  
> **Code:** `frontend/app/config/masterCustomer.ts` · **ฟอร์ม:** `MasterDataCustomerForm.vue`

---

## สถานะ DB ปัจจุบัน (`companies` + `company_ship_addresses`)

| Column / Table | Type | บันทึกจาก UI | หมายเหตุ |
|----------------|------|-------------|----------|
| `name` | text NOT NULL | ✅ | |
| `customer_type` | text NOT NULL | ✅ | [§0](#0-general-customer_type-email-mobile-notes) |
| `email` | text NULL | ✅ | |
| `mobile` | text NULL | ✅ | |
| `notes` | text NULL | ✅ | |
| `industry_segment` | text NULL | ✅ | [§1](#1-industry-segment-industry_segment) |
| `industry` | text NULL | ✅ | slug — [§2](#2-industry-industry) |
| `sales_grade` | text NULL | ✅ | [§3](#3-sales-classification--grade-sales_grade) |
| `website` | text NULL | ✅ | auto `https://` |
| `phone` | text NULL | ✅ | |
| `address` | text NULL | ✅ | Bill To default → sync จาก `company_bill_addresses` |
| `owner_id` | uuid NULL | ✅ | [§5](#5-customer-owner-owner_id) |
| `status` | text NOT NULL | ✅ | [§4](#4-status-status) · migration `20260608120030_*` |
| Tax & Payment cols | — | ✅ | [§6](#6-tax--payment-section) · migration `20260608120031_*` |
| `credit_balance` | numeric | แสดงอย่างเดียว | ไม่ส่งจาก client |
| `company_ship_addresses` | table | ✅ | [§7](#7-address-ship-to-company_ship_addresses) |
| `company_bill_addresses` | table | ✅ | [§8](#8-address-bill-to-company_bill_addresses) |

→ รายละเอียดตาราง: [tables.md](./tables.md#companies)

---

## 0. General (`customer_type`, `email`, `mobile`, `notes`)

**UI:** section General · grid 2 คอลัมน์

| ฟิลด์ form | Label EN | Default UI | ชนิด SQL | หมายเหตุ |
|------------|----------|------------|----------|----------|
| `customer_type` | Customer Type | `company` | `text NOT NULL DEFAULT 'company'` | CHECK `company`, `individual` |
| `email` | Email | `''` | `text NULL` | required ใน validation UI |
| `mobile` | Mobile | `''` | `text NULL` | |
| `notes` | Notes | `''` | `text NULL` | textarea |

**i18n:** `masterData.customer.options.customerType.{slug}`

| slug | Label EN | Label TH |
|------|----------|----------|
| `company` | Company | นิติบุคคล |
| `individual` | Individual | บุคคลธรรมดา |

**กฎ UI (บุคคลธรรมดา / `individual`):** ล็อก `industry_segment` และ `industry` เป็นไม่ระบุ

**Code:** `applyIndividualCustomerTypeRules()` ใน `masterCustomer.ts` · migration CHECK `20260608120080_*`

**Migration:** `20260608120031_*` (column) · `20260608120080_restore_customer_type_lead_type_channel.sql` (revert จาก 078)

---

## 1. Industry Segment (`industry_segment`)

**UI:** dropdown · label EN = *Industry Segment* · label TH = *อุตสาหกรรม* · placeholder *Select industry…*

**DB ปัจจุบัน:** คอลัมน์ `companies.industry_segment` — **บันทึก slug อุตสาหกรรม** (migration `20260608120079_*`)

**Default UI:** `NULL` → แสดง *— Not specified —* / *— ไม่ระบุ —*

| ลำดับ | slug | Label EN | Label TH |
|------|------|----------|----------|
| 1 | `agriculture` | Agriculture | เกษตรกรรม |
| 2 | `construction` | Construction | ก่อสร้าง |
| 3 | `education` | Education | การศึกษา |
| 4 | `finance` | Finance | การเงิน |
| 5 | `healthcare` | Healthcare | สุขภาพ |
| 6 | `hospitality` | Hospitality | โรงแรมและบริการ |
| 7 | `manufacturing` | Manufacturing | การผลิต |
| 8 | `retail` | Retail | ค้าปลีก |
| 9 | `technology` | Technology | เทคโนโลยี |
| 10 | `transportation` | Transportation | ขนส่ง |

**หมายเหตุ:** คอลัมน์ `companies.industry` ยัง sync ค่าเดียวกันเพื่อ backward compat — UI ใช้ `industry_segment` อย่างเดียว

**i18n:** `masterData.customer.options.industrySegment.{slug}`

**Migration:** `20260608120079_industry_segment_catalog.sql` (แทน enterprise/sme/startup/individual)

---

## 2. Industry (`industry`) — legacy column

**สถานะ:** ซ่อนจาก UI — ค่าถูก mirror จาก `industry_segment` ตอนบันทึก

**DB:** คอลัมน์ `companies.industry` (text NULL) · CHECK เดิมยังใช้ slug ชุดเดียวกับ §1

**i18n (change log):** `masterData.customer.options.industry.{slug}`

---

## 3. Sales Classification / Grade (`sales_grade`)

**UI:** dropdown · label EN = *Sales Classification (Grade)* · label TH = *ระดับการขาย (เกรด)*

**DB ปัจจุบัน:** คอลัมน์ `companies.sales_grade` — **บันทึก slug แล้ว** (migration `20260608120031_*`)

| ลำดับ | slug (แนะนำ SQL) | Label EN | Label TH |
|------|------------------|----------|----------|
| 1 | `vip` | VIP — Very Important Customer | VIP — ลูกค้าสำคัญมาก |
| 2 | `a` | A — High Purchase | A — ซื้อสูง |
| 3 | `b` | B — Regular Customer | B — ลูกค้าปกติ |
| 4 | `c` | C — Low Purchase | C — ซื้อต่ำ |
| 5 | `prospect` | Prospect — Target Customer | Prospect — ลูกค้าเป้าหมาย |

**แนะนำ migration:**

```sql
ALTER TABLE companies
  ADD COLUMN sales_grade text NULL
  CHECK (sales_grade IS NULL OR sales_grade IN (
    'vip', 'a', 'b', 'c', 'prospect'
  ));
```

**i18n:** `masterData.customer.options.salesGrade.{slug}`

---

## 4. Status (`status`)

**UI:** dropdown · label EN = *Status* · label TH = *สถานะ*

**DB ปัจจุบัน:** คอลัมน์ `companies.status` (text NOT NULL) — **บันทึก slug แล้ว** (migration `20260608120030_*`)

**Default UI:** `active`

**การเปลี่ยนสถานะ (Phase 1):** ผู้ใช้เลือก/แก้ใน dropdown เอง — **ยังไม่มี** workflow เปลี่ยนอัตโนมัติ (deal won, approval ฯลฯ เป็น Phase 2+)

| ลำดับ | slug (ค่าใน DB) | Label EN | Label TH | Badge (list) |
|------|-----------------|----------|----------|--------------|
| 1 | `active` | Active | ใช้งาน | success |
| 2 | `inactive` | Inactive | ไม่ใช้งาน | neutral |
| 3 | `prospect` | Prospect | เป้าหมาย | primary |
| 4 | `churned` | Churned | หลุด | error |
| 5 | `pending` | Pending | รอดำเนินการ | warning |

**Migration (deploy แล้วใน repo):**

```sql
ALTER TABLE companies DROP CONSTRAINT IF EXISTS companies_status_check;
ALTER TABLE companies ADD CONSTRAINT companies_status_check
  CHECK (status IN ('active', 'inactive', 'prospect', 'churned', 'pending'));
```

**หมายเหตุ:** ไม่สับสนกับ `sales_grade = prospect` (เกรดเป้าหมาย) — คนละฟิลด์

**i18n:** `masterData.customer.options.status.{slug}`

---

## 5. Customer Owner (`owner_id`)

**UI:** dropdown · label EN = *Customer Owner* · label TH = *ผู้ดูแลลูกค้า*

**DB ปัจจุบัน:** คอลัมน์ `companies.owner_id` (uuid NULL) — **บันทึกแล้ว** · FK → `profiles(id)`

**ไม่ใช่ Customer ID:** รหัสลูกค้า = `companies.id` (ระบบ gen) · ฟิลด์นี้ = **พนักงานผู้รับผิดชอบบัญชี**

**Default UI:** `NULL` → *— Not specified —* / *— ไม่ระบุ —*

**แหล่งตัวเลือก (Phase 1):**

| เงื่อนไข | ค่า |
|----------|-----|
| ตาราง | `profiles` |
| กรอง | `org_id` = org ปัจจุบัน · `is_active = true` |
| แสดงใน dropdown | `full_name` (fallback = uuid) |
| ค่าที่บันทึก | `profiles.id` (uuid) |

**เหตุผลที่มีฟิลด์ (CRM ทั่วไป):**

- ระบุ **Sales/AE ผู้ดูแล** ลูกค้ารายนี้
- รองรับรายงาน / KPI ตาม owner (Phase 2+)
- รองรับสิทธิ์ `owner_id = self` ตาม [permissions.md](./permissions.md) (Phase 2+)

**การกำหนดค่า (Phase 1):** เลือก/แก้ใน dropdown เอง — default ไม่บังคับ

**รอ confirm จาก product (⚪):**

- [ ] บังคับเลือก owner ตอนสร้างหรือไม่
- [ ] default เป็นผู้ login หรือว่าง
- [ ] เปลี่ยน owner อัตโนมัติเมื่อ deal won / transfer หรือไม่
- [ ] แสดงคอลัมน์ owner ในหน้ารายการลูกค้าหรือไม่

**i18n:** `masterData.customer.fields.owner` · `ownerPlaceholder`

**Code:** `MasterDataCustomerForm.vue` → `loadOwners()`

---

## 6. Tax & Payment (section)

**UI:** section *Tax & Payment* / *ภาษีและการชำระเงิน* · grid 3 คอลัมน์ (xl)

**DB ปัจจุบัน:** คอลัมน์ใน `companies` — **บันทึกแล้ว** (migration `20260608120031_*`) · `credit_balance` แสดง readonly ไม่ส่งจาก client

**Layout (mockup — อ่านลงแต่ละคอลัมน์):**

| คอล. 1 | คอล. 2 | คอล. 3 |
|--------|--------|--------|
| Tax ID | VAT Group (Currency) | Credit Term (Days) |
| Tax Branch | Payment Code | WHT (ภาษีหัก ณ ที่จ่าย) |
| Credit Limit | Credit Balance | — |

### 6.1 ฟิลด์ text / number

| ฟิลด์ form | Label EN | Default UI | ชนิด (แนะนำ SQL) | หมายเหตุ |
|------------|----------|------------|----------------|----------|
| `tax_id` | Tax ID | `''` · placeholder `0000000000000` | `text` | เลขประจำตัวผู้เสียภาษี 13 หลัก |
| `tax_branch` | Tax Branch | `''` · placeholder Head Office / Branch | `text` | สำนักงานใหญ่ / สาขา |
| `tax_vat` | Tax VAT | `NULL` | `text NULL` | slug WHT rate — [§6.5](./CUSTOMER-MASTER-FIELDS.md#65-withholding-tax--wht-tax_vat) |
| `credit_term_days` | Credit Term (Days) | `30` | `integer` | จำนวนวันเครดิต |
| `credit_limit` | Credit Limit | `0.00` | `numeric(18,2)` | ชิดขวาใน UI |
| `credit_balance` | Credit Balance | `0.00` | `numeric(18,2)` | **readonly** — คำนวณจาก AR/invoice Phase 2+ |

### 6.2 VAT Group (`vat_currency`)

**UI:** dropdown · default **`THB`**

| slug (แนะนำ SQL) | Label UI |
|------------------|----------|
| `THB` | THB |
| `USD` | USD |

Placeholder ปิด dropdown: *THB / USD*

**i18n:** ค่าแสดง = slug · `fields.vatCurrencyPlaceholder`

### 6.3 Payment Code (`payment_code`)

**UI:** dropdown · default **`NULL`** → *— Not specified —*

| ลำดับ | slug (แนะนำ SQL) | Label EN | Label TH |
|------|------------------|----------|----------|
| — | `NULL` | — Not specified — | — ไม่ระบุ — |
| 1 | `transfer` | Transfer | โอนเงิน |
| 2 | `credit` | Credit | เครดิต |
| 3 | `cash` | Cash | เงินสด |
| 4 | `cheque` | Cheque | เช็ค |

**i18n:** `masterData.customer.options.paymentCode.{slug}`

### 6.5 Withholding tax / WHT (`tax_vat`)

**UI:** dropdown · label *ภาษีหัก ณ ที่จ่าย* / *Withholding tax (WHT)* · default **`NULL`** → *— Not specified —*

> **หมายเหตุ:** คอลัมน์ DB ยังชื่อ `tax_vat` (mockup row เดิม) — เก็บ **อัตราหัก ณ ที่จ่าย** ไม่ใช่ VAT 7%

| ลำดับ | slug (ค่าใน DB) | Label EN | Label TH |
|------|-----------------|----------|----------|
| — | `NULL` | — Not specified — | — ไม่ระบุ — |
| 1 | `none` | No withholding | ไม่หัก |
| 2 | `wht_3` | 3% | 3% |
| 3 | `wht_5` | 5% | 5% |
| 4 | `wht_0_5` | 0.5% | 0.5% |
| 5 | `wht_0_75` | 0.75% | 0.75% |
| 6 | `wht_1` | 1% | 1% |
| 7 | `wht_1_5` | 1.5% | 1.5% |
| 8 | `wht_2` | 2% | 2% |
| 9 | `wht_10` | 10% | 10% |
| 10 | `wht_15` | 15% | 15% |

**i18n:** `masterData.customer.options.whtRate.{slug}` · `fields.whtRatePlaceholder`

**Migration CHECK:** `20260608120037_companies_tax_vat_wht_rates.sql`

### 6.4 แนะนำ migration (รวม section)

```sql
ALTER TABLE companies
  ADD COLUMN tax_id text NULL,
  ADD COLUMN tax_branch text NULL,
  ADD COLUMN tax_vat text NULL,
  ADD COLUMN vat_currency text NOT NULL DEFAULT 'THB'
    CHECK (vat_currency IN ('THB', 'USD')),
  ADD COLUMN payment_code text NULL
    CHECK (payment_code IS NULL OR payment_code IN ('transfer', 'credit', 'cash', 'cheque')),
  ADD COLUMN credit_term_days integer NOT NULL DEFAULT 30
    CHECK (credit_term_days >= 0),
  ADD COLUMN credit_limit numeric(18, 2) NOT NULL DEFAULT 0
    CHECK (credit_limit >= 0),
  ADD COLUMN credit_balance numeric(18, 2) NOT NULL DEFAULT 0;
  -- credit_balance: อัปเดตจากระบบ AR ใน Phase 2+ ไม่ให้ client เขียนตรง
```

**Phase 1 UI:** บันทึกครบยกเว้น `credit_balance` (sidebar แจ้ง readonly)

---

## 7. Address Ship To (`company_ship_addresses`)

**UI:** section Ship To · รายการหลายแถว (label + address) · เพิ่ม/ลบใน UI

**DB:** ตาราง `company_ship_addresses` (1:N ต่อ company)

| Column | Type | หมายเหตุ |
|--------|------|----------|
| `id` | uuid PK | |
| `org_id` | uuid FK | RLS ตาม org |
| `company_id` | uuid FK | ON DELETE CASCADE |
| `label` | text NULL | ชื่อสาขา/คลัง |
| `address` | text NOT NULL | |
| `is_default` | boolean NOT NULL DEFAULT false | **ได้ 1 รายการต่อ company** (partial unique index) |
| `sort_order` | integer | ลำดับใน UI |

**Default สำหรับระบบ:**

- UI: badge *Default* · ลิงก์ **ค่าเริ่มต้น** ตั้ง default · สวิตช์ตอนเพิ่ม/แก้
- รายการแรกที่เพิ่ม → checkbox default เปิดอัตโนมัติ
- RPC: `get_company_default_ship_address(company_id)` — คืนแถว `is_default = true` หรือ fallback แถวแรกตาม `sort_order`

**Migration:** `20260608120031_*` (ตาราง) · `20260608120033_*` (`is_default` + RPC)

**การบันทึก (Phase 1):** replace ทั้งชุดต่อ company — ลบแถวเดิมแล้ว insert ใหม่จากฟอร์ม

**Code:** `useCompanies.syncShipAddresses()` · `getDefaultShipAddress()` · `MasterDataCustomerForm.vue`

---

## 8. Address Bill To (`company_bill_addresses`)

**UI:** section Bill To · รายการหลายแถว (label + address) · เพิ่ม/ลบ · ตั้ง **ค่าเริ่มต้น**

**DB:** ตาราง `company_bill_addresses` — โครงสร้างเดียวกับ `company_ship_addresses`

| Column | Type | หมายเหตุ |
|--------|------|----------|
| `id` | uuid PK | |
| `org_id` | uuid FK | RLS ตาม org |
| `company_id` | uuid FK | ON DELETE CASCADE |
| `label` | text NULL | |
| `address` | text NOT NULL | |
| `is_default` | boolean | ได้ 1 รายการต่อ company |
| `sort_order` | integer | ลำดับใน UI |

**Backward compat:** `companies.address` = ข้อความของ default bill ตอนบันทึก

**RPC:** `get_company_default_bill_address(company_id)`

**Migration:** `20260608120035_company_bill_addresses.sql` (+ ย้าย `companies.address` เดิม)

**Code:** `MasterDataCustomerAddressList` · `useCompanies.syncBillAddresses()` · `getDefaultBillAddress()`

---

## Address Bill To

**DB:** ตาราง `company_bill_addresses` (1:N) — UI เหมือน Ship To · ตั้ง default ได้

| ฟิลด์เดิม | การย้าย |
|-----------|---------|
| `companies.address` | migrate → แถว bill default · ยัง sync จาก default ตอนบันทึก (backward compat) |

→ ดู [§8 Address Bill To](./CUSTOMER-MASTER-FIELDS.md#8-address-bill-to-company_bill_addresses)

---

## Checklist migration (2026-06-16)

- [x] slug ใน MD ตรง `CUSTOMER_*` ใน `masterCustomer.ts`
- [x] i18n th + en ครบทุก slug
- [x] อัปเดต [tables.md](./tables.md) + [DB-CHANGELOG.md](../02-database/DB-CHANGELOG.md)
- [x] บันทึก `data_change_logs` ตาม IRON-RULES §13 — create/update/delete ผ่าน RPC (`create_company`, `update_company`, `soft_delete_company`)
- [x] ลบลูกค้า (soft delete) → cascade soft delete ผู้ติดต่อที่ผูก `company_id` (`20260608120041`)

→ [DATA-CHANGE-LOG.md](./DATA-CHANGE-LOG.md) · [CHANGELOG.md](./CHANGELOG.md)

---

## ลบลูกค้า (soft delete)

- **RPC:** `soft_delete_company`
- **Cascade:** ผู้ติดต่อที่ `company_id` ชี้ลูกค้านี้และยัง active → soft delete ก่อนลบลูกค้า · log แยกต่อ contact (`metadata.cascade = true`, `source = soft_delete_company`)
- **Trigger:** `contacts_block_deleted_company_trg` — กัน INSERT/UPDATE contact ให้ชี้ลูกค้าที่ `deleted_at IS NOT NULL`
- **Migration:** `20260608120041_soft_delete_company_cascade_contacts.sql`
- **UI:** `MasterDataCustomerDeleteModal` แจ้งว่าผู้ติดต่อที่ผูกอยู่จะถูกนำออกจากรายการด้วย

---

## กู้คืน (restore)

- **UI:** แท็บ **ใช้งาน / ถูกลบ** บนหน้ารายการ · ปุ่มกู้คืนบนแท็บถูกลบ — **owner + admin เท่านั้น** (`useArchiveTabs` · migration 44)
- **RPC ลูกค้า:** `restore_company` — กู้ลูกค้า + ผู้ติดต่อที่ cascade soft delete พร้อมกัน (อ้าง `data_change_logs.metadata.cascade`)
- **RPC ผู้ติดต่อ:** `restore_contact` — กู้ทีละคน (ลูกค้าต้อง active · ถ้าลูกค้าถูกลบ → กู้ลูกค้าก่อน)
- **Migration:** `20260608120043_restore_master_data.sql`
- **Log:** action `update` · `metadata.restore = true`

