# Changelog — Frontend

→ [README.md](./README.md)

---

## ประวัติ

### 2026-06-17 — Customer CRUD RPC + Contact delete UI + DB-SCHEMA sync

- **ทำอะไร:** `create_company` / `update_company` + logs · ปุ่มลบ contact · sync DB-SCHEMA
- **Migration:** `20260608120040_companies_crud_rpc.sql`
- **Phase:** 1

### 2026-06-16 — Contact data_change_logs (RPC)

- **ทำอะไร:** `create_contact` / `update_contact` / `soft_delete_contact` → `data_change_logs` · `useContacts` เรียก RPC
- **Migration:** `20260608120039_contacts_crud_rpc.sql`
- **Phase:** 1

### 2026-06-16 — Contact list filter by customer (autocomplete)

- **ทำอะไร:** หน้ารายการผู้ติดต่อ — USelectMenu searchable กรองตามบริษัท/ลูกค้า
- **ไฟล์ที่กระทบ:** `pages/app/contact/index.vue`, i18n
- **Phase:** 1

### 2026-06-16 — Contact master UI + customer FK

- **ทำอะไร:** `/app/contact` list/new/view/edit · `company_id` required · migration `20260608120038_*`
- **Spec:** `docs/06-crm-schema/CONTACT-MASTER-FIELDS.md`
- **Phase:** 1

### 2026-06-16 — Sidebar inactive nav font (weight 400)

- **ทำอะไร:** เมนูไม่ active ใช้ `font-normal` (400) แทน `font-medium` (500) — IBM Plex โหลดแค่ 400/600
- **ไฟล์ที่กระทบ:** `AppSidebarNavItem.vue`, `main.css`
- **Phase:** 1

### 2026-06-16 — Tax section layout (WHT + credit ติดกัน)

- **ทำอะไร:** ย้าย WHT ไปคอล. 3 แถว 2 · วงเงินเครดิต + เครดิตคงเหลือ อยู่แถวล่างติดกัน
- **ไฟล์ที่กระทบ:** `MasterDataCustomerForm.vue`, `CUSTOMER-MASTER-FIELDS.md`
- **Phase:** 1

### 2026-06-16 — tax_vat → อัตราหัก ณ ที่จ่าย (WHT)

- **ทำอะไร:** เปลี่ยน dropdown จาก VAT 7%/0% เป็น WHT · slug `none`, `wht_3`, `wht_5`, `wht_0_5`, `wht_0_75`, `wht_1`, `wht_1_5`, `wht_2`, `wht_10`, `wht_15`
- **Migration:** `20260608120037_companies_tax_vat_wht_rates.sql`
- **Phase:** 1

### 2026-06-16 — Sidebar font ตรง content (IBM Plex Sans Thai)

- **ทำอะไร:** บังคับ `--font-sans` บน sidebar/header · แก้ `<button>` ไม่ inherit · ขนาดตัวอักษร nav ใช้ `appSidebarNavTextClass`
- **ไฟล์ที่กระทบ:** `main.css`, `AppSidebar*.vue`, `AppHeader.vue`, `appFormUi.ts`
- **Phase:** 1

### 2026-06-16 — Tax VAT dropdown

- **ทำอะไร:** `tax_vat` เป็น USelectMenu · slug `vat_7` / `vat_0` / `exempt` / `no_vat`
- **ไฟล์ที่กระทบ:** `masterCustomer.ts`, `MasterDataCustomerForm.vue`, `i18n`, migration `20260608120036_*`
- **Phase:** 1

### 2026-06-16 — Bill To: หลายที่อยู่ + default

- **ทำอะไร:** `company_bill_addresses` · UI เหมือน Ship To · `MasterDataCustomerAddressList`
- **ไฟล์ที่กระทบ:** migration `20260608120035_*`, `useCompanies.ts`, `MasterDataCustomerForm.vue`
- **Phase:** 1

### 2026-06-16 — Customer list: คอลัมน์ประเภท/โทร/email/เกรด/กลุ่มอุตสาหกรรม

- **ทำอะไร:** ขยายตารางหน้ารายการลูกค้า
- **ไฟล์ที่กระทบ:** `pages/app/customer/index.vue`
- **Phase:** 1

### 2026-06-16 — Individual customer: ล็อก segment + industry

