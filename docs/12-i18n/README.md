# 12 — Internationalization (i18n)

> **กฎเหล็ก:** ทุกหน้า UI ต้องรองรับ **ไทย + English** เสมอ — รวม login, signup และ CRM  
> อ้างอิง: [IRON-RULES.md §12](../IRON-RULES.md) · [DECISIONS D-009](../00-overview/DECISIONS.md)

---

## สถานะปัจจุบัน

| รายการ | สถานะ |
|--------|--------|
| Phase | 1 |
| ภาษา UI | **ไทย (default)** + **English** |
| Module | `@nuxtjs/i18n` v9 |
| ครอบคลุม | `/login`, `/signup`, `/app/**` |
| สลับภาษา | `LocaleSwitcher` — login/signup (มุมขวาบน) + sidebar CRM |
| เงิน/วันที่ | `useFormat()` — ตาม locale ที่เลือก |
| Typography | [TYPOGRAPHY.md](./TYPOGRAPHY.md) — **Noto Sans Thai default ทั้งระบบ** (interim) |

---

## โครงสร้าง code

```
frontend/
├── i18n/
│   ├── i18n.config.ts          # vue-i18n config (fallbackLocale: th)
│   └── locales/
│       ├── th.json             # ภาษาไทย (source of truth คู่กับ en)
│       └── en.json             # English
├── app/
│   ├── components/
│   │   └── LocaleSwitcher.vue  # USelectMenu สลับ th/en
│   └── composables/
│       └── useFormat.ts        # formatCurrency ตาม locale
└── nuxt.config.ts              # i18n module config
```

---

## กฎสำหรับ developer / Agent

### 1. ห้าม hardcode ข้อความ UI

| ห้าม | ต้อง |
|-----|------|
| `"Save"` ใน template | `{{ t('common.save') }}` หรือ `$t('common.save')` |
| `label="Email"` | `:label="t('auth.email')"` |
| `confirm('Delete?')` | `confirm(t('contacts.confirmDelete'))` |

**ข้อยกเว้น:** ข้อความ error จาก Supabase/API — แสดง raw message ได้ (ยังไม่แปล backend)

### 2. เพิ่ม string ใหม่ = แก้ 2 ไฟล์พร้อมกัน

ทุก key ต้องมีใน **ทั้ง** `th.json` และ `en.json` ในรูปแบบเดียวกัน:

```json
// th.json + en.json
{
  "contacts": {
    "newField": "..."
  }
}
```

ใช้ namespace ตาม feature: `common`, `auth`, `nav`, `dashboard`, `contacts`, `companies`, `deals`

### 3. หน้าใหม่ทุกหน้าต้องมี LocaleSwitcher

| พื้นที่ | วางที่ไหน |
|---------|-----------|
| Auth (`layout: false`) | มุมขวาบน — ดู `login.vue` |
| CRM (`layout: app`) | sidebar ล่าง — ดู `layouts/app.vue` |

### 4. ตัวเลข / เงิน / วันที่

ใช้ `useFormat()` — **ห้าม** hardcode `Intl.NumberFormat('th-TH', ...)` ใน component

```ts
const { formatCurrency } = useFormat()
formatCurrency(amount, 'THB')
```

### 5. URL strategy

- `strategy: 'no_prefix'` — ไม่มี `/en/...` ใน URL
- ภาษาเก็บใน cookie `crm-kai-locale`
- default locale: **th**

### 6. Typography (ฟอนต์)

**อ่านเอกสารเต็ม:** [TYPOGRAPHY.md](./TYPOGRAPHY.md)

| สถานะ | ฟอนต์ |
|--------|-------|
| **ปัจจุบัน (interim)** | **Noto Sans Thai** ทั้งระบบ — รอ user สั่งเปลี่ยน |
| **แผนอนาคต** | Taviraj (ไทย body), Prompt (EN) — ยังไม่ใช้ |

หัวข้อ → `h1`–`h6` หรือ `.font-heading` · ห้าม hardcode `font-family`

---

## สิ่งที่ยังไม่แปล (Phase 1 — รู้ไว้)

| รายการ | เหตุผล | Phase ที่พิจารณา |
|--------|--------|------------------|
| ชื่อ pipeline stage ใน DB (seed) | user/org content — เก็บภาษาเดียวใน DB | 2+ (stage i18n table) |
| ชื่อ contact, company, deal | ข้อมูลลูกค้า — ไม่ใช่ UI string | — |
| Error message จาก Supabase | backend message | 2+ (error code map) |
| Landing / marketing (Phase 4) | ยังไม่มีหน้า | 4 |

---

## Config สำคัญ (`nuxt.config.ts`)

```ts
i18n: {
  defaultLocale: 'th',
  locales: [
    { code: 'th', language: 'th-TH', name: 'ไทย', file: 'th.json' },
    { code: 'en', language: 'en-US', name: 'English', file: 'en.json' }
  ],
  lazy: true,
  langDir: 'locales',
  strategy: 'no_prefix',
  detectBrowserLanguage: {
    cookieKey: 'crm-kai-locale',
    fallbackLocale: 'th'
  }
}
```

---

## Checklist ก่อน merge UI

- [ ] ไม่มี hardcoded UI string ใน Vue (ยกเว้น error จาก API)
- [ ] key ใหม่มีครบ `th.json` + `en.json`
- [ ] หน้า auth มี `LocaleSwitcher`
- [ ] หน้า CRM ใช้ layout `app` (มี switcher ใน sidebar)
- [ ] เงินใช้ `useFormat()` ไม่ใช่ locale คงที่
- [ ] หัวข้อใช้ `h*` หรือ `.font-heading` — ไม่ hardcode font-family
- [ ] บันทึก CHANGELOG ใน `docs/12-i18n/` และ `frontend/` ถ้าแก้ locale

---

## เอกสารที่เกี่ยวข้อง

- [05-frontend/](../05-frontend/) — routes, composables
- [07-phases/PHASE-1-CHECKLIST.md](../07-phases/PHASE-1-CHECKLIST.md)
- [DECISIONS D-009](../00-overview/DECISIONS.md) — 2 ภาษา
- [DECISIONS D-010](../00-overview/DECISIONS.md) — typography
- [TYPOGRAPHY.md](./TYPOGRAPHY.md) — ฟอนต์ Noto Sans Thai / Taviraj / Prompt

## ดูการเปลี่ยนแปลงล่าสุด

→ [CHANGELOG.md](./CHANGELOG.md)
