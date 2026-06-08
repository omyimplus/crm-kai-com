# Brand Assets — Logo & Colors

> **Source of truth** สำหรับ logo และสีหลัก CRM Kai ใน frontend  
> Phase: 1 · ใช้ไฟล์ใน repo นี้เท่านั้น — **ห้าม** อ้าง path อื่นหรือ hotlink ภายนอก

---

## สีหลัก (Primary)

| รายการ | ค่า |
|--------|-----|
| **Brand primary** | `#5fb76a` |
| **Sidebar section header (light)** | `#2e9e3c` → `--color-menu-section` |
| **Nuxt UI** | `primary: 'green'` → `--color-green-500` |
| **Implementation** | `frontend/app/assets/css/main.css` (`@theme static`) |

ใช้ class `text-primary`, `bg-primary`, `color="primary"` บน Nuxt UI — **ห้าม** hardcode `#5fb76a` ใน component (ยกเว้นเอกสาร)

หัวข้อ section ใน sidebar (เมนู / ข้อมูลหลัก / ตั้งค่าระบบ): light mode ใช้ `bg-menu-section` · dark mode ใช้ `bg-primary` ตามเดิม

---

## ตำแหน่งไฟล์

```
frontend/public/images/logo/
├── logo-kai-com-crm.webp        # logo เต็ม (header, login, marketing)
└── logo-kai-com-crm-icon.webp   # icon / favicon-style (sidebar ย่อ, mobile)

frontend/public/images/flags/
├── th.svg (หรือ th.webp)        # ธงไทย — LocaleSwitcher
└── en.svg (หรือ en.webp)        # ธง English
```

**ธงภาษา:** แก้ path ใน `frontend/app/config/localeFlags.ts` หลังเปลี่ยนไฟล์

---

## URL ใน Nuxt (public/)

| ไฟล์ | Path | ใช้เมื่อ |
|------|------|----------|
| **logo-kai-com-crm.webp** | `/images/logo/logo-kai-com-crm.webp` | หน้า login/signup, header กว้าง, branding |
| **logo-kai-com-crm-icon.webp** | `/images/logo/logo-kai-com-crm-icon.webp` | sidebar แคบ, avatar slot, PWA icon |

---

## กฎสำหรับ developer / Agent

| ห้าม | ต้อง |
|-----|------|
| ใส่ logo ไฟล์ใหม่ path อื่นโดยไม่ update MD นี้ | ใช้ 2 ไฟล์ด้านบน |
| hardcode URL ภายนอก | `<img src="/images/logo/logo-kai-com-crm.webp" alt="CRM Kai">` |
| ใช้ `logo-draft.png` ใน UI production | draft เท่านั้น — UI ใช้ `.webp` คู่นี้ |

**Alt text:** ใช้ i18n `t('common.appName')` หรือ `"CRM Kai"`

**Component:** ใช้ `<AppLogo variant="full" | "icon" />` — ดู `frontend/app/components/AppLogo.vue`

**ตัวอย่าง:**

```vue
<AppLogo variant="full" size="md" />
<AppLogo variant="icon" size="sm" />
```

---

## เอกสารที่เกี่ยวข้อง

- [05-frontend/README.md](./README.md)
- [12-i18n/TYPOGRAPHY.md](../12-i18n/TYPOGRAPHY.md)

## ดูการเปลี่ยนแปลงล่าสุด

→ [CHANGELOG.md](./CHANGELOG.md)
