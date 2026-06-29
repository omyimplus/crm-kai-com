# KuTo — Customers Information Architecture

> **สถานะ:** ✅ list hub mock · C360 ยังไม่ mock · **IA ตัดสินแล้ว**  
> **รวมผู้ติดต่อ:** [KUTO-CONTACTS-IA.md](./KUTO-CONTACTS-IA.md)  
> **Legacy spec:** [CUSTOMER-360-FUNCTIONAL-SPEC.md](../07-phases/CUSTOMER-360-FUNCTIONAL-SPEC.md) · **เมนู matrix:** [KUTO-MENU-PAGE-MATRIX.md](./KUTO-MENU-PAGE-MATRIX.md)  
> **Config:** `frontend-kuto/app/config/kutoMenu.ts`

---

## หลักการ

Figma Make แยก Customers เป็น 8 เมนูย่อย — ส่วนใหญ่เป็น **แท็บใน Customer 360** หรือ **deep link** ไม่ใช่พื้นที่ทำงานแยก

**ผู้ติดต่อ** รวมเข้าโมดูลลูกค้าแล้ว — ไม่มี sidebar ผู้ติดต่อ · ประวัติการติดต่ออยู่ใน C360 (แท็บกิจกรรม + แผงรายบุคคล)

KuTo ยุบให้สอดคล้อง Leads: **hub หนึ่งหน้า** + **นำเข้า** ใน sidebar · C360 = `/app/customers/:id`

---

## Sidebar (4 รายการ)

| ลำดับ | Label (TH) | Route | Icon | หมายเหตุ |
|-------|------------|-------|------|----------|
| 1 | รายชื่อลูกค้า | `/app/customers` | `list` | Hub หลัก · parent link ชี้ที่นี่ |
| 2 | รายชื่อผู้ติดต่อ | `/app/customers/contacts` | `users` | รายการผู้ติดต่อทั้ง org · filter ตามลูกค้า |
| 3 | ประวัติการติดต่อ | `/app/customers/contact-history` | `history` | Timeline โทร/นัด/อีเมลทั้ง org — **เช็คง่ายรายวัน** |
| 4 | นำเข้าข้อมูลลูกค้า | `/app/customers/import` | `upload` | CSV / Excel · รวม sheet ผู้ติดต่อได้ |

### หน้า `/app/customers/contact-history` (✅ mock KuTo)

**ไฟล์:** `KutoContactHistoryPage.vue` · `kutoContactHistoryMock.ts` · `pages/app/customers/contact-history/index.vue`

**UI ตาม figma (ไม่ใช่ตาราง+แผงขวา):**

- Filter แถวบน · แท็บประเภทกิจกรรม (โทร/อีเมล/นัด/LINE/…) · **Timeline feed** จัดกลุ่มตามวัน
- การ์ดกิจกรรม: ไอคอน · หัวข้อ · badge สถานะ · ผู้ติดต่อ · ลูกค้า · วันเวลา · Owner · OPP/TK
- สลับ **โหมดตาราง** ได้ · คลิกการ์ด → แถบล่างเปิด C360 / ผู้ติดต่อ
- ลิงก์ **ดูงานของฉัน** → `/app/activities`

---

## ในหน้า `/app/customers` (✅ mock KuTo)

**ไฟล์:** `KutoCustomersListPage.vue` · `kutoCustomersListMock.ts` · `pages/app/customers/index.vue`

### แท็บสถานะ (tabs)

| แท็บ UI | ความหมาย | หมายเหตุ |
|---------|----------|----------|
| **สถานะ: เป้าหมาย** | `companies.status = prospect` | ลูกค้าใน master แล้ว ยังไม่ active — **ไม่ใช่** ลีดในโมดูล ลูกค้าเป้าหมาย |
| ใช้งานอยู่ / ไม่ใช้งาน / … | status อื่น ๆ | ตาม `CUSTOMER-MASTER-FIELDS.md` |

### ตัวกรอง (filters)

- ค้นหา (ชื่อบริษัท · รหัส · Tax ID · โทร)
- ระดับลูกค้า (tier) · ประเภทธุรกิจ · owner
- สถานะ (active / archived)

### ปุ่ม / actions (ไม่ใช่ sidebar)

| Action | Route / พฤติกรรม | หมายเหตุ |
|--------|------------------|----------|
| **+ ลูกค้าใหม่** | `/app/customers/new` | ปุ่ม primary |
| **นำเข้า** | `/app/customers/import` | sidebar + ปุ่มใน hub |
| **ตรวจลูกค้าซ้ำ** | `/app/customers/duplicates` | ปุ่ม/แจ้งเตือน |
| **+ ผู้ติดต่อ** | จาก hub ผู้ติดต่อ หรือ C360 | เลือกลูกค้าก่อนสร้าง |

