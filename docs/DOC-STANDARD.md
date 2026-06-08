# มาตรฐานการเขียนเอกสาร (Doc Standard)

> ทุกไฟล์ `.md` ในโปรเจกต์ต้องทำให้ **เปิด Cursor ใหม่แล้วเข้าใจได้ทันที** โดยไม่ต้องถามคนที่สร้าง

---

## หลัก 3 ข้อ (จาก IRON-RULES)

1. **สร้าง / แก้ / ลบ อะไรก็ตาม** → บันทึกใน `CHANGELOG.md` ของโฟลเดอร์นั้น
2. **สร้าง / แก้ / ลบ DB** → บันทึกใน `docs/02-database/DB-CHANGELOG.md` + อัปเดต `DB-SCHEMA.md`
3. **สร้าง / แก้ / ลบ ข้อมูลในระบบ** → เขียน `data_change_logs` ทุกครั้ง (IRON-RULES §13)
4. **ทุก md** → เขียนให้ onboard ได้เอง (มีบริบท, สถานะปัจจุบัน, ขั้นถัดไป)

---

## โครงสร้างไฟล์ต่อโฟลเดอร์

```
docs/XX-name/
├── README.md       ← ออกแบบ / สถานะปัจจุบัน (living doc)
├── CHANGELOG.md    ← บันทึกทุก action create/update/delete
└── (ไฟล์อื่น)      ← รายละเอียดเฉพาะเรื่อง
```

### DB แยกชัด (โฟลเดอร์ `02-database/`)

```
docs/02-database/
├── README.md
├── DB-CHANGELOG.md   ← 🔴 บันทึก DB ทุกครั้ง (สร้าง/แก้/ลบ)
├── DB-SCHEMA.md      ← 🔴 snapshot schema ปัจจุบัน (อัปเดตทุกครั้งที่ DB เปลี่ยน)
├── control-db.md
├── tenant-db.md
└── phase1-single-db.md
```

เมื่อมี code แล้ว ให้ mirror ใน `supabase/DB-README.md` (ชี้มาที่ docs + migration path)

---

## Template: CHANGELOG entry

ทุก entry ต้องมีครบ — Agent **ห้าม** ข้าม

```markdown
### YYYY-MM-DD — [create|update|delete] หัวข้อสั้น

- **ทำอะไร:** อธิบาย 1–3 ประโยค
- **ไฟล์ที่กระทบ:** path/to/file
- **เหตุผล:** ทำไมถึงเปลี่ยน
- **Phase:** 1
- **ผลกระทบ:** ส่วนอื่นที่ต้องรู้ / breaking change
```

เรียง **ใหม่สุดอยู่บน** ใต้หัวข้อ `## ประวัติ`

---

## Template: DB-CHANGELOG entry

```markdown
### YYYY-MM-DD — [create|update|delete] ชื่อ migration / ตาราง

- **ประเภท:** migration | seed | RLS | function | index | drop
- **ตารางที่กระทบ:** organizations, profiles, ...
- **Migration file:** `supabase/migrations/20260608_xxx.sql` (ถ้ามี)
- **SQL สรุป:** ADD COLUMN ... / CREATE TABLE ...
- **Rollback:** วิธีย้อน (ถ้ามี)
- **Phase:** 1
- **อัปเดต DB-SCHEMA.md:** ใช่
```

หลังเขียน DB-CHANGELOG **ต้อง** sync `DB-SCHEMA.md` ให้ตรงกับ schema จริง

---

## Template: README / เอกสารออกแบบ

ทุก README ควรมีหัวข้อเหล่านี้ (ตัดส่วนที่ไม่เกี่ยวได้):

```markdown
# ชื่อระบบ

## สถานะปัจจุบัน
Phase X — สรุป 1–2 ประโยคว่าทำถึงไหนแล้ว

## โปรเจกต์นี้คืออะไร (บริบทสั้น)
...

## สถาปัตยกรรม / โครงสร้าง
...

## ไฟล์ในโฟลเดอร์นี้
| ไฟล์ | อ่านเมื่อ |

## เอกสารที่เกี่ยวข้อง
ลิงก์โฟลเดอร์อื่น

## ดูการเปลี่ยนแปลงล่าสุด
→ [CHANGELOG.md](./CHANGELOG.md)
```

---

## CHANGELOG — เขียนที่ไหนเมื่อไหร่

| สถานการณ์ | บันทึกที่ |
|-----------|----------|
| แก้ docs ในโฟลเดอร์เดียว | `docs/XX/CHANGELOG.md` ของโฟลเดอร์นั้น |
| แก้หลายโฟลเดอร์ docs | CHANGELOG ทุกโฟลเดอร์ที่กระทบ + `docs/CHANGELOG.md` |
| แก้ code `frontend/` | `frontend/CHANGELOG.md` + docs ที่เกี่ยวข้อง |
| แก้ migration / DB | `docs/02-database/DB-CHANGELOG.md` + `DB-SCHEMA.md` + `02-database/CHANGELOG.md` |
| milestone / phase เปลี่ยน | `00-overview/PROJECT-STATUS.md` + `07-phases/CHANGELOG.md` |
| ตัดสินใจ architecture ใหม่ | `00-overview/DECISIONS.md` |

---

## Onboarding path (เปิด Cursor ครั้งแรก)

1. [00-overview/ONBOARDING.md](./00-overview/ONBOARDING.md)
2. [00-overview/PROJECT-STATUS.md](./00-overview/PROJECT-STATUS.md)
3. [IRON-RULES.md](./IRON-RULES.md)
4. [00-overview/DECISIONS.md](./00-overview/DECISIONS.md)
5. [07-phases/PHASE-1-CHECKLIST.md](./07-phases/PHASE-1-CHECKLIST.md)
6. โฟลเดอร์ตามงาน + CHANGELOG + DB docs ถ้าเกี่ยวข้อง

---

## Code folders (เมื่อมีแล้ว)

| โฟลเดอร์ code | CHANGELOG | DB doc |
|---------------|-----------|--------|
| `frontend/` | `frontend/CHANGELOG.md` | — |
| `api/` | `api/CHANGELOG.md` | — |
| `supabase/` | ชี้ไป `docs/02-database/DB-CHANGELOG.md` | `supabase/DB-README.md` |

การเปลี่ยน code **ต้อง** มี entry ใน CHANGELOG ของโฟลเดอร์ code **และ** docs ที่เกี่ยวข้อง
