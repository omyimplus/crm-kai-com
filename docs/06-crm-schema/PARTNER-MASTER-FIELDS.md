# Partner Master — ฟิลด์ UI และ spec สำหรับ SQL

> **Route:** `/app/partner` · **Phase 1:** พาร์ตเนอร์ / ช่องทางคู่ค้า  
> **อ้างอิง:** ฟอร์ม Partner ระบบเก่า (Partner Info + Contact Details)  
> **Code:** `frontend/app/config/masterPartner.ts` · **ฟอร์ม:** `MasterDataPartnerForm.vue`

---

## Partner info

| ฟิลด์ UI | Column | บังคับ | หมายเหตุ |
|----------|--------|--------|----------|
| Partner code | `partner_code` | ✅ | เช่น PTN-001 · unique ต่อ org |
| Company name | `name` | ✅ | ชื่อบริษัทพาร์ตเนอร์ |
| Type | `partner_type` | ✅ | distributor · reseller · agent · vendor · strategic · other |
| Tier | `tier` | ✅ | platinum · gold · silver · bronze · standard |
| Status | `status` | ✅ | active · inactive |
| Partner since | `partner_since` | | date |

## Contact details

| ฟิลด์ UI | Column | บังคับ | หมายเหตุ |
|----------|--------|--------|----------|
| Contact person | `contact_person` | ✅ | |
| Email | `email` | ✅ | |
| Phone | `phone` | ✅ | |
| Website | `website` | | auto เติม https:// |
| Commission rate (%) | `commission_rate` | | 0–100 · default 0 |

→ รายละเอียดตาราง: [tables.md](./tables.md#partners)

**Unique (active):** `(org_id, lower(trim(partner_code)))`

---

## Data change log

| action | RPC |
|--------|-----|
| create | `create_partner` |
| update | `update_partner` |
| delete | `soft_delete_partner` |
| restore | `restore_partner` |

**Migration:** `20260608120058_partners.sql` · legacy fields: `20260608120060_partners_legacy_fields.sql`
