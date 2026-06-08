# App Menu — CRM Navigation (Scaffold)

> **สถานะ:** Coming soon ทุกหน้า — scaffold menu + routes + เอกสารเท่านั้น  
> **Config แหล่งเดียว:** `frontend/app/config/appMenu.ts`  
> **Sidebar:** ส่วน **Menu** อยู่บนสุด — ตามด้วย **Master Data** และ **Setup** (ดู [MASTER-DATA-MENU.md](./MASTER-DATA-MENU.md), [SETUP-MENU.md](./SETUP-MENU.md))

---

## ภาพรวม

เมนู **Menu** ใน sidebar CRM — ครอบคลุม flow ขายตั้งแต่ลีดจนถึงบริการหลังการขาย

| # | เมนู | Route | Key | สถานะ |
|---|------|-------|-----|--------|
| 1 | Dashboard | `/app` | `dashboard` | ✅ ใช้งานได้ (สถิติดีล Phase 1) |
| 2 | Tasks | `/app/tasks` | `tasks` | ⏳ |
| 3 | Lead | `/app/leads` | `lead` | ⏳ |
| 4 | Opportunity | `/app/opportunities` | `opportunity` | ⏳ |
| 5 | Quotations | `/app/quotations` | `quotations` | ⏳ |
| 6 | Pipeline | `/app/pipeline` | `pipeline` | ⏳ |
| 7 | Sales order | `/app/sales-orders` | `salesOrder` | ⏳ |
| 8 | Invoices | `/app/invoices` | `invoices` | ⏳ |
| 9 | Reports | `/app/reports` | `reports` | ⏳ |
| 10 | Projects | `/app/projects` | `projects` | ⏳ |
| 11 | Contract agreements | `/app/contract-agreements` | `contractAgreements` | ⏳ |
| 12 | Service | `/app/service` | `service` | ⏳ |

**แผน implement:** ไล่ทีละหน้า — แทนที่ `AppMenuComingSoon` ด้วยหน้าจริงเมื่อพร้อม

---

## Flow ขาย (แนวทาง)

```
Lead → Opportunity → Quotation → Sales order → Invoice
         ↓                              ↓
      Pipeline                      Project
                                        ↓
                              Contract agreement → Service
```

- **Tasks** — งานข้ามโมดูล (ติดตามลูกค้า, follow-up, internal)
- **Reports** — สรุปจากทุกโมดูลด้านบน
- **Dashboard** — ภาพรวม KPI และงานค้าง

---

## Frontend

```
frontend/app/
├── config/appMenu.ts              ← แก้เมนูที่นี่ที่เดียว
├── components/
│   ├── AppSidebar.vue             ← อ่าน appMenuItems
│   └── app-menu/AppMenuComingSoon.vue
└── pages/app/
    ├── index.vue                  → dashboard
    ├── tasks.vue
    ├── leads.vue
    ├── opportunities.vue
    ├── quotations.vue
    ├── pipeline.vue
    ├── sales-orders.vue
    ├── invoices.vue
    ├── reports.vue
    ├── projects.vue
    ├── contract-agreements.vue
    └── service.vue
```

### i18n

- Section label: `appMenu.section`
- Nav label: `appMenu.{key}.nav`
- หน้า Coming soon: `appMenu.{key}.title`, `.description`, `.features`
- ไฟล์: `frontend/i18n/locales/{th,en}.json`

### Sidebar badge

- **Dashboard** — ไม่มี badge (หน้าจริง Phase 1)
- **รายการอื่น** — badge `common.comingSoonBadge` จนกว่าจะ implement จริง

---

## เมนูอื่นใน sidebar

| ส่วน | เอกสาร |
|------|--------|
| Master data (`/app/master-data/**`) | [MASTER-DATA-MENU.md](./MASTER-DATA-MENU.md) |
| Setup (`/app/setup/**`) | [SETUP-MENU.md](./SETUP-MENU.md) |

**Legacy routes** (`/app/contacts`, `/app/companies`, `/app/deals`) — ยังเข้า URL ได้จาก Dashboard

---

## ดูการเปลี่ยนแปลง

→ [CHANGELOG.md](./CHANGELOG.md)
