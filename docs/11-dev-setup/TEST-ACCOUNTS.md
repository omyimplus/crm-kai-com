# Test Accounts — บัญชีทดสอบ (Phase 1)

> **ใช้ local dev / Supabase cloud dev เท่านั้น** — ห้ามใช้รหัสเหล่านี้ production  
> อัปเดต: 2026-06-08

---

## บัญชีหลักสำหรับทดสอบ (Browser Tester)

บัญชีนี้สร้างจาก `/signup` ครั้งแรก แล้วตั้ง **username** ใน Setup → ผู้ใช้ในระบบ

| ฟิลด์ | ค่า |
|-------|-----|
| **ชื่อแสดง** | Browser Tester |
| **Username** | `tester1` |
| **Email** | `browser-test-owner@crm-kai.test` |
| **Password** | `testpass123` |
| **ระดับองค์กร** | owner (user แรกที่ signup) |
| **Org** | Demo Corp (`demo`) |

---

## วิธี Login

**URL:** http://localhost:3000/login

### วิธีที่ 1 — Email (ใช้ได้ทันที)

| ช่อง | ค่า |
|------|-----|
| อีเมลหรือ Username | `browser-test-owner@crm-kai.test` |
| รหัสผ่าน | `testpass123` |

**ผลลัพธ์ที่คาดหวัง:** redirect → `/app` (Dashboard)

### วิธีที่ 2 — Username

| ช่อง | ค่า |
|------|-----|
| อีเมลหรือ Username | `tester1` |
| รหัสผ่าน | `testpass123` |

**ผลลัพธ์ที่คาดหวัง:** redirect → `/app` (Dashboard)

**เงื่อนไข:** ต้องรัน migration 17 บน Supabase ก่อน:

```
supabase/migrations/20260608120017_resolve_login_email.sql
```

---

## Checklist ทดสอบ (Agent / QA)

- [ ] รัน migration `20260608120017_resolve_login_email.sql` ใน SQL Editor
- [ ] Login ด้วย **email** → เข้า `/app` ได้
- [ ] Logout แล้ว login ด้วย **username `tester1`** → เข้า `/app` ได้
- [ ] Login ด้วย username ผิด → ข้อความ `Invalid email/username or password`
- [ ] หลัง login เห็นชื่อ **Browser Tester** มุมขวาบน

---

## ตรวจ username ใน DB

```sql
SELECT p.full_name, p.username, p.role, p.is_active, u.email
FROM public.profiles p
JOIN auth.users u ON u.id = p.id
WHERE lower(p.username) = 'tester1';
```

---

## ตรวจ RPC resolve email

```sql
SELECT public.resolve_login_email('tester1');
-- คาดหวัง: browser-test-owner@crm-kai.test
```

---

## แก้ error: `Database error querying schema`

เกิดกับ **ผู้ใช้ที่สร้างจาก Setup → ผู้ใช้ในระบบ** (RPC `admin_create_org_user`) — คอลัมน์ token ใน `auth.users` เป็น NULL

**รันใน SQL Editor:**

`supabase/migrations/20260608120018_fix_auth_users_admin_create.sql`

หรือแค่ backfill user ที่มีอยู่:

```sql
UPDATE auth.users
SET
  confirmation_token = COALESCE(confirmation_token, ''),
  recovery_token = COALESCE(recovery_token, ''),
  email_change_token_new = COALESCE(email_change_token_new, ''),
  email_change = COALESCE(email_change, '')
WHERE confirmation_token IS NULL
   OR recovery_token IS NULL
   OR email_change_token_new IS NULL
   OR email_change IS NULL;
```

หลังรันแล้วลอง login อีกครั้ง

---

## แก้ error: `Could not find the function public.admin_update_org_user(... p_org_role_ids ...) in the schema cache`

Frontend ใช้ **บทบาททีมหลายอัน (chip)** แล้ว — DB ยังเป็น RPC รุ่นเก่า (`p_org_role_id` ตัวเดียว)

**รันใน SQL Editor (ทั้งไฟล์):**

`supabase/migrations/20260608120019_profile_org_roles_multi.sql`

สร้างตาราง `profile_org_roles` + อัปเดต `admin_create_org_user` / `admin_update_org_user` / `list_org_users`

**ตรวจหลังรัน:**

```sql
SELECT pg_get_function_arguments(p.oid)
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname = 'admin_update_org_user';
```

คาดหวังเห็น `p_org_role_ids uuid[]` และ `p_set_org_roles boolean`

ถ้ายัง error หลังรัน SQL สำเร็จ — รอ ~1 นาที หรือรัน:

```sql
NOTIFY pgrst, 'reload schema';
```

---

## แก้ error: `list_org_roles` (Network 500 / relation profile_org_roles)

มักเกิดเมื่อ migration 19 รันไม่ครบ — function อ้าง `profile_org_roles` แต่ตารางยังไม่มี

**รันใน SQL Editor:**

`supabase/migrations/20260608120020_fix_list_org_roles.sql`

**ตรวจ:**

```sql
SELECT to_regclass('public.profile_org_roles');
-- คาดหวัง: profile_org_roles

SELECT COUNT(*) FROM public.list_org_roles();
-- ต้อง login เป็น owner/admin ใน SQL Editor (หรือทดสอบจากแอป)
```

| Status | สาเหตุที่พบบ่อย |
|--------|----------------|
| **404** | schema cache ค้าง → `NOTIFY pgrst, 'reload schema';` |
| **500** | ตาราง `profile_org_roles` ไม่มี → รัน migration 20 |
| **401** | session หมดอายุ → login ใหม่ |
| **403 / Forbidden** | user ไม่ใช่ owner/admin |

---

## เอกสารที่เกี่ยวข้อง

- [Login flow (Phase 1)](../09-flows/phase1-only.md)
- [Auth overview](../03-auth/README.md)
- [Dev setup](./README.md)