- **ทำอะไร:** ประเภทบุคคลธรรมดา → กลุ่มอุตสาหกรรม = รายบุคคล · อุตสาหกรรม = ไม่ระบุ · CHECK ใน DB
- **ไฟล์ที่กระทบ:** `masterCustomer.ts`, `MasterDataCustomerForm.vue`, migration `20260608120034_*`
- **Phase:** 1

### 2026-06-16 — Ship To default address

- **ทำอะไร:** `is_default` ต่อ company · UI badge/ดาว/checkbox · RPC สำหรับโมดูลอื่น
- **ไฟล์ที่กระทบ:** migration `20260608120033_*`, `MasterDataCustomerForm.vue`, `useCompanies.ts`
- **Phase:** 1

### 2026-06-16 — Customer view + soft delete + log

- **ทำอะไร:** ดูรายละเอียด (คลิกชื่อ/ปุ่มตา) · ลบ soft delete ผ่าน RPC + `data_change_logs`
- **ไฟล์ที่กระทบ:** `MasterDataCustomerViewPage.vue`, routes `[id]/`, migration `20260608120032_*`
- **Phase:** 1

### 2026-06-16 — Customer master: migration + บันทึกครบฟิลด์

- **ทำอะไร:** รองรับคอลัมน์ companies ใหม่ + ship addresses · ลบ layout-only hint
- **ไฟล์ที่กระทบ:** `masterCustomer.ts`, `useCompanies.ts`, `MasterDataCustomerPage.vue`, `crm.ts`, `i18n`
- **Phase:** 1 · ต้องรัน migration `20260608120031_*` ก่อน

### 2026-06-16 — Customer website: auto https://

- **ทำอะไร:** `normalizeWebsiteUrl` — blur + ตอนบันทึก เติม `https://` ถ้าผู้ใช้ไม่ใส่ scheme
- **ไฟล์ที่กระทบ:** `utils/websiteUrl.ts`, `masterCustomer.ts`, `MasterDataCustomerForm.vue`
- **Phase:** 1

### 2026-06-16 — Customer Tax & Payment section ตาม mockup

- **ทำอะไร:** grid 3 คอล · Payment Code ลำดับ transfer/credit/cash/cheque · VAT dropdown · credit ชิดขวา
- **ไฟล์ที่กระทบ:** `MasterDataCustomerForm.vue`, `masterCustomer.ts`, `i18n`, `CUSTOMER-MASTER-FIELDS.md` §6
- **Phase:** 1

### 2026-06-16 — Customer Owner: dropdown + spec §5

- **ทำอะไร:** เลือกพนักงานจาก profiles (active ใน org) · บันทึก `owner_id` · จด MD รอ confirm rules
- **ไฟล์ที่กระทบ:** `MasterDataCustomerForm.vue`, `CUSTOMER-MASTER-FIELDS.md`, `i18n/en.json`
- **Phase:** 1

### 2026-06-16 — Customer Status dropdown (5 lifecycle values)

- **ทำอะไร:** active · inactive · prospect · churned · pending · USelectMenu · tabs/badge หน้ารายการ · migration DB
- **ไฟล์ที่กระทบ:** `masterCustomer.ts`, `MasterDataCustomerForm.vue`, `customer/index.vue`, `i18n`, migration `20260608120030_*`
- **Phase:** 1

### 2026-06-16 — Customer Sales Grade dropdown ตาม mockup

- **ทำอะไร:** vip · A · B · C · Prospect (รูปแบบ Code — Description) · ลบเกรด D
- **ไฟล์ที่กระทบ:** `masterCustomer.ts`, `MasterDataCustomerForm.vue`, `i18n/locales/*`, `CUSTOMER-MASTER-FIELDS.md`
- **Phase:** 1

### 2026-06-16 — Customer Industry dropdown + spec MD

- **ทำอะไร:** เปลี่ยน Industry จาก text input เป็น USelectMenu 10 ตัวเลือก + slug ลง `companies.industry`
- **ไฟล์ที่กระทบ:** `masterCustomer.ts`, `MasterDataCustomerForm.vue`, `i18n/locales/*`, `customer/index.vue`
- **Docs:** `docs/06-crm-schema/CUSTOMER-MASTER-FIELDS.md`
- **Phase:** 1

### 2026-06-16 — Customer Industry Segment options ตาม mockup

- **ทำอะไร:** เปลี่ยนเป็น Enterprise · SME · Startup · Individual (ลำดับตาม dropdown)
- **ไฟล์ที่กระทบ:** `config/masterCustomer.ts`, `i18n/locales/*`, `MasterDataCustomerForm.vue`
- **Phase:** 1

