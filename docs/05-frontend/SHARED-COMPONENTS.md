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
| `AppViewModeToggle` | `components/AppViewModeToggle.vue` | สลับมุมมอง table/card หรือ list/calendar |

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

### สลับมุมมอง (table / card / list / calendar)

ใช้ **`AppViewModeToggle`** + preset จาก `config/appViewMode.ts` — reference: Setup → กำหนด Role

```vue
<script setup lang="ts">
import { appTableGridViewOptions, type AppTableGridViewMode } from '~/config/appViewMode'

const { t } = useI18n()
const viewMode = ref<AppTableGridViewMode>('table')
const viewModeOptions = computed(() => appTableGridViewOptions(t))
</script>

<template>
  <AppViewModeToggle v-model="viewMode" :options="viewModeOptions" />
  <!-- v-if="viewMode === 'table'" → AppDataTable -->
  <!-- v-else → grid ของ card components -->
</template>
```

| Preset | ค่า | ใช้ที่ |
|--------|-----|--------|
| `appTableGridViewOptions(t)` | `table` \| `grid` | Setup roles, company profiles |
| `appListCalendarViewOptions(t)` | `list` \| `calendar` | Tasks |

- i18n: `common.viewMode.*` (th + en)
- ค่าเริ่มต้น: ปุ่มไอคอนอย่างเดียว (`showLabels: false`) — ใส่ `show-labels` ถ้าต้องการข้อความคู่ไอคอน

---

## List page แบบ «ผู้ใช้ในระบบ» (reference layout)

> **Reference:** `frontend/app/pages/app/setup/system-users/index.vue`  
> ใช้เป็นแม่แบบทุกหน้ารายการที่มี **filter + tab กรอง + ตาราง + modal สร้าง/แก้**

### โครงหน้า (4 สถานะ)

```
┌─ Page header (title + subtitle + ปุ่มสร้าง) ─────────────┐
├─ [loading]  UCard + common.loading                        │
├─ [empty]    UCard + empty + ปุ่ม createFirst              │
└─ [has data]                                               │
    ├─ UCard filter bar (searchBy + search + reset)         │
    └─ bordered block                                       │
        ├─ role/status tabs (appTableRoleTab*)              │
        ├─ displayCount                                     │
        ├─ [no match] empty filter + reset                  │
        └─ AppDataTable embedded + AppPagination embedded   │
                                                             │
    SetupXxxFormModal (page level — ไม่ซ้อนใน dialog อื่น)  │
```

| สถานะ | เงื่อนไข | UI |
|--------|----------|-----|
| Loading | `loading === true` | `UCard` + `common.loading` |
| Empty DB | `!loading && !items.length` | `UCard` + ข้อความว่าง + ปุ่ม `createFirst` |
| Has data | `items.length > 0` | filter + table block |
| Filter ไม่ตรง | `filtered.length === 0` | ข้อความ `filters.noResults` + ปุ่ม `viewAll` |

### 1) Page header

```vue
<div class="mb-6 flex flex-wrap items-center justify-between gap-4">
  <div>
    <h1 class="text-2xl font-bold font-heading">{{ t('...title') }}</h1>
    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">{{ t('...subtitle') }}</p>
  </div>
  <UButton icon="i-lucide-..." @click="openCreate">{{ t('...create') }}</UButton>
</div>
```

- หัวข้อใช้ **`font-heading`** (IBM Plex SemiBold)
- ปุ่มสร้างเปิด **modal** (`formOpen = true`) — ไม่ไป route `/new` (ยกเว้น entity ใหญ่เช่น customer ที่แยกหน้าได้)

### 2) Filter bar (`UCard class="mb-4"`)

```vue
<UCard class="mb-4">
  <div class="flex flex-wrap items-end gap-3">
    <UFormField :label="t('...filters.searchBy')" class="min-w-44">
      <USelectMenu v-model="searchField" :items="searchFieldOptions" value-key="value" class="w-full" />
    </UFormField>
    <UInput v-model="search" class="min-w-0 flex-1" icon="i-lucide-search" :placeholder="t('...filters.search')" />
    <UButton v-if="hasActiveFilters" variant="soft" color="neutral" icon="i-lucide-rotate-ccw" @click="clearFilters">
      {{ t('...filters.viewAll') }}
    </UButton>
  </div>
</UCard>
```

**State มาตรฐาน:**

| ref | หน้าที่ |
|-----|---------|
| `search` | ข้อความค้นหา |
| `searchField` | `'all'` \| field เฉพาะ |
| `roleTab` / `statusTab` | tab กรอง (`'all'` + ค่าอื่น) |
| `hasActiveFilters` | computed — มี filter ค้างอยู่ |
| `clearFilters()` | รีเซ็ตทุก filter + `resetPage()` |

**Filter logic:** `computed filteredItems` — กรอง tab ก่อน แล้วค่อย search ตาม `searchField`

**Pagination:** `usePagination(filteredItems)` — เปลี่ยน filter → `resetPage()` (หรือพึ่ง auto-reset ของ composable)

### 3) Tab กรองเหนือตาราง

```vue
<div
  class="flex flex-wrap gap-2 border-b border-gray-200 bg-gray-50/90 px-3 py-2.5 dark:border-gray-800 dark:bg-gray-900/60"
  role="tablist"
  :aria-label="t('...filters.roleTabs')"
>
  <button
    v-for="tab in roleTabs"
    :key="tab.value"
    type="button"
    role="tab"
    :aria-selected="roleTab === tab.value"
    :class="[
      appTableRoleTabBaseClass,
      appTableTextClass,
      roleTab === tab.value ? appTableRoleTabActiveClass : appTableRoleTabInactiveClass
    ]"
    @click="roleTab = tab.value"
  >
    {{ tab.label }}
  </button>
</div>
```

