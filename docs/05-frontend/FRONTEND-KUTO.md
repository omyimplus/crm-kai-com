# Frontend KuTo — UI track (แยกจาก legacy)

> **โฟลเดอร์:** `frontend-kuto/` · **Port:** 3001 · **Legacy:** `frontend/` (port 3000) — ห้ามทับกัน

---

## เป้าหมาย

Implement UI ตาม **Figma Make / figma.site** บน stack เดียวกับ CRM Kai (Nuxt 4 + Nuxt UI + Supabase) โดย:

- **ไม่แก้** `frontend/` เดิม
- **ไม่ใช้** SQL จาก Figma
- **ใช้** `supabase/migrations` + schema docs ของเราเมื่อต่อข้อมูลจริง

**UX reference:** [Figma Make](https://www.figma.com/make/XZYS22WiMTgEdPInRzwVJS/KC-KuTo-CRM) · https://morph-boho-25621922.figma.site/

**Gap analysis:** [CUSTOMER-360-FUNCTIONAL-SPEC.md](../07-phases/CUSTOMER-360-FUNCTIONAL-SPEC.md)

---

## สถานะ implement

| หน้า | สถานะ |
|------|--------|
| Shell (sidebar teal + header + **dropdown ย่อย**) | ✅ v0 |
| Sidebar IA ตรง figma.site | ✅ เมนู + placeholder |
| **Leads — กล่องรับเป้าหมาย** `/app/leads/inbox` | ✅ mock ตาม figma.site |
| Dashboard — แดชบอร์ดของฉัน | ✅ mock ตาม figma.site |
| Dashboard types อื่น (Sales, Executive, …) | ⏳ placeholder |
| Auth | ⏳ ถัดไป |
| โมดูล CRM + Master Data | ⏳ ทีละ sprint |

**Page inventory:** [KUTO-MENU-PAGE-MATRIX.md](./KUTO-MENU-PAGE-MATRIX.md) · **Leads IA:** [KUTO-LEADS-IA.md](./KUTO-LEADS-IA.md)

---

## รัน local

```bash
cd frontend-kuto
cp ../frontend/.env .env   # ครั้งแรก
pnpm install
pnpm dev                   # http://localhost:3001/app
```

---

## โครงสร้าง

```
frontend-kuto/app/
├── components/kuto/          → KutoSidebar, KutoHeader
├── components/kuto/dashboard/ → KutoDashboardPage
├── config/kutoMenu.ts        → nav nested + flattenKutoNav
├── config/kutoDashboardMock.ts
├── layouts/app.vue
└── pages/app/index.vue
```

---

## Sprint ถัดไป (แนะนำ)

1. Auth + layout guard (reuse pattern จาก `frontend/`)
2. Live KPI bar จาก Supabase (leads, opps, tasks)
3. Customer 360 route
4. โมดูล Leads / Opp — UI KuTo + composables จาก legacy

---

## Agent rule

`.cursor/rules/frontend-kuto.mdc` · **อ่าน** [KUTO-MENU-PAGE-MATRIX.md](./KUTO-MENU-PAGE-MATRIX.md) ก่อนแก้เมนู/route
