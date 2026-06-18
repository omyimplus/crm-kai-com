# CRM Kai — Control Plane API (scaffold)

> **⚪ Phase 3+** — โฟลเดอร์นี้เป็น **โครง scaffold** เท่านั้น ยังไม่ implement business logic  
> ออกแบบเต็ม → [docs/04-api/README.md](../docs/04-api/README.md)

---

## Node.js version

| รายการ | ค่า |
|--------|-----|
| **Node (ทั้งระบบ)** | **>= 24.11.0** (LTS line 24) |
| **Source of truth** | [`.nvmrc`](../.nvmrc) ที่ root repo |
| **บังคับใน package** | `"engines": { "node": ">=24.11.0" }` ใน `api/package.json` และ `frontend/package.json` |

```bash
# ที่ root repo
nvm use
node -v   # ควรได้ v24.11.0 ขึ้นไป
```

→ รายละเอียด: [docs/11-dev-setup/NODE-VERSION.md](../docs/11-dev-setup/NODE-VERSION.md)

---

## โครงสร้าง (Phase 3+)

```
api/
├── src/
│   ├── index.ts          # entry — Hono + @hono/node-server
│   ├── routes/           # HTTP routes (register, org config, webhooks)
│   ├── services/         # Control DB, provision, billing
│   └── workers/          # queue jobs (BullMQ / Inngest — Phase 3+)
├── package.json
├── tsconfig.json
└── .env.example
```

**ห้ามใน Phase 1–2:** implement register, provision, proxy CRM — ดู [IRON-RULES](../docs/IRON-RULES.md)

---

## รัน local (scaffold)

```bash
cd api
cp .env.example .env
npm install
npm run dev
```

- Health: `GET http://localhost:4000/health`
- Default port: **4000**

---

## Tech (เมื่อ implement Phase 3+)

- **Runtime:** Node.js 24 LTS
- **Framework:** Hono (หรือ Fastify — ดู [01-tech-stack](../docs/01-tech-stack/README.md))
- **Language:** TypeScript

## ดูการเปลี่ยนแปลงล่าสุด

→ [CHANGELOG.md](./CHANGELOG.md)
