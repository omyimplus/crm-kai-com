# 03 — Auth

Authentication & Authorization

> **🔴 ใช้ตอนนี้ (Phase 1–2):** อ่านส่วน "Phase 1–2" ด้านล่าง  
> **⚪ อนาคต (Phase 3+):** ส่วน "Auth กลางที่ Control DB"  
> Flow Phase 1 → [phase1-only.md](../09-flows/phase1-only.md)

## สถานะปัจจุบัน

| รายการ | สถานะ |
|--------|--------|
| Phase | 1 |
| Implement แล้ว | ✅ login email + username (RPC) |
| โหมด | Supabase Auth + profiles.org_id |
| Multi-org | ❌ Phase 1: 1 user = 1 org |

---

## 🔴 Phase 1–2 (ใช้ตอนนี้)

- Login และ CRM อยู่ **Supabase project เดียว**
- `profiles.org_id` เชื่อม user กับ org — **ไม่มี** `organization_members`
- `profiles.role` — owner | admin | employee
- `profiles.username` — unique ต่อ org; ใช้ login แทน email ได้ (ผ่าน `resolve_login_email`)
- ดู [permissions.md](../06-crm-schema/permissions.md) สำหรับ role × table

### Login (หน้า `/login`)

| วิธี | ตัวอย่าง | หมายเหตุ |
|------|---------|----------|
| Email | `browser-test-owner@crm-kai.test` | Supabase Auth โดยตรง |
| Username | `tester1` | RPC แปลงเป็น email ก่อน sign in |

**บัญชีทดสอบ:** [TEST-ACCOUNTS.md](../11-dev-setup/TEST-ACCOUNTS.md)

**Migration:** `20260608120017_resolve_login_email.sql`

---

## ⚪ Phase 3+ (อนาคต): Auth กลางที่ Control DB

```
Login     → Control DB (auth.users)
Org list  → Control DB (organization_members)
CRM data  → Tenant DB ของ org ที่เลือก
```

1. User login ที่ Control Supabase Auth
2. API คืน org ที่ user เป็นสมาชิก
3. User เลือก org → API ตรวจ subscription + สิทธิ์
4. API คืน tenant config (URL + anon key)
5. Frontend สร้าง Supabase client ของ tenant → CRM

---

## Roles

| Role | สิทธิ์ |
|------|--------|
| owner | ทุกอย่าง + billing + ลบ org |
| admin | user, settings, CRM เต็ม |
| sales | CRUD ที่ assign / ของตัวเอง |
| readonly | อ่านอย่างเดียว |

---

## ไฟล์ในโฟลเดอร์นี้

| ไฟล์ | อ่านเมื่อ |
|------|-----------|
| [README.md](./README.md) | auth overview |
| [CHANGELOG.md](./CHANGELOG.md) | เปลี่ยนอะไรล่าสุด |

## เอกสารที่เกี่ยวข้อง

- [06-crm-schema/permissions.md](../06-crm-schema/permissions.md)
- [09-flows/phase1-only.md](../09-flows/phase1-only.md)
- [00-overview/DECISIONS.md](../00-overview/DECISIONS.md) — D-004

## ดูการเปลี่ยนแปลงล่าสุด

→ [CHANGELOG.md](./CHANGELOG.md)