### 2026-06-16 — Customer form: แปล th ครบ + placeholder i18n

- **ทำอะไร:** ฟอร์มเพิ่ม/แก้ไขลูกค้า — sections, fields, options ภาษาไทย · ลบ hardcode placeholder
- **ไฟล์ที่กระทบ:** `i18n/locales/*`, `MasterDataCustomerForm.vue`
- **Phase:** 1

### 2026-06-16 — Customer list UI แบบ system-users (หน้า new/edit แยก)

- **ทำอะไร:** filter card + status tabs + ตาราง/pagination เหมือนผู้ใช้ในระบบ · เพิ่ม/แก้ไขเปิดหน้า `/new` และ `/:id` (ไม่ใช่ modal)
- **ไฟล์ที่กระทบ:** `pages/app/customer/*`, `MasterDataCustomerPage.vue`
- **Phase:** 1

### 2026-06-16 — Customer route `/app/customer` + filter UI แบบ users

- **ทำอะไร:** ย้ายออกจาก `/app/master-data/customer` · filter card + status tabs + ตารางเหมือน system-users
- **ไฟล์ที่กระทบ:** `pages/app/customer/*`, `masterDataMenu.ts`, `MasterDataCustomerPage.vue`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-16 — IBM Plex Sans Thai ทั้งระบบ

- **ทำอะไร:** `--font-sans` / `--font-heading` = IBM Plex Sans Thai · Google Fonts 400 + 600
- **ไฟล์ที่กระทบ:** `main.css`, `app.vue`
- **Phase:** 1

### 2026-06-16 — Master Data Customer: layout ฟอร์มครบ

- **ทำอะไร:** หน้ารายการ + new/edit ฟอร์ม 4 section (General / Tax / Bill To / Ship To) อ้างอิง layout system-users · บันทึกเฉพาะคอลัมน์ `companies` ที่มีอยู่
- **ไฟล์ที่กระทบ:** `master-data/customer/*`, `MasterDataCustomerForm.vue`, `AppFormSection.vue`, `masterCustomer.ts`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — Settings: ตารางข้อมูลบริษัทแสดงโลโก้

- **ทำอะไร:** คอลัมน์โลโก้ในมุมมองตาราง — แสดงรูปที่อัปโหลด (fallback ไอคอน building)
- **ไฟล์ที่กระทบ:** `SettingsCompanyProfilesTab.vue`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — Supabase Realtime: WebSocket บน Node < 22

- **ทำอะไร:** ติดตั้ง `ws` + ส่ง `clientOptions.realtime.transport` ใน `nuxt.config` — แก้ warning "Node.js 20 detected without native WebSocket"
- **ไฟล์ที่กระทบ:** `build/supabaseRealtimeTransport.ts`, `nuxt.config.ts`, `package.json`
- **Phase:** 1

### 2026-06-08 — Sidebar version จาก git commit

- **ทำอะไร:** แสดง `0.1.0 · fb58af4` ใน sidebar — อ่าน `git rev-parse --short HEAD` ตอน `dev`/`build`; CI ใช้ `NUXT_PUBLIC_GIT_COMMIT` ได้
- **ไฟล์ที่กระทบ:** `scripts/gitBuildInfo.mjs`, `nuxt.config.ts`, `useAppBuildInfo.ts`, `AppSidebarVersion.vue`, `appVersion.ts`
- **Phase:** 1

### 2026-06-08 — Settings: Auth Providers tab (ครบ 4 แท็บ)

- **ทำอะไร:** แท็บผู้ให้บริการเข้าสู่ระบบ — Microsoft 365 / Google / Azure AD / Username&Password; toggle + configure modal; tips
- **ไฟล์ที่กระทบ:** `SettingsAuthProvidersTab.vue`, `SettingsAuthProviderFormModal.vue`, `useOrgAuthProviders.ts`, `settings.vue`, `i18n/locales/*`
- **DB:** `20260608120029_org_auth_providers.sql`
- **Phase:** 1

### 2026-06-08 — Settings: Email Service (SMTP) tab

- **ทำอะไร:** แท็บบริการอีเมล — ฟอร์ม SMTP, บันทึก `settings.email`, ทดสอบการเชื่อมต่อ (validate Phase 1)
- **ไฟล์ที่กระทบ:** `SettingsEmailTab.vue`, `useOrgEmailSettings.ts`, `orgEmailSettings.ts`, `settings.vue`, `i18n/locales/*`
- **DB:** `20260608120028_org_email_settings.sql`
- **Phase:** 1

