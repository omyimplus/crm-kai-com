# Shared UI Components — ใช้ร่วมทั้งระบบ

> **อ่านก่อนสร้างหน้า list / form / ตารางใหม่** — ใช้ component และ class ชุดนี้ให้ UI สม่ำเสมอ  
> Code อยู่ `frontend/app/components/App*.vue`, `config/appFormUi.ts`, `composables/usePagination.ts`

---

## หลักการ

| ห้าม | ใช้แทน |
|-----|--------|
| ตาราง raw `<table>` + style เอง | `AppDataTable` + `AppDataTableTh/Td/Row` |
| แบ่งหน้าเองทีละหน้า | `usePagination` + `AppPagination` |
| Modal form แบบไม่สม่ำเสมอ | `AppDialog` + `AppDialogFooter` |
| Chip สีต่างกันแต่ละหน้า | `appTableBadgeClass`, `appPlatformRoleBadgeClass` |
| Hardcode UI string | `i18n` th + en — [12-i18n](../12-i18n/README.md) |

**ขนาดตาราง:** `DEFAULT_PAGE_SIZE = 20` ([`config/pagination.ts`](../../frontend/app/config/pagination.ts))

---

## ตาราง (List pages)

### ชุด component

| Component | ไฟล์ | หน้าที่ |
|-----------|------|---------|
| `AppDataTable` | `components/AppDataTable.vue` | wrapper ตาราง + header เขียว (มนซ้าย–ขวา–บน) |
| `AppDataTableTh` | `components/AppDataTableTh.vue` | `<th>` |
| `AppDataTableTd` | `components/AppDataTableTd.vue` | `<td>` — prop `muted`, `align` |
| `AppDataTableRow` | `components/AppDataTableRow.vue` | `<tr>` hover |
| `AppPagination` | `components/AppPagination.vue` | แถบแบ่งหน้าใต้ตาราง |
| `AppIconButton` | `components/AppIconButton.vue` | ปุ่มไอคอนในคอลัมน์ action |

### Composable

```ts
import { usePagination } from '~/composables/usePagination'

const items = ref<MyRow[]>([]) // หรือ computed หลัง filter

const {
  page,
  pagedItems,       // ใช้ใน v-for
  totalItems,
  totalPages,
  rangeStart,
  rangeEnd,
  pageSize,         // default 20
  resetPage
} = usePagination(items) // หรือ usePagination(filteredItems)
```

- เปลี่ยน filter / search → รีเซ็ตหน้า 1 อัตโนมัติ
- เรียก `resetPage()` เมื่อกดล้าง filter เอง

### Layout มาตรฐาน (ตาราง + pagination)

```vue
<div class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800">
  <AppDataTable embedded>
    <template #head>
      <tr>
        <AppDataTableTh>{{ t('...') }}</AppDataTableTh>
      </tr>
    </template>

    <AppDataTableRow v-for="row in pagedItems" :key="row.id">
      <AppDataTableTd>...</AppDataTableTd>
      <AppDataTableTd muted>...</AppDataTableTd>
      <AppDataTableTd align="right">
        <AppIconButton icon="i-lucide-pencil" @click="openEdit(row)" />
      </AppDataTableTd>
    </AppDataTableRow>
  </AppDataTable>

  <AppPagination
    v-model:page="page"
    embedded
    :total-items="totalItems"
    :total-pages="totalPages"
    :range-start="rangeStart"
    :range-end="rangeEnd"
    :page-size="pageSize"
  />
</div>
```

**`embedded`** บน `AppDataTable` + `AppPagination` = แชร์ border กับ wrapper ด้านนอก (ไม่ซ้อนกรอบ)

### Class ตาราง (`config/appFormUi.ts`)

| Export | ใช้เมื่อ |
|--------|----------|
| `appTableTextClass` | ขนาดตัวอักษรตาราง (`text-sm` + 1px) |
| `appTableBadgeClass` | chip ในตาราง — ตัวอักษรดำหนา |
| `appPlatformRoleBadgeClass` | chip ระดับองค์กร: `owner` / `admin` / `employee` |
| `appTableRoleTabBaseClass` | ปุ่ม tab กรอง role (inline-block) |
| `appTableRoleTabActiveClass` | tab ที่เลือก |
| `appTableRoleTabInactiveClass` | tab ปกติ |

ตัวอย่าง chip ระดับองค์กร:

```vue
<UBadge
  variant="subtle"
  :class="[appTableBadgeClass, appPlatformRoleBadgeClass[user.role]]"
>
  {{ t(`profile.roles.${user.role}`) }}
</UBadge>
```

### หน้าที่ใช้แล้ว

| หน้า | หมายเหตุ |
|------|----------|
| `/app/setup/system-users` | + tabs กรอง role, ข้อความ `displayCount` |
| `/app/setup/user-approvals` | |
| `/app/setup/roles` | table + grid ใช้ `pagedItems` |
| `/app/contacts` | |
| `/app/companies` | |

### i18n pagination

| Key | ตัวอย่าง (th) |
|-----|----------------|
| `common.pagination.range` | แสดง 1–20 จาก 45 |
| `common.pagination.previous` | ก่อนหน้า |
| `common.pagination.next` | ถัดไป |
| `common.pagination.page` | หน้า 1 / 3 |

---

## Dialog / Form

### ชุด component

