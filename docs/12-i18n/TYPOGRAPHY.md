# Typography — ฟอนต์

> **ADR:** [D-010](../00-overview/DECISIONS.md) · **i18n:** [README.md](./README.md) · **กฎเหล็ก:** [IRON-RULES §12](../IRON-RULES.md)

---

## สถานะปัจจุบัน (Phase 1 — interim)

| รายการ | ค่า |
|--------|-----|
| **Login / signup** | **Noto Sans Thai** — ทุก locale |
| **CRM (`th`)** | **Sarabun** — หัวข้อ + เนื้อหา + UI ทั้งหมด |
| **CRM (`en`)** | **Noto Sans Thai** ทั้งหมด |
| **ขนาดฐาน** | `html { font-size: 16px; }` — มาตรฐาน + antialiasing / contrast |
| **เปลี่ยนเมื่อ** | user สั่งเท่านั้น |

**แผนถัดไป:** EN CRM → Prompt

---

## สรุป

| ประเภท | ฟอนต์ (CRM, locale=th) |
|--------|------------------------|
| หัวข้อ (`h1`–`h6`, `.font-heading`) | Sarabun |
| เนื้อหา / label / ปุ่ม / ตาราง (`--font-sans`) | Sarabun |
| login / signup | Noto Sans Thai |

---

## กฎสำหรับ developer / Agent

| ห้าม | ต้อง |
|-----|------|
| hardcode `font-family` ใน component | inherit จาก `--font-sans` / `--font-heading` |
| ใช้ Sarabun, Prompt, Inter โดยไม่สั่ง user | CRM ไทย: **Sarabun** ทั้งหมด ตาม D-010 |
| เปลี่ยน font ใน code อย่างเดียว | อัปเดต MD นี้ + D-010 + CHANGELOG |
| ลืม sync `html lang` | `app.vue` → `useHead({ htmlAttrs: { lang: locale } })` |

### หัวข้อ

ใช้ **`h1`–`h6`** หรือ class **`.font-heading`**

### เนื้อหา

ใช้ element ปกติ — Nuxt UI inherit `--font-sans` (Noto Sans Thai)

---

## Implementation

```
frontend/
├── app/
│   ├── app.vue              # Google Fonts — Noto Sans Thai + Sarabun
│   └── assets/css/main.css  # .crm-app locale overrides
```

### Google Fonts

```
Noto Sans Thai — 400, 500, 600, 700
Sarabun — 400, 500, 600, 700 (CRM ภาษาไทย)
```

### CSS (`main.css`)

```css
@theme static {
  --font-sans: "Noto Sans Thai", sans-serif;
  --font-heading: "Noto Sans Thai", sans-serif;
}

html { font-size: 16px; }
body { line-height: 1.55; -webkit-font-smoothing: antialiased; }

html[lang="th"] .crm-app {
  --font-sans: "Sarabun", "Noto Sans Thai", sans-serif;
  --font-heading: "Sarabun", "Noto Sans Thai", sans-serif;
}
```

---

## Checklist ก่อน merge UI

- [ ] ไม่มี `font-family` hardcode
- [ ] ไม่โหลด/ใช้ font อื่นโดยไม่สั่ง user
- [ ] แก้ font → อัปเดตไฟล์นี้ + D-010 + CHANGELOG

---

## เปลี่ยนฟอนต์ (เมื่อ user สั่ง)

1. ยืนยันกับ user / อัปเดต D-010
2. แก้ `main.css`, `app.vue` (Google Fonts URL)
3. บันทึก CHANGELOG

---

## เอกสารที่เกี่ยวข้อง

- [12-i18n/README.md](./README.md)
- [DECISIONS D-010](../00-overview/DECISIONS.md)

→ [CHANGELOG.md](./CHANGELOG.md)
