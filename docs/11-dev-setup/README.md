# 11 — Dev Setup (Local Development)

> **สถานะ:** ✅ มี code — ดู [frontend/README.md](../../frontend/README.md)
> Phase ปัจจุบัน: **1**

---

## Prerequisites

| Tool | Version |
|------|---------|
| Node.js | **24 LTS** (>= 24.11.0) — [NODE-VERSION.md](./NODE-VERSION.md) · root [`.nvmrc`](../../.nvmrc) |
| pnpm | 9+ (หรือ npm) |
| Docker | สำหรับ Supabase local |
| Supabase CLI | latest |

```bash
# ที่ root — ใช้ Node 24
nvm use
node -v

npm install -g supabase
```

---

## โครง repo (หลัง scaffold)

```
crm-kai-com/
├── .nvmrc          # Node 24
├── frontend/       # npm run dev → localhost:3000
├── api/            # npm run dev → localhost:4000 (scaffold)
├── supabase/       # supabase start
└── docs/
```

---

## Local Supabase

```bash
cd supabase   # หรือ root ถ้า config อยู่ root
supabase start
supabase status   # copy API URL, anon key
```

---

## Environment variables

### `frontend/.env` (ไม่ใช่ `.env.example`)

Nuxt อ่าน **`.env` เท่านั้น** — `.env.example` เป็นแค่ template

```bash
cd frontend
cp .env.example .env
# แก้ค่าจาก Supabase Dashboard → Settings → API Keys
```

```env
NUXT_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co
NUXT_PUBLIC_SUPABASE_KEY=sb_publishable_xxxx
```

> ใช้ **Publishable key** (`sb_publishable_...`) — ชื่อ env ใหม่ของ `@nuxtjs/supabase` v1  
> Legacy `NUXT_PUBLIC_SUPABASE_ANON_KEY` ยังใช้ได้ แต่แนะนำ `NUXT_PUBLIC_SUPABASE_KEY`

> **ห้าม** commit ค่าจริงใน `.env.example` · **ห้าม** ใส่ secret/service role key ใน frontend

---

## บัญชีทดสอบ

→ [TEST-ACCOUNTS.md](./TEST-ACCOUNTS.md) — บัญชีทดสอบ  
→ **[QA-GUIDE.md](./QA-GUIDE.md)** — คู่มือทดสอบ **ชั้น 0–7** (อ่านก่อน) · ชั้น 7 = ยิงทะลุ API นอกระบบ  
→ [QA-CUSTOMER-CONTACT.md](./QA-CUSTOMER-CONTACT.md) — checklist ลูกค้า + ผู้ติดต่อ  
→ [QA-LEADS.md](./QA-LEADS.md) — checklist สร้างลีด (ลูกค้าเก่า + ลูกค้าใหม่)  
→ [QA-OPPORTUNITIES.md](./QA-OPPORTUNITIES.md) — checklist แปลงลีด → โอกาสขาย  
→ **กู้คืน:** แท็บ ใช้งาน/ถูกลบ บน `/app/customer` และ `/app/contact` (migration 43–44)

---

## รัน Frontend (หลัง scaffold)

```bash
cd frontend
pnpm install
pnpm dev
```

### macOS: `connect ENOENT ... nuxt-vite-node-*.sock`

Nuxt **4.4.7** บน macOS อาจ crash เพราะ path socket ใน `/var/folders/.../T/` ยาวเกิน limit — ดู [nuxt#35258](https://github.com/nuxt/nuxt/issues/35258)

**แก้:** ใช้ Node 24 + script `dev` ใน `frontend/package.json` ตั้ง `TMPDIR=/tmp` แล้ว:

```bash
nvm use
cd frontend && rm -rf .nuxt node_modules/.cache/nuxt && npm run dev
```

---

## Migration workflow

```bash
# สร้าง migration ใหม่
supabase migration new create_crm_schema

# แก้ SQL ตาม docs/06-crm-schema/tables.md

# apply local
supabase db reset

# บันทึก docs
# → docs/02-database/DB-CHANGELOG.md
# → docs/02-database/DB-SCHEMA.md
```

**Naming:** `YYYYMMDDHHMMSS_description.sql` (Supabase default)

---

## ก่อน commit

- [ ] CHANGELOG โฟลเดอร์ที่แก้
- [ ] DB-CHANGELOG + DB-SCHEMA ถ้าแตะ migration
- [ ] อัปเดต PROJECT-STATUS ถ้า milestone เปลี่ยน

---

## เอกสารที่เกี่ยวข้อง

- [../07-phases/PHASE-1-CHECKLIST.md](../07-phases/PHASE-1-CHECKLIST.md)
- [../06-crm-schema/tables.md](../06-crm-schema/tables.md)
- [CHANGELOG.md](./CHANGELOG.md)
