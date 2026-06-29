# KuTo — Leads Information Architecture

> **สถานะ:** ✅ inbox mock · ✅ list hub mock · ✅ import mock  
> **Legacy spec:** [LEADS-MODULE.md](./LEADS-MODULE.md) · **เมนู matrix:** [KUTO-MENU-PAGE-MATRIX.md](./KUTO-MENU-PAGE-MATRIX.md)  
> **Config:** `frontend-kuto/app/config/kutoMenu.ts`

---

## หลักการ

Figma Make แยก Leads เป็น 10 เมนูย่อย — ส่วนใหญ่เป็น **มุมมอง / action / เครื่องมือ** ไม่ใช่โมดูลแยก

KuTo + CRM Kai ยุบให้สอดคล้อง legacy: **hub หนึ่งหน้า** + **กล่องรับ** ใน sidebar (คิวเด่น) · ที่เหลืออยู่**ในหน้า** หรือ **deep link**

---

## Sidebar (3 รายการ)

| ลำดับ | Label (TH) | Route | Icon | Badge | หมายเหตุ |
|-------|------------|-------|------|-------|----------|
| 1 | กล่องรับเป้าหมาย | `/app/leads/inbox` | `inbox` | 12 (mock) | ลีดใหม่ / ยังไม่มอบหมาย |
| 2 | เป้าหมายทั้งหมด | `/app/leads` | `list` | — | Hub หลัก · parent link ชี้ที่นี่ |
| 3 | นำเข้าเป้าหมาย | `/app/leads/import` | `upload` | — | CSV / Excel import |

Parent **ลูกค้าเป้าหมาย** แสดง badge รวมคิวเมื่อเมนูพับอยู่

**คำศัพท์:** โมดูล Leads ใช้คำ **「เป้าหมาย」** ทั้งชุด — แยกจากโมดูล **ลูกค้า** · แท็บ `status = prospect` ในรายชื่อลูกค้าใช้ **สถานะ: เป้าหมาย** (ไม่ใช่ “ลูกค้าเป้าหมาย”)

ไอคอนเมนูย่อยทุกโมดูล: `kutoNavSubIcons.ts` + override ใน `kutoMenu.ts`

---

## ในหน้า `/app/leads` (✅ mock KuTo)

**ไฟล์:** `KutoLeadsListPage.vue` · `kutoLeadsListMock.ts` · `pages/app/leads/index.vue`

**Layout (โหมดตาราง):** KPI เต็มความกว้าง · ตารางซ้าย + **แผงขวา 2 การ์ด** (ดูรายละเอียดด่วน + ช่องทาง) — เหมือน `KutoLeadsInboxPage` · `lg:` sticky

| แท็บ | นิยาม filter | หมายเหตุ |
|------|--------------|----------|
| **ทั้งหมด** | active leads (ไม่รวม soft-deleted) | default |
| **กล่องรับ** | `owner_id` ว่าง หรือ status NEW | sync กับ `/app/leads/inbox` |
| **แปลงแล้ว** | `status_code = CONVERTED` | ไม่นับในลีดที่ใช้งาน |

### มุมมอง (view mode)

| โหมด | หมายเหตุ |
|------|----------|
| **ตาราง** | default · ตาม `LeadsLeadTable` legacy |
| **Kanban** | คอลัมน์ตาม `module_statuses` · v1.1 ใน legacy spec |

### ตัวกรอง (filters) — บน toolbar

- ค้นหา (ชื่อ · บริษัท · email · โทร · รหัสลีด)
- สถานะ (ชิปจาก `module_statuses`)
- แหล่งที่มา (dropdown `lead_sources`)
- ช่วงวันที่ (สร้าง / ดำเนินการถัดไป)
- **ลีดร้อนแรง** — `lead_score >= 80` (กดการ์ดสรุปหรือชิป)

### ปุ่ม / actions (ไม่ใช่ sidebar)

| Action | Route / พฤติกรรม | สิทธิ์ | หมายเหตุ |
|--------|------------------|--------|----------|
| **+ ลีดใหม่** | `/app/leads/new` | `app.lead` create | ปุ่ม primary |
| **นำเข้า** | `/app/leads/import` | create + admin | **เมนู sidebar** + หน้า wizard CSV/Excel |
| **มอบหมาย** | bulk action บนแถวที่เลือก | manager/admin | ไม่มีหน้าแยก |
| **ตรวจลูกค้าซ้ำ** | `/app/leads/duplicates` หรือ modal | admin | ไม่ใส่ sidebar จนกว่า workflow พร้อม |

### การ์ดสรุป (summary)

ตาม [LEADS-MODULE.md](./LEADS-MODULE.md): ลีดที่ใช้งาน · ลีดร้อนแรง 80+ · มูลค่าที่เป็นไปได้

---

## ไม่ใช่ sidebar — deep link / อนาคต

Route ยังจองไว้ (placeholder `[...slug].vue`) แต่**ไม่**อยู่ใน `kutoMenu.ts`

| Route | เดิมใน figma | ที่อยู่จริง |
|-------|--------------|-------------|
| `/app/leads/new` | เมนูย่อย | ปุ่มสร้าง |
| `/app/leads/kanban` | เมนูย่อย | สลับมุมมองในหน้า |
| `/app/leads/assignment` | เมนูย่อย | bulk action |
| `/app/leads/scoring` | เมนูย่อย | คอลัมน์ score + filter hot |
| `/app/leads/sources` | เมนูย่อย | filter หน้ารายการ · master → `/app/settings/master-data/lead-source` |
| `/app/leads/duplicates` | เมนูย่อย | ปุ่ม/แจ้งเตือน → หน้า dedup เมื่อพร้อม |
| `/app/leads/converted` | เมนูย่อย | แท็บในหน้ารายการ |

> `/app/leads/import` อยู่ใน sidebar แล้ว — ไม่อยู่ตารางนี้

---

## สิ่งที่เอาออกจาก sidebar (และเหตุผล)

| รายการ | เหตุผล |
|--------|--------|
| การมอบหมาย | bulk action บนรายการ ไม่ใช่พื้นที่ทำงานประจำ |
| ลูกค้าซ้ำ | workflow พิเศษ · เปิดจากปุ่ม/notification ก่อนคืน sidebar |

---

## Implement ถัดไป (KuTo)

1. `pages/app/leads/index.vue` — port pattern จาก `frontend/app/pages/app/leads/`
2. `/app/leads/inbox` — หน้าเดียวกับ index + query `?view=inbox` หรือแชร์ component + preset filter
3. i18n key ใหม่ `kuto.leads.*` เมื่อเริ่มหน้าจริง
4. `/app/leads/import` — wizard CSV/Excel · มีเมนู sidebar แล้ว
5. Dedup — ทำหลัง v1 list ship

---

## Sync

แก้ sidebar Leads → อัปเดต `kutoMenu.ts` + ไฟล์นี้ + `KUTO-MENU-PAGE-MATRIX.md` + CHANGELOG
