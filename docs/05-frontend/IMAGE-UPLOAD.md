# Image Upload — อัปโหลดรูปทั้งระบบ

> **อ่านก่อนเพิ่มฟีเจอร์อัปโหลดรูปใหม่** — ใช้ชุดกลางนี้ ห้ามเขียน upload/resize/validate ซ้ำ

---

## เลือกเครื่องมือไหน

| งาน | ใช้ | อย่าใช้ |
|-----|-----|--------|
| UI เลือก/ลบรูปในฟอร์ม | `AppImageUpload` (+ slot `#preview`) | `<input type="file">` + validate เอง |
| รูปพนักงาน (กลม) | `AppAvatarUpload` → ห่อ `AppImageUpload preset="avatar"` | copy จาก SystemUserFormModal |
| state รอบันทึก (preview / เปลี่ยน / ลบ) | `useImageUploadState()` | ref หลายตัวซ้ำในแต่ละ modal |
| validate + อัปโหลด Storage + ลบไฟล์ | `useImageUpload()` | Supabase storage ตรง ๆ ใน component |
| preset ขนาด/bucket/mime | `config/imageUpload.ts` | ค่าคงที่กระจายหลายไฟล์ |
| resize → WebP | `utils/imageUpload.ts` (`convertImageForUpload`) | canvas ใน composable อื่น |
| domain เฉพาะ (path ใน bucket) | composable บาง — ดูด้านล่าง | logic path ใน page |

---

## Presets (`config/imageUpload.ts`)

| ID | Bucket | ขนาดสูงสุด | ชนิดไฟล์ | Resize |
|----|--------|-----------|----------|--------|
| `avatar` | `avatars` | 5 MB | JPG, PNG, WebP, GIF | WebP max 512px |
| `companyLogo` | `org-images` | 2 MB | JPG, PNG, WebP, SVG | WebP max 800px (SVG คงเดิม) |
| `categoryImage` | `org-images` | 2 MB | JPG, PNG, WebP, GIF | WebP max 640px |
| `productImage` | `org-images` | 2 MB | JPG, PNG, WebP, GIF | WebP max 800px |

เพิ่ม preset ใหม่ → แก้ `imageUpload.ts` + migration bucket/policy (ถ้าต้องการ bucket ใหม่) + i18n `common.imageUpload.errors.*`

---

## Composables

### `useImageUpload()` — ชั้นกลาง

```ts
const { validate, upload, remove, hasCustomImage, getPreset } = useImageUpload()

// validate ก่อน emit จาก UI (AppImageUpload ทำให้แล้ว)
const err = validate(file, 'companyLogo') // 'tooLarge' | 'invalidType' | null

// อัปโหลด — ส่ง path ภายใน bucket (ไม่รวม bucket name)
const publicUrl = await upload('avatar', `${orgId}/${userId}.webp`, file)

// ลบ — รวม path จาก URL เดิม + candidates + list folder
await remove('companyLogo', {
  knownPublicUrl: oldUrl,
  candidatePaths: [`${orgId}/company-profiles/${id}.webp`],
  listFolder: `${orgId}/company-profiles`,
  listPrefix: profileId
})
```

### `useImageUploadState()` — state ในฟอร์ม

```ts
// ต้อง destructure — ห้ามเก็บเป็น object แล้วใช้ image.previewUrl ใน template
// (Vue ไม่ unwrap ref ซ้อนใน plain object → render error / dialog ไม่ขึ้น)
const {
  previewUrl,
  changed,
  file,
  removed,
  select,
  remove,
  reset
} = useImageUploadState(initialUrl)
```

### Domain wrappers (path + business rules)

| Composable | Preset | Path pattern |
|------------|--------|--------------|
| `useUserAvatar()` | `avatar` | `{org_id}/{user_id}.ext` |
| `useOrgCompanyLogo()` | `companyLogo` | `{org_id}/company-profiles/{profile_id}.ext` |
| `useCategoryImage()` | `categoryImage` | `{org_id}/categories/{category_id}.ext` |
| `useProductImage()` | `productImage` | `{org_id}/products/{product_id}.ext` |
| `useProductGallery()` | `productImage` | `{org_id}/products/{product_id}/gallery/{image_id}.webp` |

**เพิ่ม use case ใหม่:** สร้าง composable บาง ๆ ที่กำหนด path + เรียก `useImageUpload` — อย่า duplicate resize/validate

---

## UI Components

### `AppImageUpload`

```vue
<AppImageUpload
  preset="companyLogo"
  :preview-url="image.previewUrl"
  :label="t('setup.settings.companyInfo.logo')"
  :hint="t('setup.settings.companyInfo.logoHint')"
  @select="image.select"
  @remove="image.remove"
>
  <template #preview="{ previewUrl, hasUpload }">
    <!-- กล่อง preview ตามดีไซน์หน้านั้น -->
  </template>
</AppImageUpload>
```

- ปุ่มอัปโหลด/เปลี่ยน/ลบ → `common.imageUpload.*`
- Error → `common.imageUpload.errors.tooLarge.{preset}` / `invalidType.{preset}`

### `AppAvatarUpload`

ใช้เมื่อเป็นรูปพนักงาน — ภายในใช้ `AppImageUpload preset="avatar"` + `AppUserAvatar`

### `AppUserAvatar`

**แสดงอย่างเดียว** (list, header) — ไม่ใช่สำหรับอัปโหลด

---

## Flow บันทึก (ตัวอย่าง company logo)

1. เปิด modal → `image.reset(profile.logoUrl)`
2. User เลือกไฟล์ → `image.select(file)` (preview ทันที)
3. กดบันทึก:
   - สร้าง/อัปเดต record ข้อมูลหลัก
   - ถ้า `image.changed`:
     - ลบ: `removeLogo(id)` + RPC `setLogo: true, logoUrl: null`
     - อัปโหลด: `uploadLogo(id, file)` + RPC `setLogo: true, logoUrl: url`
4. ลบ profile → เรียก `removeLogo` ก่อน RPC delete

ดูตัวอย่างจริง: `SettingsCompanyProfileFormModal.vue`, `SystemUserFormModal.vue`

---

## Database / Storage

| Migration | เนื้อหา |
|-----------|---------|
| `20260608120021_user_avatars_storage.sql` | bucket `avatars` + RLS |
| `20260608120026_org_images_storage.sql` | bucket `org-images` + RPC `logo_url` |

RLS: owner/admin ของ org เท่านั้น; path ขึ้นต้นด้วย `current_org_id()`

---

## Checklist ฟีเจอร์อัปโหลดรูปใหม่

- [ ] มี preset ใน `config/imageUpload.ts` หรือใช้ preset เดิม
- [ ] bucket + policy ใน migration (ถ้ายังไม่มี)
- [ ] composable domain สำหรับ build path
- [ ] UI ใช้ `AppImageUpload` + `useImageUploadState`
- [ ] i18n error ตาม preset (th + en)
- [ ] ลบไฟล์ใน Storage เมื่อลบ entity
- [ ] อัปเดต CHANGELOG + เอกสารนี้ถ้าเพิ่ม preset

---

## เอกสารที่เกี่ยวข้อง

- [SHARED-COMPONENTS.md](./SHARED-COMPONENTS.md) — สรุป component ร่วม
- [BRAND-ASSETS.md](./BRAND-ASSETS.md) — logo สาธารณะใน `public/`

*อัปเดต: 2026-06-08*
