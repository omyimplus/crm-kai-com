# 05 — Frontend (Nuxt)

Nuxt 3 + Tailwind + Nuxt UI — landing + CRM ใน project เดียว

> **🔴 Phase 1:** routes `/login`, `/app/**` เท่านั้น — ยังไม่มี `/`, `/register`  
> **⚪ Phase 4+:** landing + register

## สถานะปัจจุบัน

| รายการ | สถานะ |
|--------|--------|
| Phase | 1 |
| `frontend/` | ❌ ยังไม่ scaffold |
| UI library | **Nuxt UI** ([DECISIONS D-006](../00-overview/DECISIONS.md)) |
| ต่อ DB | Supabase ตรง (anon + RLS) |
| i18n | **ไทย + English** — [12-i18n](../12-i18n/README.md) ([D-009](../00-overview/DECISIONS.md)) |
| Typography | **Noto Sans Thai (default ทั้งระบบ)** — [TYPOGRAPHY.md](../12-i18n/TYPOGRAPHY.md) ([D-010](../00-overview/DECISIONS.md)) |
| Logo | [BRAND-ASSETS.md](./BRAND-ASSETS.md) — `public/images/logo/` |

---

## 🔴 Routes ใช้ตอนนี้ (Phase 1)

```
/login               → Login
/app                 → Dashboard (Coming soon)
/app/tasks
/app/leads
/app/opportunities
/app/quotations
/app/pipeline
/app/sales-orders
/app/invoices
/app/reports
/app/projects
/app/contract-agreements
/app/service         → ทุกหน้า Coming soon — ดู [APP-MENU.md](./APP-MENU.md)
```

```
/app/master-data/**  → [MASTER-DATA-MENU.md](./MASTER-DATA-MENU.md)
/app/setup/**        → [SETUP-MENU.md](./SETUP-MENU.md)
```

**Legacy (ยังเข้า URL ได้ แต่ไม่อยู่ใน sidebar):** `/app/contacts` · `/app/companies` · `/app/deals`

## ⚪ Routes อนาคต

```
/                    → Landing (Phase 4+)
/register            → สมัคร org (Phase 4+)
```

---

## การเชื่อม Database

| Phase | CRM Data | Control Data |
|-------|----------|--------------|
| **1–2 (ตอนนี้)** | Supabase ตรง | Supabase ตรง (same project) |
| 3+ | Tenant Supabase ตรง | Node API |

---

## i18n (บังคับ)

- Locale files: `frontend/i18n/locales/{th,en}.json`
- สลับภาษา: `LocaleSwitcher` บน login/signup + sidebar CRM
- ฟอนต์: [TYPOGRAPHY.md](../12-i18n/TYPOGRAPHY.md)
- รายละเอียด + checklist: [12-i18n/README.md](../12-i18n/README.md)

---

## โครงสร้างโฟลเดอร์ (แผน)

```
frontend/
├── public/images/logo/   ← logo-kai-com-crm.webp, logo-kai-com-crm-icon.webp
├── i18n/locales/       ← th.json, en.json
├── pages/
│   ├── login.vue
│   └── app/
├── components/
│   ├── crm/
│   ├── LocaleSwitcher.vue
│   └── layout/
├── composables/
│   ├── useContacts.ts
│   ├── useDeals.ts
│   └── useFormat.ts
├── middleware/
└── types/
```

---

## App menu (sidebar หลัก)

- [APP-MENU.md](./APP-MENU.md) — 12 หน้า CRM (Coming soon scaffold)

## Master data + Setup (sidebar)

- [MASTER-DATA-MENU.md](./MASTER-DATA-MENU.md) — 11 หน้า master data
- [SETUP-MENU.md](./SETUP-MENU.md) — 6 หน้า system admin

---

## เอกสารที่เกี่ยวข้อง

- [11-dev-setup](../11-dev-setup/) — local run
- [BRAND-ASSETS.md](./BRAND-ASSETS.md) — logo paths
- [PHASE-1-CHECKLIST](../07-phases/PHASE-1-CHECKLIST.md)
- [06-crm-schema/tables.md](../06-crm-schema/tables.md)

## ดูการเปลี่ยนแปลงล่าสุด

→ [CHANGELOG.md](./CHANGELOG.md)
