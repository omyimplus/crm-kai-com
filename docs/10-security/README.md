# 10 — Security

Checklist และกฎความปลอดภัย — **ไม่ negotiable**

---

## Checklist

- [ ] Service role key encrypt ใน Control DB — ใช้ใน API เท่านั้น
- [ ] Frontend ใช้ **anon key** เท่านั้น
- [ ] RLS เปิดทุกตาราง CRM
- [ ] Tenant config จาก API หลัง verify member + subscription
- [ ] ห้าม client ส่ง tenant_id / org slug โดยไม่ verify
- [ ] Rate limit `/register` และ provision
- [ ] Audit log provision / suspend (Phase 5)

## ตามชั้น

| ชั้น | กฎ |
|------|-----|
| QA ชั้น 7 | ยิง API/route **นอก Phase 1** + ทะลุ Supabase — ต้องไม่ได้ · ดู [QA-GUIDE.md](../11-dev-setup/QA-GUIDE.md#ชั้น-7--bypass--api-นอกระบบ-penetration) |
| Control DB | ไม่ expose ให้ browser; secrets ใน API only |
| Tenant DB | anon + RLS; ไม่มี service role ใน Nuxt |
| API | validate ทุก request; webhook signature verify |
| Auth | role ตรวจทั้ง RLS และ middleware |

## เอกสารที่เกี่ยวข้อง

- [IRON-RULES.md](../IRON-RULES.md) — กฎที่ 8
- [04-api](../04-api/)
- [03-auth](../03-auth/)
