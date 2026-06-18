# QA Checklist — Opportunities (แปลงจากลีด)

> **ใช้คู่กับ:** [QA-GUIDE.md](./QA-GUIDE.md) (ชั้น 0–7)  
> **Module:** `/app/opportunities` · `/app/opportunities/from-lead/:leadId` · `/app/opportunities/:id`  
> **Spec:** [OPPORTUNITIES-MODULE.md](../05-frontend/OPPORTUNITIES-MODULE.md)  
> **อัปเดต:** 2026-06-18

---

## ก่อนเริ่ม

1. Apply migration `20260608120081_opportunities_module.sql` (`supabase db push` / `db reset`)
2. Login: `tester1` / `testpass123` (หรือ owner ที่มี `app.opportunity` create)
3. มีลีดที่ **ยังไม่ convert** (สถานะไม่ใช่ CONVERTED / CANCELLED / UNQUALIFIED)

---

## Flow หลัก — Convert ลีด → Opportunity

| # | ขั้นตอน | Expected | ผล |
|---|---------|----------|-----|
| 1 | เปิด `/app/leads` → เลือกลีดที่ยังไม่ convert → **ดู** | มีปุ่ม「แปลงเป็นโอกาสขาย」 | |
| 2 | กดแปลง | ไป `/app/opportunities/from-lead/:id` · ฟอร์ม prefill (ชื่อ · ลูกค้า · มูลค่า · bill to) | |
| 3 | เลือก Stage | Probability อัปเดตตาม stage | |
| 4 | กรอก Owner* · บันทึก | สร้างสำเร็จ → หน้าดู opp · มีรหัส `OPP-...` | |
| 5 | กลับดูลีดเดิม | สถานะ = **Converted** · ปุ่มเป็น「ดูโอกาสขาย」 | |
| 6 | กดแปลงลีดเดิมอีกครั้ง (URL from-lead ตรง) | redirect ไป opp ที่มีอยู่ / ไม่สร้างซ้ำ | |

---

## หน้ารายการ `/app/opportunities`

| # | ขั้นตอน | Expected | ผล |
|---|---------|----------|-----|
| 7 | เปิดรายการ | การ์ด Pipeline / ชนะช่วงนี้ / โอกาสเปิด · **ไม่มี**ปุ่ม + New | |
| 8 | ค้นหา · filter stage · ช่วงวันที่ | รายการและการ์ดสรุปเปลี่ยนตาม filter | |
| 9 | สลับ table / grid | แสดงผลถูกต้อง | |
| 10 | ดู · แก้ไข · ลบ | หน้าดู readonly · แก้ไขบันทึกได้ · soft delete | |

---

## ฟอร์มแก้ไข

| # | ขั้นตอน | Expected | ผล |
|---|---------|----------|-----|
| 11 | แก้ stage เป็น Won | status = won · การ์ด「ชนะช่วงนี้」นับมูลค่า (ช่วงวันที่ปัจจุบัน) | |
| 12 | แก้ Project / People / Bill to | บันทึกแล้วแสดงบนหน้าดู | |

---

## สิทธิ์ (ชั้น 4)

| # | ขั้นตอน | Expected | ผล |
|---|---------|----------|-----|
| 13 | user อ่านอย่างเดียว | เห็นรายการ · ไม่มีปุ่มแก้/ลบ/convert | |
| 14 | org อื่น | ไม่เห็น opp ข้าม org (RLS) | |

---

## บัคที่พบ (รอบล่าสุด)

| ชั้น | Expected | Actual | สถานะ |
|------|----------|--------|--------|
| | | | |