### 2026-06-08 — Settings: Notifications tab

- **ทำอะไร:** แท็บการแจ้งเตือน — toggle 6 ประเภท + ปุ่มส่งอีเมล (guard จนกว่า Email Service พร้อม)
- **ไฟล์ที่กระทบ:** `SettingsNotificationsTab.vue`, `useOrgNotificationSettings.ts`, `orgNotificationSettings.ts`, `settings.vue`, `i18n/locales/*`
- **DB:** `20260608120027_org_notification_settings.sql`
- **Phase:** 1

### 2026-06-08 — Image upload กลาง + โลโก้บริษัท

- **ทำอะไร:** `useImageUpload` / `useImageUploadState` / `AppImageUpload`; refactor avatar; อัปโหลดโลโก้ company profile
- **ไฟล์ที่กระทบ:** `config/imageUpload.ts`, `utils/imageUpload.ts`, `AppImageUpload.vue`, `useUserAvatar.ts`, `useOrgCompanyLogo.ts`, `SettingsCompanyProfileFormModal.vue`, `SystemUserFormModal.vue`
- **เอกสาร:** `docs/05-frontend/IMAGE-UPLOAD.md`
- **DB:** `20260608120026_org_images_storage.sql`
- **Phase:** 1

### 2026-06-08 — Settings: ข้อมูลบริษัท grid card + table toggle

- **ทำอะไร:** แท็บข้อมูลบริษัท — สลับมุมมองกล่อง (default) / ตาราง; card แสดงโลโก้ ชื่อ ภาษี สาขา ที่อยู่ ติดต่อ
- **ไฟล์ที่กระทบ:** `SettingsCompanyProfileCard.vue`, `SettingsCompanyProfilesTab.vue`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — Settings: ข้อมูลบริษัทหลายโปรไฟล์ (สาขา)

- **ทำอะไร:** แท็บข้อมูลบริษัท — รายการ + เพิ่ม/แก้ไข/ลบ หลาย company profile (สำนักงานใหญ่/สาขา); ตั้งค่าเริ่มต้นได้
- **ไฟล์ที่กระทบ:** `SettingsCompanyProfilesTab.vue`, `SettingsCompanyProfileFormModal.vue`, `useOrgCompanyProfiles.ts`, `orgCompanyProfile.ts`, `settings.vue`, `types/crm.ts`, `i18n/locales/*`
- **ลบ:** `SettingsCompanyInfoForm.vue`, `orgCompanyInfo.ts`
- **DB:** `20260608120025_org_company_profiles.sql`
- **Phase:** 1

### 2026-06-08 — Settings page: tabs + Company Info form

- **ทำอะไร:** `/app/setup/settings` — 4 แท็บ (ข้อมูลบริษัท / แจ้งเตือน / อีเมล / Auth); ฟอร์มข้อมูลบริษัท (superseded โดย multi-profile)
- **ไฟล์ที่กระทบ:** `settings.vue`, `SettingsTabSoon.vue`, `settingsTabs.ts`
- **DB:** `20260608120024_org_settings_company_info.sql`
- **Phase:** 1

### 2026-06-08 — sidebar: ปิด ข้อมูลหลัก / ตั้งค่าระบบ โดยค่าเริ่มต้น

- **ทำอะไร:** panel Master Data + Setup หุบไว้ — เปิดอัตโนมัติเฉพาะเมื่ออยู่ใน route ของ section นั้น
- **ไฟล์ที่กระทบ:** `AppSidebar.vue`
- **Phase:** 1

### 2026-06-08 — CRM scrollbar + menu ready badge

- **ทำอะไร:** scrollbar เล็กสีเขียวอ่อนใน `.crm-app`; `ready: true` สำหรับ active-sessions + user-approvals (เอา badge เร็ว ๆ นี้ออก)
- **กฎ:** `.cursor/rules/nuxt-frontend-pitfalls.mdc` §5 — หน้าพร้อมแล้วต้องตั้ง `ready: true` ใน menu config
- **ไฟล์ที่กระทบ:** `main.css`, `setupMenu.ts`, `SETUP-MENU.md`
- **Phase:** 1

### 2026-06-08 — app layout: sidebar scroll แยกจาก main

