# Node.js Version — ทั้งระบบ

> **บังคับ:** ใช้ Node **24 LTS (Krypton)** (minimum **24.11.0**) ทุก package ใน repo นี้  
> **ADR:** [D-011](../00-overview/DECISIONS.md)

---

## สรุป

| Package | Path | `engines.node` |
|---------|------|----------------|
| **Monorepo (root)** | [`.nvmrc`](../../.nvmrc) | `24` |
| **Frontend** | `frontend/package.json` | `>=24.11.0` |
| **API** | `api/package.json` | `>=24.11.0` |

---

## ทำไม Node 24

- **Latest LTS** (Node 24.x) — ไม่ใช้ line เก่า (20/22) เป็น default ของโปรเจกต์
- **Nuxt 4** รองรับ `^22.12.0 || ^24.11.0 || >=26.0.0` — เราเลือก **24.11.0+** เป็น baseline
- **API (Phase 3+)** ใช้ runtime เดียวกับ frontend — ลดความสับสนใน CI และ local dev
- Node 24 มี native WebSocket — Supabase Realtime SSR ยังใช้ `ws` transport ตาม config โปรเจกต์ได้

---

## Setup local

```bash
# ติดตั้ง Node 24 (ตัวอย่าง nvm)
nvm install 24
cd /path/to/crm-kai-com
nvm use          # อ่านจาก .nvmrc
node -v          # v24.11.0 ขึ้นไป (แนะนำ latest 24.x เช่น v24.16.0)
```

### ตรวจทุก package

```bash
cd frontend && node -v && pnpm run typecheck
cd ../api && node -v && npm run typecheck
```

---

## CI / Deploy (อนาคต)

- GitHub Actions: `node-version: '24'`
- Docker API image: `FROM node:24-alpine`
- **ห้าม** ใช้ Node 18, 20 หรือ 22 ใน pipeline ใหม่

---

## เปลี่ยน version

1. อัปเดต `.nvmrc` + `engines` ทุก `package.json`
2. อัปเดต [DECISIONS D-011](../00-overview/DECISIONS.md)
3. บันทึก CHANGELOG ใน `docs/11-dev-setup/`

---

## เอกสารที่เกี่ยวข้อง

- [11-dev-setup/README.md](./README.md)
- [api/README.md](../../api/README.md)
- [08-repo-structure/README.md](../08-repo-structure/README.md)
