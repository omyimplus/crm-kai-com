# Flows — Phase 1 Only (ใช้ตอนนี้)

> **Phase ปัจจุบัน** — อ่านไฟล์นี้ก่อน `login.md` ถ้าไม่แน่ใจ  
> Phase 3+ → [login.md](./login.md) (ส่วนล่าง)

---

## Architecture Phase 1

```
┌─────────────────────────────────────┐
│     Supabase 1 project              │
│  auth.users → profiles → org_id     │
│  organizations + CRM tables         │
│  RLS ตาม org_id                     │
└─────────────────────────────────────┘
         ↑
    Nuxt (anon key + JWT)
```

---

## Login → CRM

```
User → /login (กรอก email หรือ username + password)
Nuxt → ถ้าไม่มี @ → RPC resolve_login_email(username) → email
Nuxt → Supabase Auth: signInWithPassword(email, password)
Nuxt → SELECT profiles WHERE id = auth.uid()
      → ได้ org_id, role
Nuxt → redirect /app
CRM queries → Supabase client + RLS (org_id)
```

**บัญชีทดสอบ:** [TEST-ACCOUNTS.md](../11-dev-setup/TEST-ACCOUNTS.md) — `tester1` / `testpass123`

---

## สร้าง record CRM

```
User → /app/contacts/new
Nuxt → INSERT contacts (org_id จาก profile, created_by = uid)
RLS → ตรวจ org_id ตรงกับ current_org_id()
```

---

## สิ่งที่ **ไม่มี** ใน Phase 1

- ❌ เลือก org หลาย org
- ❌ Node API
- ❌ Tenant config endpoint
- ❌ Register / provision

---

## เอกสารที่เกี่ยวข้อง

- [../03-auth/README.md](../03-auth/README.md)
- [../02-database/phase1-single-db.md](../02-database/phase1-single-db.md)
- [../07-phases/PHASE-1-CHECKLIST.md](../07-phases/PHASE-1-CHECKLIST.md)
