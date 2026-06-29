# KuTo — Contacts Information Architecture

> **สถานะ:** ✅ list hub mock · C360 ยังไม่ mock · **IA ตัดสินแล้ว**  
> **รวมเข้า:** [KUTO-CUSTOMERS-IA.md](./KUTO-CUSTOMERS-IA.md) · **entity:** `contacts` → `companies`  
> **Legacy:** [CONTACT-MASTER-FIELDS.md](../06-crm-schema/CONTACT-MASTER-FIELDS.md) · `/app/contact` (Master Data)

---

## หลักการ

Figma Make แยก **ผู้ติดต่อ** เป็นโมดูล top-level 10 เมนู — ใน CRM Kai ผู้ติดต่อ **ผูกลูกค้าเสมอ** (`contacts.company_id` → `companies`)

KuTo **ไม่มีโมดูลผู้ติดต่อระดับ top-level** — **รายชื่อผู้ติดต่อ** เป็นเมนูย่อยใต้ **ลูกค้า** · รายละเอียด/ประวัติใน **Customer 360**

---

## Sidebar (2 รายการ — ภายใต้โมดูลลูกค้า)

ไม่มีโมดูล **ผู้ติดต่อ** ระดับ top-level · รายการหลักอยู่ใน dropdown **ลูกค้า**

| ลำดับ | Label (TH) | Route | Icon | หมายเหตุ |
|-------|------------|-------|------|----------|
| 1 | รายชื่อผู้ติดต่อ | `/app/customers/contacts` | `users` | รายการทั้ง org · filter `company_id` |
| 2 | ประวัติการติดต่อ | `/app/customers/contact-history` | `history` | timeline ทั้ง org · filter ลูกค้า/ผู้ติดต่อ |

Route legacy `/app/contacts` → `/app/customers/contacts` · `/app/contacts/history` → `/app/customers/contact-history`

### หน้า `/app/customers/contacts` (✅ mock KuTo)

**ไฟล์:** `KutoContactsListPage.vue` · `kutoContactsListMock.ts` · `pages/app/customers/contacts/index.vue`

- KPI 6 ใบ · filter · แท็บ 9 รายการ · ตาราง + **แผงขวา 2 การ์ด** (ดูรายละเอียดด่วน + กิจกรรมล่าสุด) — pattern เดียวกับรายชื่อลูกค้า
- คลิกแถว → อัปเดตแผงขวา · ลิงก์ C360 ลูกค้า · ประวัติการติดต่อ

### หน้า `/app/customers/contact-history` (✅ mock KuTo)

**ไฟล์:** `KutoContactHistoryPage.vue` · `kutoContactHistoryMock.ts`

- **Timeline feed** ตาม figma (ไม่ใช่แผงขวาแบบรายชื่อผู้ติดต่อ) · filter · แท็บประเภท · สลับโหมดตาราง
- คลิกการ์ด → แถบล่างลิงก์ C360 · **ดูงานของฉัน** → `/app/activities`

---

## ใน Customer 360 — `/app/customers/:id`

### แท็บ ผู้ติดต่อ (Contacts)

แทนเมนู figma ทั้งกลุ่ม (รายชื่อ · หลัก · ผู้ตัดสินใจ · ฝ่ายจัดซื้อ · IT · บทบาท)

| ฟีเจอร์ | พฤติกรรม |
|---------|----------|
| รายชื่อคน | ตารางในบริษัทนี้ · role chip · main contact badge |
| **+ ผู้ติดต่อ** | modal/หน้าย่อย · `company_id` preset |
| Filter role | chip: ทั้งหมด · หลัก · ผู้ตัดสินใจ · influencer · … (ไม่ใช่เมนูแยก) |
| คลิกแถว | เปิด **แผงขวา** — รายละเอียด + **ประวัติติดต่อรายบุคคล** |

**Role ใน DB:** `contact_role` — `decision_maker`, `influencer`, `user`, `gatekeeper`, `other`  
Figma แยก purchasing/IT → Phase 1 ใช้ role chip/filter บนรายการ (หรือขยาย slug ภายหลัง)

### แท็บ กิจกรรม (Activities / Timeline)

