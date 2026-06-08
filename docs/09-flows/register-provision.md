# Register + Provisioning

**Phase 4+** — ยังไม่ implement ก่อน Phase 4

---

```
User → Nuxt: สมัคร org
Nuxt → API: POST /register
API → Control DB: org + subscription (trialing, +90d)
API → Queue: provision job

Worker:
  → Supabase Management API: สร้าง project
  → รัน tenant migrations
  → seed pipeline + admin user
  → บันทึก tenant_projects
  → ส่ง welcome email

Nuxt → redirect เข้า CRM
```

## Provision State

```
pending → creating_project → migrating → seeding → active
                              ↓ failed → retry / manual
```

## เอกสารที่เกี่ยวข้อง

- [04-api](../04-api/)
- [02-database/control-db.md](../02-database/control-db.md)