- **ทำอะไร:** ล็อกความสูง `h-dvh` — sidebar เลื่อนใน `nav` เอง เนื้อหาหลักเลื่อนใน `main` ไม่ scroll ทั้ง page
- **ไฟล์ที่กระทบ:** `layouts/app.vue`, `AppSidebar.vue`, `AppHeader.vue`, `assets/css/main.css`
- **Phase:** 1

### 2026-06-08 — Active Sessions: login / activity / ended columns

- **ทำอะไร:** แยกคอลัมน์ เข้าสู่ระบบ · ใช้งานล่าสุด · สิ้นสุด — logout แสดง `ended_at`; ปิด browser แสดง `last_seen` พร้อม (ประมาณ)
- **ไฟล์ที่กระทบ:** `active-sessions.vue`, `loginSessionDisplay.ts`, `types/crm.ts`, `i18n/locales/*`
- **DB:** `20260608120023_user_login_sessions_list_ended.sql`
- **Phase:** 1

### 2026-06-08 — Active Sessions page (Setup)

- **ทำอะไร:** หน้า `/app/setup/active-sessions` — ตาราง User / Device / Browser / IP / Last Login / Status; บันทึกเซสชันตอน login + heartbeat ใน app layout
- **ไฟล์ที่กระทบ:** `active-sessions.vue`, `useLoginSession.ts`, `userAgent.ts`, `login.vue`, `signup.vue`, `UserMenu.vue`, `layouts/app.vue`, `server/api/session/client-info.get.ts`, `i18n/locales/*`
- **DB:** `20260608120022_user_login_sessions.sql`
- **Phase:** 1

### 2026-06-08 — roles: org role code validation + hints

- **ทำอะไร:** validate รหัสบทบาทตอนสร้าง (ห้ามเว้นวรรค/ตัวใหญ่/ขีดกลาง, ต้องขึ้นต้นด้วยตัวอักษร, 2–49 ตัว) ตรงกับ DB constraint — ข้อความช่วย th/en
- **ไฟล์ที่กระทบ:** `utils/orgRoleCode.ts`, `OrgRoleFormModal.vue`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — roles: remove create-from-template UI

- **ทำอะไร:** เอา dropdown เทมเพลตออกจากฟอร์มเพิ่มบทบาท — สร้างบทบาทใหม่เป็น code + ชื่อ + สิทธิ์ว่างเท่านั้น; บทบาทระบบ 4 อันยัง seed จาก DB ตอนสร้าง org
- **สาเหตุ:** เทมเพลตซ้ำกับบทบาทที่ seed แล้ว และชน unique code
- **ไฟล์ที่กระทบ:** `OrgRoleFormModal.vue`, `config/orgRoleTemplates.ts`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — fix OrgRoleFormModal empty dialog (add role)

- **ทำอะไร:** แก้ `OrgRoleFormModal` / `OrgRoleDeleteModal` — ใช้ default slot ของ `AppDialog` (เดิม `#body` ไม่แสดงเนื้อหา); `AppDialog` รองรับ `#body` fallback
- **สาเหตุ:** `AppDialog` ส่งเฉพาะ default slot ไป `UModal#body` — ฟอร์มเพิ่มบทบาทว่าง
- **ไฟล์ที่กระทบ:** `OrgRoleFormModal.vue`, `OrgRoleDeleteModal.vue`, `AppDialog.vue`
- **Phase:** 1

### 2026-06-08 — AppDataTable header rounded top corners

- **ทำอะไร:** หัวตารางมน `rounded-t-lg` ซ้าย–ขวา–บน (`.app-data-table` ใน `main.css`)
- **ไฟล์ที่กระทบ:** `AppDataTable.vue`, `app/assets/css/main.css`
- **Phase:** 1

### 2026-06-08 — docs: SHARED-COMPONENTS.md

- **ทำอะไร:** เอกสาร component/config ใช้ร่วมทั้งระบบ — ตาราง, pagination, dialog, form, avatar
- **ไฟล์ที่กระทบ:** `docs/05-frontend/SHARED-COMPONENTS.md`, `docs/05-frontend/README.md`, `frontend/README.md`
- **Phase:** 1

### 2026-06-08 — AppPagination + usePagination (20 rows/page)