แทน **รายละเอียด** ของประวัติต่อลูกค้า — หน้า sidebar **ประวัติการติดต่อ** ใช้เช็คข้ามลูกค้า · C360 ใช้ดูลึกรายลูกค้า

| ระดับ | ข้อมูล | แหล่ง |
|-------|--------|-------|
| **ทั้งลูกค้า** | โทร · นัด · อีเมล · follow-up ทุกคนในบริษัท | `tasks` ที่ `company_id` · `activities` ที่ `related_type=company` |
| **รายบุคคล** | ประวัติคุยกับคนนี้ | แผงในแท็บผู้ติดต่อ · `tasks.contact_id` · `activities` ที่ `related_type=contact` |

| Action | หมายเหตุ |
|--------|----------|
| **+ บันทึกกิจกรรม** | สร้าง task/activity ผูก company (+ contact ถ้าเลือก) |
| **ดูทั้งหมดในกิจกรรม** | `/app/activities?company=:id` |

Overview แสดง **กิจกรรมล่าสุด 3–5 รายการ** (snippet) — ไม่ต้องแท็บ “ประวัติ” แยก

---

## ไม่ใช่ sidebar — deep link / อนาคต

Route ยังจองไว้ (`[...slug].vue`) แต่**ไม่**อยู่ใน `kutoMenu.ts`

| Route | เดิมใน figma | ที่อยู่จริง |
|-------|--------------|-------------|
| `/app/contacts` | รายชื่อผู้ติดต่อ | redirect/legacy → `/app/customers/contacts` |
| `/app/contacts/primary` | ผู้ติดต่อหลัก | filter `is_main_contact` ใน C360 หรือ `/app/contacts` |
| `/app/contacts/decision-makers` | ผู้ตัดสินใจ | filter `contact_role=decision_maker` |
| `/app/contacts/purchasing` | ฝ่ายจัดซื้อ | role chip (อนาคต slug) |
| `/app/contacts/it` | ฝ่ายไอที | role chip (อนาคต slug) |
| `/app/contacts/roles` | บทบาท | dropdown ในฟอร์ม · ไม่ใช่หน้า list |
| `/app/contacts/history` | ประวัติการติดต่อ | `/app/customers/contact-history` |
| `/app/contacts/duplicates` | ผู้ติดต่อซ้ำ | ปุ่มใน import / hub |
| `/app/contacts/import` | นำเข้า | ขั้นใน **นำเข้าลูกค้า** (sheet contacts) |
| `/app/contacts/schedule` | กำหนดการ | `/app/activities` filter `contact_id` |

---

## สิ่งที่เอาออกจาก sidebar (และเหตุผล)

| รายการ | เหตุผล |
|--------|--------|
| โมดูลผู้ติดต่อ top-level (10 เมนู figma) | เหลือแค่ **รายชื่อผู้ติดต่อ** ใต้ลูกค้า · ที่เหลือใน C360/filter |
| ประวัติการติดต่อ (เมนู top-level figma) | อยู่ใน sidebar ลูกค้า `/app/customers/contact-history` |
| กำหนดการผู้ติดต่อ | = `/app/activities` |

---

## ห้ามยุบข้าม entity

| สิ่งที่เก็บแยก | เหตุผล |
|---------------|--------|
| ตาราง `contacts` | ลูกค้า 1 รายหลายคน · main contact rule · Opp/Task ผูก `contact_id` |
| โมดูล `/app/activities` | คิวงานข้ามลูกค้า · ปฏิทิน · มอบหมายทีม |
| Legacy `/app/contact` | Master Data CRUD — reuse composable ใน C360 แท็บผู้ติดต่อ |

---

## Implement ถัดไป (KuTo)

1. C360 แท็บ **ผู้ติดต่อ** + แผงประวัติรายบุคคล (mock)
2. C360 แท็บ **กิจกรรม** — timeline ระดับลูกค้า
3. `/app/contacts` — optional global list (deep link)
4. นำเข้า — รวม contacts ใน wizard นำเข้าลูกค้า

---

## Sync

แก้ IA ผู้ติดต่อ → อัปเดต `kutoMenu.ts` + ไฟล์นี้ + `KUTO-CUSTOMERS-IA.md` + `KUTO-MENU-PAGE-MATRIX.md` + CHANGELOG