- ใช้ **`<button>` ธรรมดา** + class จาก `appFormUi` — ไม่ใช้ `UTabs`
- tab แรกมักเป็น `viewAll` (value `'all'`)

### 4) แถบนับจำนวน

```vue
<p
  class="border-b border-gray-200 px-3 py-2 text-gray-600 dark:border-gray-800 dark:text-gray-400"
  :class="appTableTextClass"
>
  {{ t('...filters.displayCount', { count: paginationTotal }) }}
</p>
```

### 5) ตาราง + action column

| คอลัมน์ | component / class |
|---------|-------------------|
| ข้อความหลัก | `AppDataTableTd` + `font-medium` (หรือ avatar + ชื่อ) |
| ข้อมูลรอง | `AppDataTableTd muted` |
| สถานะ / role | `UBadge variant="subtle"` + `appTableBadgeClass` |
| role องค์กร | `appPlatformRoleBadgeClass[role]` (เฉพาะ user) |
| แก้ไข | `AppIconButton icon="i-lucide-pencil"` + `@click="openEdit(row)"` |
| ลบ (ถ้ามี) | `AppIconButton color="error"` + `@click` + confirm |

- **แก้ไขเปิด modal** — ไม่ใช้ `:to` ไปหน้าแยก (ยกเว้น design กำหนด)
- คอลัมน์ action สุดท้าย: `<AppDataTableTh />` ว่าง + `align="right"`

### 6) Modal สร้าง/แก้ (page level)

```vue
<!-- ท้าย template ของ page — นอก table block -->
<SetupSystemUserFormModal
  v-model:open="formOpen"
  :user="editingUser"
  @saved="onSaved"
/>
```

| state | หน้าที่ |
|-------|---------|
| `formOpen` | `v-model:open` ของ modal |
| `editingUser` | `null` = สร้าง · object = แก้ |
| `openCreate()` | `editingUser = null; formOpen = true` |
| `openEdit(row)` | `editingUser = row; formOpen = true` |
| `onSaved()` | `refresh()` รายการ |

**ใน modal (`SystemUserFormModal`):**

- `AppDialog` size `2xl` + `AppDialogFooter`
- form `id="xxx-form"` grid `lg:grid-cols-2`
- section หัวข้อ: `<h3 class="text-sm font-semibold font-heading">`
- fields: `UFormField` + `:class="appFormFieldClass"` + `UInput size="lg" :ui="appInputUi"`
- error: `appFormErrorClass`
- save: `UButton type="submit" form="xxx-form"` ใน `#footer` ของ `AppDialogFooter`

### i18n keys (filters)

ใส่ใต้ namespace หน้านั้น เช่น `setup.systemUsers.filters.*`:

| Key | ตัวอย่าง |
|-----|----------|
| `filters.searchBy` | ค้นหาตาม |
| `filters.viewAll` | ดูทั้งหมด |
| `filters.byName` / `byEmail` / … | ตัวเลือก dropdown |
| `filters.search` | placeholder ช่องค้นหา |
| `filters.roleTabs` / `statusTabs` | aria-label แถบ tab |
| `filters.displayCount` | แสดง {count} รายการ |
| `filters.noResults` | ไม่พบรายการ |

### หน้าที่ใช้แล้ว

| หน้า | หมายเหตุ |
|------|----------|
| `/app/setup/system-users` | **แม่แบบหลัก** — modal create/edit |
| `/app/customer` | filter + status tabs · ฟอร์มแยกหน้า `/new` |
| `/app/setup/user-approvals` | ตารางอย่างเดียว |
| `/app/setup/roles` | table + grid |
| `/app/contacts` | ตารางพื้นฐาน |
| `/app/companies` | ตารางพื้นฐาน |

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

### Class ตาราง (`config/appFormUi.ts`)

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
| `AppDialog` | `components/AppDialog.vue` | modal มาตรฐาน — `v-model:open`, `title`, `size` · overlay ดำ fade (`bg-black/60`) |
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

## Charts

→ รายละเอียดเต็ม: **[CHARTS.md](./CHARTS.md)**

| Component | หน้าที่ |
|-----------|---------|
| `AppLineChart` | กราฟเส้นมาตรฐาน (nuxt-charts / vue-chrts) |
| `config/appChart.ts` | สี + padding + helpers |

---

## Checklist หน้า list ใหม่ (แบบ system-users)

- [ ] Page header: `font-heading` title + subtitle + ปุ่มสร้าง
- [ ] 4 สถานะ: loading / empty / has data / filter no results
- [ ] Filter: `UFormField` + `USelectMenu` + `UInput` search + ปุ่ม `viewAll` เมื่อ `hasActiveFilters`
- [ ] Tab กรอง: `appTableRoleTab*` บน `<button role="tab">`
- [ ] แถบ `displayCount` ก่อนตาราง
- [ ] `usePagination(filteredItems)` + `resetPage()` ใน `clearFilters`
- [ ] wrapper `border` + `AppDataTable embedded` + `AppPagination embedded`
- [ ] chip: `appTableBadgeClass` (+ `appPlatformRoleBadgeClass` ถ้าเป็น role)
- [ ] action: `AppIconButton` — edit เปิด modal หรือ route ตาม design
- [ ] modal form อยู่ **page level** (hoist — ไม่ซ้อน modal)
- [ ] i18n `filters.*` th + en
- [ ] อัปเดต CHANGELOG โฟลเดอร์ที่แก้

## Checklist หน้า list พื้นฐาน (ไม่มี filter tabs)

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

*อัปเดต: 2026-06-16*
