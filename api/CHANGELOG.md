# Changelog — API

→ [README.md](./README.md) · Design: [docs/04-api/README.md](../docs/04-api/README.md)

---

## ประวัติ

### 2026-06-08 — create scaffold Control Plane API + Node 22

- **ทำอะไร:** โครง `api/` (Hono, routes/services/workers), health endpoint, engines Node >=22.12.0
- **ไฟล์ที่กระทบ:** `api/**`, `.nvmrc`, `docs/04-api/`, `docs/11-dev-setup/NODE-VERSION.md`
- **Phase:** 1 (scaffold only — logic Phase 3+)
- **หมายเหตุ:** ไม่ proxy CRM — Control Plane เท่านั้น