- **ทำอะไร:** component `AppPagination` + composable `usePagination` — 20 รายการต่อหน้า; ใช้กับตาราง system-users, contacts, companies, roles, user-approvals
- **ไฟล์ที่กระทบ:** `AppPagination.vue`, `usePagination.ts`, `config/pagination.ts`, `AppDataTable.vue` (embedded), หน้าตาราง CRM, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — system-users: inline role tabs above table

- **ทำอะไร:** tabs กรอง role เป็นกล่อง inline-block ชิดด้านบนตาราง (รวม border กับ `AppDataTable` embedded)
- **ไฟล์ที่กระทบ:** `pages/app/setup/system-users/index.vue`, `AppDataTable.vue`, `config/appFormUi.ts`, `i18n/locales/*`
- **Phase:** 1

### 2026-06-08 — system-users: role tabs + distinct role chip colors

- **ทำอะไร:** tabs กรองตามระดับองค์กร (ทั้งหมด / เจ้าของ / ผู้ดูแล / พนักงาน) พร้อมจำนวน; chip สีแยก owner (amber), admin (sky), employee (emerald)
- **ไฟล์ที่กระทบ:** `pages/app/setup/system-users/index.vue`, `config/appFormUi.ts`
- **Phase:** 1

### 2026-06-08 — AppDataTable font +1px

- **ทำอะไร:** ขนาดตัวอักษรในตารางทั้งระบบใหญ่ขึ้น 1px จาก `text-sm` เดิม (`calc(0.875rem + 1px)`)
- **ไฟล์ที่กระทบ:** `AppDataTable.vue`, `config/appFormUi.ts`
- **Phase:** 1

### 2026-06-08 — table badge chips: bold dark text

- **ทำอะไร:** chip ในตารางผู้ใช้ในระบบ — ตัวอักษรดำหนา (`appTableBadgeClass`) อ่านง่ายบนพื้น subtle
- **ไฟล์ที่กระทบ:** `config/appFormUi.ts`, `pages/app/setup/system-users/index.vue`
- **Phase:** 1

### 2026-06-08 — system-users create: default role employee

- **ทำอะไร:** เปิดฟอร์มสร้างผู้ใช้ใหม่ — default ระดับองค์กรเป็น «พนักงาน» (employee) แทนรายการแรกใน dropdown
- **ไฟล์ที่กระทบ:** `components/setup/SystemUserFormModal.vue`
- **Phase:** 1

### 2026-06-08 — password generate button + avatar delete from storage

- **ทำอะไร:** ปุ่มสร้างรหัสผ่าน — พื้นเขียวเข้ม (`bg-menu-section`) ตัวอักษรขาว; ลบรูปแล้วบันทึก — ลบไฟล์จริงใน Supabase Storage (path จาก URL + list โฟลเดอร์ org)
- **ไฟล์ที่กระทบ:** `AppPasswordFieldGroup.vue`, `useUserAvatar.ts`, `SystemUserFormModal.vue`
- **Phase:** 1

### 2026-06-08 — system-users list: search filters

- **ทำอะไร:** เพิ่ม filter ค้นหาจากชื่อ / อีเมล / username และตัวเลือก «ดูข้อมูลทั้งหมด» บนหน้ารายการผู้ใช้ในระบบ
- **ไฟล์ที่กระทบ:** `pages/app/setup/system-users/index.vue`, `i18n/locales/th.json`, `i18n/locales/en.json`
- **Phase:** 1

### 2026-06-08 — system-users avatar: webp + resize before upload

- **ทำอะไร:** ย้าย `AppAvatarUpload` ไปคอลัมน์ขวา และแปลงรูปเป็น `webp` พร้อมลดขนาดด้วย `canvas` ก่อนอัปโหลดขึ้น Storage
- **ไฟล์ที่กระทบ:** `app/components/setup/SystemUserFormModal.vue`, `app/composables/useUserAvatar.ts`
- **Phase:** 1


### 2026-06-08 — fix system-users/new route + edit modal component name

- **ทำอะไร:** ย้าย list → `system-users/index.vue` (แก้ nested route กับ `/new`); ใช้ `SetupSystemUserFormModal` ใน template
- **สาเหตุ:** Nuxt ไม่ register `/system-users/new` เมื่อมีทั้ง `system-users.vue` + `system-users/new.vue`; ชื่อ component ผิดทำให้ dialog แก้ user ไม่ขึ้น
- **ไฟล์ที่กระทบ:** `pages/app/setup/system-users/index.vue`, `.cursor/rules/nuxt-frontend-pitfalls.mdc`
- **Phase:** 1

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
