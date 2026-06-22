# KC KuTo CRM (Nuxt)

เวอร์ชัน Nuxt + Tailwind CSS ของ KC KuTo CRM แยกจากโปรเจกต์ React/Vite ต้นฉบับ

## Tech Stack

- Nuxt 4
- Vue 3
- Tailwind CSS
- lucide-vue-next (icons)

## การรัน

```bash
npm install
npm run dev
```

เปิดที่ http://localhost:3000

## หน้าที่พร้อมใช้งาน

- `/` — Dashboard (หน้าหลัก)
- หน้าอื่น ๆ ทั้งหมด — Coming Soon

## โครงสร้าง

```
kuto-crm-nuxt/
├── app/
│   ├── components/
│   │   ├── common/ComingSoon.vue
│   │   ├── dashboard/DashboardView.vue
│   │   ├── layout/AppHeader.vue, AppSidebar.vue
│   │   └── ui/AppBadge.vue, AppCard.vue
│   ├── composables/useLang.ts
│   ├── data/navigation.ts
│   ├── layouts/default.vue
│   └── pages/
│       ├── index.vue
│       └── [...slug].vue
└── tailwind.config.ts
```
