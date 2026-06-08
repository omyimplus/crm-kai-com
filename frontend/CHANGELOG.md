# Changelog — Frontend

→ [README.md](./README.md)

---

## ประวัติ

### 2026-06-08 — strengthen login → CRM session routing

- **ทำอะไร:** `useAuthSession`, middleware auth/guest, index redirect, logo ใน CRM sidebar
- **ไฟล์ที่กระทบ:** `composables/useAuthSession.ts`, `middleware/*`, `index.vue`, `login.vue`, `layouts/app.vue`
- **Phase:** 1

### 2026-06-08 — default font Noto Sans Thai ทั้งระบบ (interim)

- **ทำอะไร:** `--font-sans` / `--font-heading` = Noto ทุก locale — รอ user สั่ง Taviraj/Prompt
- **ไฟล์ที่กระทบ:** `main.css`, `app.vue`, `TYPOGRAPHY.md`, `DECISIONS.md`, IRON-RULES, Cursor rule
- **Phase:** 1

### 2026-06-08 — auth panel: container + green-50 + Noto สำหรับ p

- **ทำอะไร:** AuthShell ซ้าย — container, พื้นเขียวอ่อน, `.auth-brand-panel` ใช้ Noto Sans Thai ชั่วคราว
- **ไฟล์ที่กระทบ:** `AuthShell.vue`, `main.css`, `TYPOGRAPHY.md`
- **Phase:** 1

### 2026-06-08 — redesign login/signup (FlowAccount-style + logo)

- **ทำอะไร:** AuthShell split layout, logo, i18n brand copy, signup ใช้ layout เดียวกัน
- **ไฟล์ที่กระทบ:** `AuthShell.vue`, `login.vue`, `signup.vue`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — fix dev script TMPDIR สำหรับ macOS (Nuxt 4.4.7 socket)

- **ทำอะไร:** `dev`: `TMPDIR=/tmp nuxt dev` — แก้ ENOENT vite-node socket
- **ไฟล์ที่กระทบ:** `package.json`
- **Phase:** 1

### 2026-06-08 — add locale typography (Noto Sans Thai, Taviraj, Prompt)

- **ทำอะไร:** Google Fonts + CSS variables ตาม `html[lang]` — sync กับ i18n locale
- **ไฟล์ที่กระทบ:** `app/assets/css/main.css`, `app.vue`, `app/layouts/app.vue`
- **Phase:** 1
- **อ้างอิง:** `docs/12-i18n/README.md` § Typography

### 2026-06-08 — add i18n (th + en) ทุกหน้า UI

- **ทำอะไร:** `@nuxtjs/i18n`, locale files, LocaleSwitcher, useFormat — แทน hardcoded strings ใน login/signup/CRM
- **ไฟล์ที่กระทบ:** `i18n/**`, `app/pages/**`, `app/layouts/app.vue`, `app/components/**`, `nuxt.config.ts`, `package.json`
- **Phase:** 1
- **อ้างอิง:** `docs/12-i18n/`, DECISIONS D-009, IRON-RULES §12

### 2026-06-08 — create Phase 1 CRM scaffold

- **ทำอะไร:** Nuxt 4 + Nuxt UI + Supabase — login/signup, dashboard, contacts, companies, deals Kanban
- **ไฟล์ที่กระทบ:** `app/**`, `nuxt.config.ts`, `package.json`, `.env.example`
- **Phase:** 1
- **หมายเหตุ:** `/signup` สำหรับผูก demo org (ไม่ใช่ SaaS register Phase 4)