---

## Customer 360 — `/app/customers/:id`

แทนเมนู figma **มุมมอง 360** + **ผู้ติดต่อทั้งกลุ่ม** · เปิดจากแถวในตาราง hub

แท็บตาม [CUSTOMER-360-FUNCTIONAL-SPEC.md](../07-phases/CUSTOMER-360-FUNCTIONAL-SPEC.md) (ทยอย implement):

| แท็บ | แทนเมนู figma / contacts |
|------|--------------------------|
| Overview | มุมมอง 360 · ผู้ติดต่อหลัก · กิจกรรมล่าสุด 3–5 รายการ |
| Company & สาขา | สาขา |
| Accounts | บัญชีลูกค้า |
| **Contacts** | รายชื่อผู้ติดต่อ · role filter · **+ ผู้ติดต่อ** · แผง **ประวัติรายบุคคล** |
| Opportunities | โอกาสที่ผูกบริษัท |
| Documents | เอกสารลูกค้า (+ `/app/documents?customer=`) |
| **Activities** | ประวัติระดับลูกค้า (รายละเอียด) · snippet ใน Overview · ลิงก์ไป sidebar **ประวัติการติดต่อ** |
| Contracts / Assets / Tickets | ตาม phase |

รายละเอียดผู้ติดต่อ + ประวัติ: [KUTO-CONTACTS-IA.md](./KUTO-CONTACTS-IA.md)

---

## ไม่ใช่ sidebar — deep link / อนาคต

Route ยังจองไว้ (placeholder `[...slug].vue`) แต่**ไม่**อยู่ใน `kutoMenu.ts`

| Route | เดิมใน figma | ที่อยู่จริง |
|-------|--------------|-------------|
| `/app/customers/360` | เมนูย่อย | ใช้ `/app/customers/:id` |
| `/app/customers/accounts` | เมนูย่อย | แท็บ Accounts ใน C360 |
| `/app/customers/documents` | เมนูย่อย | แท็บ Documents · `/app/documents` |
| `/app/customers/branches` | เมนูย่อย | แท็บ Company ใน C360 |
| `/app/customers/duplicates` | เมนูย่อย | ปุ่มใน hub |
| `/app/customers/activity-schedule` | เมนูย่อย | sidebar **ประวัติการติดต่อ** + แท็บ Activities ใน C360 |
| `/app/contacts/*` | โมดูลผู้ติดต่อ 10 เมนู | ดู [KUTO-CONTACTS-IA.md](./KUTO-CONTACTS-IA.md) |

> `/app/customers/import` อยู่ใน sidebar แล้ว — ไม่อยู่ตารางนี้

---

## สิ่งที่เอาออกจาก sidebar (และเหตุผล)

| รายการ | เหตุผล |
|--------|--------|
| มุมมอง 360 | หน้ารายละเอียดต่อ record |
| บัญชี / เอกสาร / สาขา | ข้อมูลย่อยใน C360 |
| ลูกค้าซ้ำ | workflow พิเศษ |
| โมดูลผู้ติดต่อ (top-level) | รวมใน C360 — ดู KUTO-CONTACTS-IA |
| ประวัติการติดต่อ (เมนูแยก top-level) | อยู่ใน sidebar ลูกค้า `/app/customers/contact-history` |

---

## ห้ามยุบข้ามโมดูล

| คู่ | เหตุผล |
|-----|--------|
| Leads import ↔ Customers import | คนละ entity · validation |
| Leads ซ้ำ ↔ Customers ซ้ำ | ซ้ำระดับ lead vs company/tax_id |
| เอกสารลูกค้า ↔ `/app/documents` | แสดงใน C360 · storage รวมที่โมดูลเอกสาร |
| กิจกรรมลูกค้า ↔ `/app/activities` | sidebar ประวัติ = ดู log ข้ามลูกค้า · โมดูลกิจกรรม = คิวงาน/ปฏิทินของฉัน |
| `contacts` table ↔ `companies` | entity แยกใน DB · UI รวมใน C360 |

---

## Implement ถัดไป (KuTo)

1. ~~`pages/app/customers/index.vue` — hub mock~~ ✅
2. `pages/app/customers/[id].vue` — C360 shell · Overview + Contacts + Activities ก่อน
3. `pages/app/customers/import.vue` — wizard (รวม contacts)
4. Dedup + new — deep link หลัง hub ship

---

## Sync

แก้ sidebar / C360 ลูกค้า → อัปเดต `kutoMenu.ts` + ไฟล์นี้ + `KUTO-CONTACTS-IA.md` + `KUTO-MENU-PAGE-MATRIX.md` + CHANGELOG
