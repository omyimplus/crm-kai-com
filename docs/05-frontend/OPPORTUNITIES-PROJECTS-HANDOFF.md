# Opportunities — ส่วนโปรเจกต์ (Handoff)

> **วันที่:** 2026-06-18  
> **สถานะ:** หยุดชั่วคราว — dropdown ประเภทโปรเจกต์ / ประเภทย่อย / กลุ่มสินค้า ยังไม่ verify ว่าใช้ได้จริง  
> **Dev server:** ปิดแล้ว (port 3000 ว่าง)

---

## อาการที่ user รายงาน

- หน้าสร้าง/แก้โอกาสขาย — ส่วน **โปรเจกต์** แก้ชื่อหรือมูลค่าได้บางฟิลด์ แต่ **เลือกประเภทโปรเจกต์ · ประเภทย่อย · กลุ่มสินค้าไม่ได้**
- หน้า **ดูรายละเอียด** (`/app/opportunities/:id`) — ฟอร์มทั้งก้อนเป็น `readonly` โดยเจตนา ต้องกด **แก้ไข** ก่อน

---

## สาเหตุที่สงสัย (จากการทดสอบ agent)

| # | ประเด็น | รายละเอียด |
|---|---------|------------|
| 1 | **ชั้น component / v-model ซ้อนกัน** | เคยใช้ `OpportunitiesProjectsSection` → `OpportunitiesProjectCard` + `defineModel` หลายชั้น + `patchProject()` / `:model-value` แทน `v-model` ทำให้ `USelectMenu` ไม่ sync กับ parent |
| 2 | **`USelectMenu` ใน v-for** | bind ผ่าน `projects[index].field` หรือ emit แบบ manual อาจทำให้ Combobox เปิดได้แต่ไม่มีรายการใน portal (ทดสอบแล้ว: stage dropdown มี `listbox` + `option` แต่ project type ไม่มี) |
| 3 | **Sticky sidebar ทับพื้นที่คลิก** | layout `lg:grid` + `aside lg:sticky` — agent เจอ `Click target intercepted` ตอนคลิก dropdown โปรเจกต์ (แก้บางส่วนด้วย `lg:self-start` แล้ว) |
| 4 | **Grid 3 คอลัมน์แคบ** | `xl:grid-cols-3` บนฟิลด์โปรเจกต์อาจทำให้คอลัมน์ขวาชิดกับ aside — เปลี่ยนเป็น `md:grid-cols-2` แล้ว |

---

## สิ่งที่ทำแล้ว (รื้อ + ทำใหม่)

### ลบ component แยก

- ~~`OpportunitiesProjectsSection.vue`~~
- ~~`OpportunitiesProjectCard.vue`~~

### รวมเข้า `OpportunitiesForm.vue` โดยตรง

- ส่วนโปรเจกต์อยู่ใน form เดียวกับ stage / customer (pattern เดียวกับ `LeadsForm` + `v-model="row.project_type"`)
- `v-for="(row, index) in projects"` บน `defineModel('projects')`
- grid **2 คอลัมน์** (`md:grid-cols-2`)
- enum dropdown: `:search-input="false"`

### Utils ใหม่ใน `masterOpportunityProjects.ts`

- `opportunityProjectTypeSelectOptions(t, current)`
- `opportunityProjectSubTypeSelectOptions(t, current)`
- `opportunityProductGroupSelectOptions(t, categories, current)`

### Layout

- `OpportunitiesOpportunityPage.vue` + `OpportunitiesViewPage.vue` — aside เพิ่ม `lg:self-start`

### Build

- `npm run build` ผ่าน (ใช้ `NODE_OPTIONS=--max-old-space-size=4096`)

---

## สิ่งที่ยังไม่ verify

- [ ] เปิด dropdown **ประเภทโปรเจกต์** แล้วเห็นตัวเลือก (ติดตั้ง, บำรุงรักษา, …) และเลือกแล้วค่าค้าง
- [ ] ประเภทย่อย + กลุ่มสินค้า เช่นเดียวกัน
- [ ] บันทึก opp แล้ว `opportunity_projects` ถูก sync ใน DB (ต้องมี migration 081–086 apply แล้ว)
- [ ] หน้า edit โหลดโปรเจกต์จาก `list_opportunity_projects` ถูกต้อง

### ผลทดสอบ agent ล่าสุด (ก่อนพัก)

- **Stage** `USelectMenu`: เปิดแล้วมี `listbox` + 6 `option` ✅
- **Project type** `USelectMenu`: สถานะ `expanded` แต่ **ไม่มี `listbox` / `option` ใน DOM** ❌
- ยังไม่ได้ retest หลังรื้อรวมเข้า `OpportunitiesForm` แบบเต็ม (user ขอพักก่อน)

---

## งานต่อเมื่อกลับมา

1. **รัน dev** → `cd frontend && npm run dev`
2. **Hard refresh** หน้า `/app/opportunities/from-lead/:leadId` (ลีดที่ convert ได้)
3. **ทดสอบ manual** 3 dropdown ในส่วนโปรเจกต์
4. ถ้ายังพัง — ลองทางเลือก:
   - ใช้ **computed options คงที่** ใน form (ไม่เรียก function ใน template ทุก render)
   - เปรียบเทียบ props ของ `USelectMenu` ที่ทำงาน (stage) กับโปรเจกต์ทีละตัวใน Vue DevTools
   - ลอง **`USelect`** แทน `USelectMenu` สำหรับ enum คงที่ (ถ้า Nuxt UI รองรับ)
   - ตรวจ **`supabase db push`** migration `081`–`086` โดยเฉพาะ `list_opportunity_projects`
5. อัปเดต `frontend/CHANGELOG.md` + `docs/05-frontend/CHANGELOG.md` เมื่อ fix ยืนยันแล้ว

---

## ไฟล์ที่เกี่ยวข้อง

| ไฟล์ | บทบาท |
|------|--------|
| `frontend/app/components/opportunities/OpportunitiesForm.vue` | ฟอร์มรวมส่วนโปรเจกต์ |
| `frontend/app/utils/masterOpportunityProjects.ts` | draft helpers + select options |
| `frontend/app/components/opportunities/OpportunitiesOpportunityPage.vue` | create/edit page |
| `frontend/app/composables/useOpportunities.ts` | `listProjects`, create/update + projects payload |
| `supabase/migrations/20260608120086_opportunity_projects.sql` | ตาราง + RPC sync |

---

## ทดสอบ

- URL: `http://localhost:3000`
- Account: `tester1` / `testpass123` (ดู `docs/11-dev-setup/TEST-ACCOUNTS.md`)
- สร้าง opp จากลีด: `/app/leads` → ลีดที่ผ่านเกณฑ์ → แปลงเป็นโอกาสขาย  
  หรือตรง: `/app/opportunities/from-lead/<leadId>`

---

## กฎฟิลด์ (ยังใช้อยู่)

| แก้ได้บน opp | ล็อกจากลีด |
|--------------|------------|
| stage, close_date, sales_designer, sales_team, bill-to, **โปรเจกต์ทั้งหมด** | title, customer, description, owner, sales_owner |
| มูลค่ารวม = SUM โปรเจกต์ → sync lead | probability (จาก stage) |