| Component | ไฟล์ | หน้าที่ |
|-----------|------|---------|
| `AppDialog` | `components/AppDialog.vue` | modal มาตรฐาน — `v-model:open`, `title`, `size` |
| `AppDialogFooter` | `components/AppDialogFooter.vue` | ปุ่มยกเลิก + slot ปุ่มหลัก |
| `AppPasswordFieldGroup` | `components/AppPasswordFieldGroup.vue` | รหัสผ่าน + confirm + strength + สร้างรหัสผ่าน |
| `AppPasswordInput` | `components/AppPasswordInput.vue` | input รหัสผ่าน + แสดง/ซ่อน |
| `AppOrgRoleChipSelect` | `components/AppOrgRoleChipSelect.vue` | เลือกบทบาททีมแบบ chip หลายอัน |
| `AppImageUpload` / `AppAvatarUpload` | ดู [IMAGE-UPLOAD.md](./IMAGE-UPLOAD.md) | อัปโหลดรูป |

### Class ฟอร์ม (`config/appFormUi.ts`)

| Export | ใช้กับ |
|--------|--------|
| `appFormFieldClass` | `UFormField` |
| `appInputUi` | `UInput` |
| `appSelectMenuUi` | `USelectMenu` |
| `appTextareaUi` | `UTextarea` |
| `appFormHintClass` | ข้อความ hint ใต้ field |
| `appFormErrorClass` | ข้อความ error |
| `appFormInfoClass` | กล่องข้อมูลสีเขียวอ่อน |
| `appFormSwitchBoxClass` | กล่อง `USwitch` |

### ตัวอย่าง Dialog

```vue
<AppDialog v-model:open="formOpen" :title="t('...')" size="2xl">
  <!-- ใส่เนื้อหาเป็น default slot — ห้ามใช้ #body (ยกเว้น AppDialog รองรับ fallback แล้ว) -->
  <form id="my-form" @submit.prevent="save">...</form>

  <template #footer>
    <AppDialogFooter @cancel="formOpen = false">
      <UButton type="submit" form="my-form">{{ t('common.save') }}</UButton>
    </AppDialogFooter>
  </template>
</AppDialog>
```

**Modal ซ้อน modal:** ห้ามใส่ dialog ลูกใน dialog แม่ — hoist ไป page level (ดู `.cursor/rules/nuxt-frontend-pitfalls.mdc`)

---

## Image upload

→ รายละเอียดเต็ม: **[IMAGE-UPLOAD.md](./IMAGE-UPLOAD.md)**

| ชั้น | ไฟล์ | ใช้เมื่อ |
|------|------|---------|
| `AppImageUpload` | `components/AppImageUpload.vue` | ฟอร์มอัปโหลดรูปทั่วไป (preset + slot preview) |
| `AppAvatarUpload` | `components/AppAvatarUpload.vue` | รูปพนักงาน — ห่อ `AppImageUpload preset="avatar"` |
| `AppUserAvatar` | `components/AppUserAvatar.vue` | แสดงรูปกลมเท่านั้น |
| `useImageUpload` | `composables/useImageUpload.ts` | validate, upload, remove Storage |
| `useImageUploadState` | `composables/useImageUploadState.ts` | state preview ในฟอร์มก่อน save |
| `useUserAvatar` | `composables/useUserAvatar.ts` | path รูปพนักงาน |
| `useOrgCompanyLogo` | `composables/useOrgCompanyLogo.ts` | path โลโก้บริษัท |
| `config/imageUpload.ts` | presets: `avatar`, `companyLogo` |

---

## Component ในโฟลเดอร์ `setup/`

ไฟล์ `components/setup/SystemUserFormModal.vue` → ใช้ใน template เป็น **`SetupSystemUserFormModal`** (prefix ชื่อโฟลเดอร์)

| ไฟล์ | ใน template |
|------|-------------|
| `setup/SystemUserFormModal.vue` | `SetupSystemUserFormModal` |
| `setup/OrgRoleFormModal.vue` | `SetupOrgRoleFormModal` |
| `setup/OrgRoleDeleteModal.vue` | `SetupOrgRoleDeleteModal` |

---

## Sidebar / Layout

| Component | หน้าที่ |
|-----------|---------|
| `AppSidebar` | sidebar CRM |
| `AppSidebarNavItem` | รายการเมนู |
| `AppSidebarSectionLabel` | หัว section เขียว |
| `AppHeader` | header บน content |
| `AppLogo` | logo full / icon |
| `UserMenu` | เมนูผู้ใช้มุมขวา |

---

## Checklist หน้า list ใหม่

- [ ] โหลดข้อมูล → `ref` / `computed` สำหรับ filter
- [ ] `usePagination(items)` — แสดง `pagedItems` ไม่ใช่ array เต็ม
- [ ] wrapper `border` + `AppDataTable embedded` + `AppPagination embedded`
- [ ] chip ใช้ `appTableBadgeClass` (+ `appPlatformRoleBadgeClass` ถ้าเป็น role)
- [ ] ข้อความ UI ผ่าน `t('...')` th + en
- [ ] อัปเดต CHANGELOG โฟลเดอร์ที่แก้

---

## เอกสารที่เกี่ยวข้อง

- [README.md](./README.md) — frontend overview
- [BRAND-ASSETS.md](./BRAND-ASSETS.md) — logo
- [12-i18n](../12-i18n/README.md) — ภาษา
- [frontend/CHANGELOG.md](../../frontend/CHANGELOG.md) — ประวัติ code

*อัปเดต: 2026-06-08*
