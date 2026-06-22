# Opportunities — ส่วนโปรเจกต์ (Handoff)

> **วันที่:** 2026-06-18  
> **สถานะ:** ✅ แก้ dropdown แล้ว — verify บน browser ผ่าน  
> **Dev server:** รันได้ที่ `http://localhost:3000`

---

## อาการที่ user รายงาน

- หน้าสร้าง/แก้โอกาสขาย — ส่วน **โปรเจกต์** แก้ชื่อหรือมูลค่าได้บางฟิลด์ แต่ **เลือกประเภทโปรเจกต์ · ประเภทย่อย · กลุ่มสินค้าไม่ได้**
- หน้า **ดูรายละเอียด** (`/app/opportunities/:id`) — ฟอร์มทั้งก้อนเป็น `readonly` โดยเจตนา ต้องกด **แก้ไข** ก่อน

---

## Root cause (ยืนยันแล้ว)

**`USelectMenu` + `value: ''` (empty string) สำหรับตัวเลือก "ไม่ระบุ"** — Combobox เปิด (`expanded`) แต่ไม่ render `listbox` / `option` ใน DOM

แก้โดยใช้ **`value: null`** + `normalizeSelectValue()` เหมือน dropdown อื่นในโปรเจกต์ (Leads, Master Product)

---

## สิ่งที่ทำแล้ว

### `OpportunitiesProjectCard.vue` (ใหม่)

- `defineModel<OpportunityProjectDraft>` — หนึ่งโปรเจกต์ต่อ component
- computed options ใน script (ไม่เรียก function ใน template)
- enum dropdown: `null` = ไม่ระบุ · `@update:model-value` + `normalizeSelectValue`
- ไม่ใช้ `:search-input="false"`

### Types / utils

- `OpportunityProjectDraft`: `project_type` / `project_sub_type` / `products_group` → `string | null`
- `masterOpportunityProjects.ts`: default `null` · payload แปลงเป็น `''` ก่อนส่ง RPC

### Layout

- `OpportunitiesForm.vue` — v-for + `OpportunitiesProjectCard`
- aside `lg:self-start` (OpportunityPage + ViewPage)

---

## Verify แล้ว

- [x] เปิด dropdown **ประเภทโปรเจกต์** — มี listbox + 7 options · เลือก "ติดตั้ง" ได้
- [x] **ประเภทย่อย** — มี listbox + options
- [ ] บันทึก opp แล้ว `opportunity_projects` sync ใน DB (ต้อง apply migration 081–086)
- [ ] หน้า edit โหลดโปรเจกต์จาก `list_opportunity_projects`

---

## ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | บทบาท |
|------|--------|
| `frontend/app/components/opportunities/OpportunitiesProjectCard.vue` | การ์ดโปรเจกต์ + dropdown |
| `frontend/app/components/opportunities/OpportunitiesForm.vue` | ฟอร์มรวมส่วนโปรเจกต์ |
| `frontend/app/utils/masterOpportunityProjects.ts` | draft helpers + payload |
| `frontend/app/composables/useOpportunities.ts` | `listProjects`, create/update + projects payload |
| `supabase/migrations/20260608120086_opportunity_projects.sql` | ตาราง + RPC sync |

---

## ทดสอบ

- URL: `http://localhost:3000`
- Account: `tester1` / `testpasspass123` (ดู `docs/11-dev-setup/TEST-ACCOUNTS.md`)
- สร้าง opp จากลีด: `/app/opportunities/from-lead/<leadId>`

---

## กฎฟิลด์ (ยังใช้อยู่)

| แก้ได้บน opp | ล็อกจากลีด |
|--------------|------------|
| stage, close_date, sales_designer, sales_team, bill-to, **โปรเจกต์ทั้งหมด** | title, customer, description, owner, sales_owner |
| มูลค่ารวม = SUM โปรเจกต์ → sync lead | probability (จาก stage) |
