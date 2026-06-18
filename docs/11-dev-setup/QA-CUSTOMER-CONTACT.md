# QA Checklist — Master Data: ลูกค้า + ผู้ติดต่อ

> **ใช้คู่กับ:** [QA-GUIDE.md](./QA-GUIDE.md) (ชั้น 0–7)  
> **Module:** `/app/customer` · `/app/contact`  
> **อัปเดต:** 2026-06-17

---

## วิธีใช้

1. อ่าน [QA-GUIDE.md](./QA-GUIDE.md) — ทำ **ชั้น 0 → 7** ตามลำดับ (ชั้น 7 หลังชั้น 2)  
2. ติ๊ก `[ ]` → `[x]` ใน checklist ด้านล่าง (แยกตามชั้น)  
3. บัคใหม่ใส่ตาราง **บัคที่พบ (รอบล่าสุด)** — ใช้รูปแบบใน QA-GUIDE

---

## ชั้น 0 — Environment

- [ ] Dev server สะอาด (ไม่มี WARN/ERROR)
- [ ] Login owner ได้
- [ ] Migration **39, 40, 41, 42, 43, 44** apply แล้ว + `NOTIFY pgrst, 'reload schema';`

---

## ชั้น 1 — Database

- [ ] RPC 10 ตัวครบ (ดู SQL ใน QA-GUIDE ชั้น 1)
- [ ] RLS: employee ไม่ SELECT แถว `deleted_at IS NOT NULL`

---

## ชั้น 2 — API

### ลูกค้า

- [ ] A1 `create_company`
- [ ] A2 `update_company`
- [ ] A3 `soft_delete_company` (ไม่มี contact)
- [ ] A4 `soft_delete_company` (มี contact → cascade)
- [ ] A5 `restore_company` (contact cascade กลับ)

### ผู้ติดต่อ

- [ ] B1 `create_contact`
- [ ] B2 `update_contact`
- [ ] B3 `soft_delete_contact`
- [ ] B4 `restore_contact` (ลูกค้า active)
- [ ] B5 สร้าง contact ชี้ลูกค้าที่ลบ → error
- [ ] B6 ตั้งผู้ติดต่อหลักคนใหม่ → คนเดิมของลูกค้าเดียวกันถูกยกเลิกอัตโนมัติ (มีได้ 1 คน)

### สิทธิ์ API

- [ ] P1 employee → `restore_company` Forbidden
- [ ] P2 employee → REST ไม่เห็น deleted rows

---

## ชั้น 3 — UI

### ลูกค้า

- [ ] U-C1 รายการ + filter
- [ ] U-C2 สร้างใหม่
- [ ] U-C3 ดู / แก้
- [ ] U-C4 ลบ (modal ยกเลิกปุ่มเดียว · แสดง error จริง)
- [ ] U-C5 Panel + modal เพิ่มผู้ติดต่อ (ไม่ select ลูกค้า)
- [ ] U-C6 แท็บ ใช้งาน/ถูกลบ (owner)
- [ ] U-C7 กู้คืนจากแท็บ ถูกลบ

### ผู้ติดต่อ

- [ ] U-T1 รายการ + filter ลูกค้า
- [ ] U-T2 CRUD ครบ
- [ ] U-T3 แท็บ ถูกลบ + restore
- [ ] U-T4 i18n th/en

---

## ชั้น 4 — Permission

- [ ] Employee **ไม่เห็น** archive tabs (customer + contact)
- [ ] Owner/admin **เห็น** archive tabs + restore ได้
- [ ] Contact ที่ลูกค้าถูกลบ — restore contact ต้องไปกู้ลูกค้าก่อน (ปุ่ม disabled + hint)

---

## ชั้น 5 — E2E

- [ ] Flow 1: ลูกค้าใหม่ → add contact จาก view → แก้ → ลบ contact อย่างเดียว
- [ ] Flow 2: ลบลูกค้า cascade → กู้คืนทั้งคู่
- [ ] Flow 3: employee vs owner archive tabs

---

## ชั้น 6 — Audit

- [ ] Log สร้าง/แก้/ลบ ลูกค้า
- [ ] Log สร้าง/แก้/ลบ ผู้ติดต่อ
- [ ] Log cascade delete contact (`metadata.cascade`)
- [ ] Log restore (`metadata.restore`)

---

## ชั้น 7 — Bypass / API นอกระบบ

- [ ] X1–X5 Node `:4000` + Nuxt `/api/*` — ไม่มี CRM route นอก `/health` · `client-info` ไม่ leak data
- [ ] X6–X9 ไม่ login / RPC ปลอม → 401 / 404 / ไม่เห็นข้อมูล
- [ ] X10 employee → `restore_company` Forbidden
- [ ] X11 employee → `admin_create_org_user` Forbidden
- [ ] X12 employee → ไม่เห็น deleted rows ผ่าน REST
- [ ] X13–X14 ข้าม org / แก้ org_id ไม่ได้
- [ ] X15–X16 ไม่รั่ว service_role ใน frontend
- [ ] X18 (optional) REST INSERT ตรง bypass audit — บันทึก finding ถ้ามี

---

## บัคที่เคยพบ (อ้างอิง — ตรวจว่ายัง reproduce ได้ไหม)

| ID | ชั้น | สถานะหลังแก้ | หมายเหตุ |
|----|------|---------------|----------|
| BUG-CC-01 | 2 | retest | migration 39 — `create_contact` 404 |
| BUG-CC-02 | 2 | retest | migration 42 — ลบลูกค้ามี contact |
| BUG-CC-03 | 3 | **แก้แล้ว** | contact delete modal แสดง error จริง |
| BUG-CC-04 | 3 | open (UX) | ลบบน list ไม่สม่ำเสมอ customer vs contact |
| BUG-CC-05 | 3 | open (info) | legacy `/app/companies` vs `/app/customer` |

---

## รายงานรอบทดสอบ (ตัวอย่าง 2026-06-17 — Agent)

> รอบเก่า — migration 39/42 ยังไม่ apply บน remote ตอนนั้น

| ชั้น | ผล | หมายเหตุ |
|------|-----|----------|
| 0 | PARTIAL | migration ไม่ครบ |
| 2 | FAIL | contact RPC 404 · cascade delete |
| 3 | PARTIAL | UI โหลดได้ · CRUD contact fail |

**หลัง apply 39–44:** รัน checklist ด้านบนใหม่แล้วอัปเดตตารางนี้

---

## เอกสารที่เกี่ยวข้อง

- [QA-GUIDE.md](./QA-GUIDE.md)
- [TEST-ACCOUNTS.md](./TEST-ACCOUNTS.md)
- [CUSTOMER-MASTER-FIELDS.md](../06-crm-schema/CUSTOMER-MASTER-FIELDS.md)
- [CONTACT-MASTER-FIELDS.md](../06-crm-schema/CONTACT-MASTER-FIELDS.md)
