# Node.js Version — ทั้งระบบ

> **บังคับ:** ใช้ Node **22 LTS** (minimum **22.12.0**) ทุก package ใน repo นี้  
> **ADR:** [D-011](../00-overview/DECISIONS.md)

---

## สรุป

| Package | Path | `engines.node` |
|---------|------|----------------|
| **Monorepo (root)** | [`.nvmrc`](../../.nvmrc) | `22` |
| **Frontend** | `frontend/package.json` | `>=22.12.0` |
| **API** | `api/package.json` | `>=22.12.0` |

---

## ทำไม Node 22

- **Nuxt 4** ต้องการ Node `^22.12.0 || ^24.11.0 || >=26.0.0`
- **API (Phase 3+)** ใช้ runtime เดียวกับ frontend — ลดความสับสนใน CI และ local dev
- Node 20 ยังรันได้บางส่วน แต่ **ไม่รองรับอย่างเป็นทางการ** — build อาจ warning/fail

---

## Setup local

```bash
# ติดตั้ง Node 22 (ตัวอย่าง nvm)
nvm install 22
cd /path/to/crm-kai-com
nvm use          # อ่านจาก .nvmrc
node -v          # v22.12.0 ขึ้นไป
```

### ตรวจทุก package

```bash
cd frontend && node -v && npm run build
cd ../api && node -v && npm run typecheck
```

---

## CI / Deploy (อนาคต)

- GitHub Actions: `node-version: '22'`
- Docker API image: `FROM node:22-alpine`
- **ห้าม** ใช้ Node 18 หรือ 20 ใน pipeline ใหม่

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
