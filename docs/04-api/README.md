# 04 — API (Control Plane)

> **⚪ Phase 3+** — business logic ยังไม่ implement  
> **Scaffold:** มี `api/` แล้ว (health only) — ดู [api/README.md](../../api/README.md)

Node.js API — **ไม่ proxy CRM**

## สถานะปัจจุบัน

| รายการ | สถานะ |
|--------|--------|
| Phase | 1 |
| `api/` folder | ✅ **scaffold** (Hono + `/health`) |
| Node version | **>= 24.11.0** — [NODE-VERSION.md](../11-dev-setup/NODE-VERSION.md) |
| Implement endpoints | Phase 3+ |

---

## โครง code (`api/`)

```
api/
├── src/
│   ├── index.ts
│   ├── routes/       # HTTP
│   ├── services/     # Control DB, provision
│   └── workers/      # queue jobs
├── package.json
└── README.md
```

```bash
cd api && npm install && npm run dev
# GET http://localhost:4000/health
```

---

## บทบาท (Phase 3+)

- Control DB (service role)
- register, trial, billing webhook
- provision tenant
- คืน tenant config หลัง verify

→ รายละเอียด endpoints ด้านล่างใช้ **เมื่อถึง Phase 3**

---

## User-facing Endpoints (Phase 3+)

| Method | Path | หน้าที่ |
|--------|------|---------|
| POST | `/register` | Phase 4 |
| GET | `/me/orgs` | org ของ user |
| GET | `/orgs/:slug/config` | tenant URL + anon key |
| GET | `/orgs/:slug/subscription` | trial / plan |

## Internal / Admin (Phase 3+)

| Method | Path | หน้าที่ |
|--------|------|---------|
| POST | `/webhooks/stripe` | Phase 5 |
| POST | `/internal/provision/:orgId` | สร้าง tenant |
| GET | `/admin/orgs` | ops console |

---

## ดูการเปลี่ยนแปลงล่าสุด

→ [CHANGELOG.md](./CHANGELOG.md)
