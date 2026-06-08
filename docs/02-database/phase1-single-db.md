# Phase 1–2: Single Supabase Project

ก่อนแยก Control / Tenant จริง — ใช้ **Supabase project เดียว**

---

## โครงสร้าง

```
Supabase 1 project
├── auth.users
├── organizations
├── profiles (org_id, role)
├── companies, contacts, deals, ... (org_id ทุกตาราง)
└── RLS: org_id = current user's org
```

## ทำไมยังมี org_id

- แยกข้อมูลหลาย org ใน DB เดียว (เตรียม multi-tenant logic)
- ย้ายไป Tenant DB ต่อ org ได้โดย export ตาม `org_id` (Phase 3)

## การเข้าถึง

| ข้อมูล | วิธี |
|--------|------|
| Login + CRM | Nuxt → Supabase ตรง (project เดียว) |
| Node API | **ยังไม่มี** |

## ข้อยกเว้นจาก IRON-RULES

กฎ "Control DB ผ่าน API" และ "Tenant DB แยก project" **ยังไม่ใช้** ใน Phase 1–2  
ใช้เอกสารนี้เป็น source of truth สำหรับ phase ปัจจุบัน

## Migration path

```
supabase/migrations/     ← CRM + organizations + profiles รวมกัน
```

เมื่อถึง Phase 3 แยกเป็น:

```
supabase/migrations/control/
supabase/migrations/tenant/
```
