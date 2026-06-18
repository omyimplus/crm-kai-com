# Typography — ฟอนต์

> **ADR:** [D-010](../00-overview/DECISIONS.md) · **i18n:** [README.md](./README.md) · **กฎเหล็ก:** [IRON-RULES §12](../IRON-RULES.md)

---

## สถานะปัจจุบัน (Phase 1)

| รายการ | ค่า |
|--------|-----|
| **Headline** (`h1`–`h6`, `.font-heading`) | **IBM Plex Sans Thai SemiBold** — weight `600` |
| **Body** (UI, ตาราง, ปุ่ม, label, auth) | **IBM Plex Sans Thai Regular** — weight `400` |
| **Locale** | th + en ใช้ฟอนต์เดียวกัน |
| **ขนาดฐาน** | `html { font-size: 16px; }` — CRM `/app` ใช้ `15px` |
| **เปลี่ยนเมื่อ** | user สั่งเท่านั้น |

---

## สรุป

| ประเภท | ฟอนต์ | Weight |
|--------|-------|--------|
| หัวข้อ | IBM Plex Sans Thai | 600 (SemiBold) |
| เนื้อหา / UI | IBM Plex Sans Thai | 400 (Regular) |

---

## กฎสำหรับ developer / Agent

| ห้าม | ต้อง |
|-----|------|
| hardcode `font-family` ใน component | inherit จาก `--font-sans` / `--font-heading` |
| ใช้ Noto, Sarabun, Prompt โดยไม่สั่ง user | **IBM Plex Sans Thai** ตาม D-010 |
| เปลี่ยน font ใน code อย่างเดียว | อัปเดต MD นี้ + D-010 + CHANGELOG |
| ลืม sync `html lang` | `app.vue` → `useHead({ htmlAttrs: { lang: locale } })` |

### หัวข้อ

ใช้ **`h1`–`h6`** หรือ class **`.font-heading`** — weight 600 จาก `main.css`

### เนื้อหา

ใช้ element ปกติ — Nuxt UI inherit `--font-sans` (Regular 400)

---

## Implementation

```
frontend/
├── app/
│   ├── app.vue              # Google Fonts — IBM Plex Sans Thai 400, 600
│   └── assets/css/main.css  # --font-sans / --font-heading
```

### Google Fonts

```
IBM Plex Sans Thai — 400 (Regular), 600 (SemiBold)
```

URL ใน `app.vue`:

```
family=IBM+Plex+Sans+Thai:wght@400;600
```

### CSS (`main.css`)

```css
@theme static {
  --font-sans: "IBM Plex Sans Thai", sans-serif;
  --font-heading: "IBM Plex Sans Thai", sans-serif;
}

body { font-weight: 400; }

.font-heading { font-weight: 600; }
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
