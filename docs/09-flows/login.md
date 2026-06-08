# Login → CRM

> **🔴 Phase 1 (ใช้ตอนนี้):** อ่าน [phase1-only.md](./phase1-only.md)  
> **⚪ Phase 3+:** flow ด้านล่าง

---

## ⚪ Phase 3+ (อนาคต)

```
User → Nuxt: email + password
Nuxt → Control Auth: signIn
Nuxt → API: GET /me/orgs
API → Control DB: organization_members
API → Nuxt: org list

User เลือก org "acme"
Nuxt → API: GET /orgs/acme/config
API → Control DB: member + subscription active
API → Nuxt: { supabaseUrl, anonKey }

Nuxt → Tenant Supabase: CRM (RLS)
```

---

## 🔴 Phase 1–2 (ใช้ตอนนี้)

→ [phase1-only.md](./phase1-only.md)

---

## เอกสารที่เกี่ยวข้อง

- [03-auth](../03-auth/)
- [04-api](../04-api/) — Phase 3+ เท่านั้น
- [05-frontend](../05-frontend/)
