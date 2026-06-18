# QA Guide — คู่มือทดสอบ (Phase 1)

> **สำหรับ:** Tester · QA · Dev ก่อนส่งงาน · Agent ที่รับงานทดสอบ  
> **Phase:** 1 — Master Data ลูกค้า + ผู้ติดต่อ (+ Setup / Auth พื้นฐาน)  
> **อัปเดต:** 2026-06-17

> **กฎโปรเจกต์:** ทุกครั้งที่ทำงาน tester / QA — **อ่านไฟล์นี้ก่อน** แล้วทำตามชั้น 0–7 (Cursor rule: `.cursor/rules/qa-testing.mdc`)

---

## Agent สำหรับ QA — Claude เท่านั้น

| รายการ | กำหนด |
|--------|--------|
| **โมเดล** | รอบทดสอบ / retest ใช้ **Cursor Agent = Claude** (Sonnet หรือ Opus) เท่านั้น |
| **ห้าม** | ใช้ Composer · GPT · Gemini หรือโมเดลอื่นรัน checklist QA แทน Claude |
| **Session** | หนึ่งรอบ QA (ชั้น 0→7) ควรจบใน agent Claude เดียวกัน — สลับโมเดลกลางรอบแล้วสรุปต่อไม่ได้ |
| **สั่งงาน** | พิมพ์ **ทดสอบ · QA · retest · หาบัค** ในแชท Claude เพื่อให้ agent โหลด rule `qa-testing.mdc` |

งาน implement โค้ดไม่จำกัดโมเดล — กฎนี้ใช้เฉพาะ **งาน tester**

---

## อ่านก่อนเริ่ม

| เอกสาร | ใช้เมื่อ |
|--------|----------|
| [TEST-ACCOUNTS.md](./TEST-ACCOUNTS.md) | Login · บัญชี · แก้ migration error |
| [QA-CUSTOMER-CONTACT.md](./QA-CUSTOMER-CONTACT.md) | Checklist ละเอียดโมดูล ลูกค้า + ผู้ติดต่อ |
| [QA-LEADS.md](./QA-LEADS.md) | Checklist สร้างลีด — ลูกค้าในระบบ + ลูกค้าใหม่ |
| [QA-OPPORTUNITIES.md](./QA-OPPORTUNITIES.md) | Checklist แปลงลีด → โอกาสขาย |
| [DB-README.md](../../supabase/DB-README.md) | ลำดับ migration บน Supabase |
| [permissions.md](../06-crm-schema/permissions.md) | สิทธิ์ role × ตาราง |

**URL ทดสอบ:** `http://localhost:3000` (หรือ port ที่ dev แจ้ง เช่น 3001)  
**Login:** `/login`

---

## ชั้นการทดสอบ (Testing Layers)

ทดสอบ **จากล่างขึ้นบน** — ชั้นล่าง fail แล้วอย่ารีบทดสอบชั้นบน (จะเสียเวลาและสรุปบัคผิด)

```text
                    ┌─────────────────────┐
  ชั้น 7            │  Bypass / นอกระบบ  │  API ที่ Phase 1 ไม่มี · ยิงทะลุ
                    ├─────────────────────┤
  ชั้น 6            │  Audit / Log        │  data_change_logs
                    ├─────────────────────┤
  ชั้น 5            │  E2E Flow            │  journey ผู้ใช้จริง
                    ├─────────────────────┤
  ชั้น 4            │  Permission / Role  │  owner · admin · employee
                    ├─────────────────────┤
  ชั้น 3            │  UI (Browser)        │  หน้าจอ · modal · i18n
                    ├─────────────────────┤
  ชั้น 2            │  API (RPC)           │  create/update/delete/restore
                    ├─────────────────────┤
  ชั้น 1            │  Database            │  migration · RLS · function มีครบ
                    ├─────────────────────┤
  ชั้น 0            │  Environment         │  dev server · env · login
                    └─────────────────────┘
```

| ชั้น | ชื่อ | ทำอะไร | ผ่านเมื่อ | ใช้เครื่องมือ |
|:----:|------|--------|-----------|---------------|
| **0** | Environment | dev รันได้ · login ได้ · migration ครบ | ไม่มี ERROR/WARN ใน terminal · เข้า `/app` ได้ | Terminal · Browser |
| **1** | Database | RPC / policy บน Supabase ตรง repo | SQL / RPC ไม่ 404 · RLS ตาม spec | Supabase SQL Editor |
| **2** | API | เรียก RPC ตรง (ไม่ผ่าน UI) | CRUD + soft delete + restore + cascade ถูก | curl / Postman |
| **3** | UI | กดใช้งานบนหน้าจอ | ฟอร์ม · รายการ · modal · ข้อความ error ชัด | Browser (th + en) |
| **4** | Permission | แยก role | owner/admin เห็น/ทำได้ · employee ถูกบล็อกตาม spec | Browser 2 บัญชี |
| **5** | E2E Flow | flow ครบหลายหน้า | journey จบโดยไม่ติด state ค้าง | Browser |
| **6** | Audit | บันทึก log | Setup → กิจกรรมผู้ใช้ มี log ตรง action | Browser + SQL |
| **7** | Bypass / นอกระบบ | ยิง endpoint/RPC **ที่ไม่อยู่ใน Phase 1** · ทะลุ UI/auth | **ทะลุไม่ได้** — 404 / 401 / 403 / RLS block | curl · DevTools Network |

**กฎ:** บันทึกผล **ทีละชั้น** — ใส่ `[ ]` / `[x]` ใน [QA-CUSTOMER-CONTACT.md](./QA-CUSTOMER-CONTACT.md) หรือสร้างรายงานใหม่ต่อรอบ  
**ชั้น 7:** ทำหลัง **ชั้น 2** (รู้ RPC ที่ถูกต้องแล้ว) — ทุก release / หลังเพิ่ม route ใหม่

---

## ชั้น 0 — Environment

### Checklist

- [ ] `nvm use` → Node 24 · `cd frontend && npm run dev`
- [ ] Terminal **ไม่มี** `ERROR` / `WARN` (ยกเว้น user ยอมรับ known issue)
- [ ] `frontend/.env` มี `NUXT_PUBLIC_SUPABASE_URL` + key
- [ ] Login owner: `browser-test-owner@crm-kai.test` / `testpass123` → `/app`
- [ ] Migration ชุด Master Data บน Supabase remote (อย่างน้อย **39–44** ถ้าทดสอบ contact + restore):

| ลำดับ | ไฟล์ | ต้องมีเมื่อทดสอบ |
|------|------|------------------|
| 39 | `20260608120039_contacts_crud_rpc.sql` | Contact CRUD |
| 40 | `20260608120040_companies_crud_rpc.sql` | Customer create/update log |
| 41 | `20260608120041_soft_delete_company_cascade_contacts.sql` | ลบลูกค้า + cascade contact |
| 42 | `20260608120042_fix_soft_delete_contact_snapshot.sql` | ลบลูกค้าที่มี contact |
| 43 | `20260608120043_restore_master_data.sql` | กู้คืน + แท็บ ถูกลบ |
| 44 | `20260608120044_deleted_records_admin_only.sql` | แท็บ ถูกลบ เฉพาะ owner/admin |
| 45 | `20260608120045_contacts_single_main_contact.sql` | ผู้ติดต่อหลัก 1 คนต่อลูกค้า |

หลัง apply: `NOTIFY pgrst, 'reload schema';`

### ผลที่บันทึก

| รายการ | PASS / FAIL | หมายเหตุ |
|--------|-------------|----------|
| Dev server | | |
| Login owner | | |
| Migration 39–44 | | |

---

## ชั้น 1 — Database

### ตรวจ function มีครบ (SQL Editor)

```sql
SELECT p.proname
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'create_company', 'update_company', 'soft_delete_company', 'restore_company',
    'create_contact', 'update_contact', 'soft_delete_contact', 'restore_contact',
    'contact_log_snapshot', 'company_log_snapshot'
  )
ORDER BY 1;
-- คาดหวัง: 10 แถว
```

### ตรวจ RLS — employee ไม่เห็น soft-deleted

```sql
-- รันใน session ของ employee (หรือทดสอบผ่าน API ชั้น 2)
-- คาดหวัง: 0 แถวที่ deleted_at IS NOT NULL สำหรับ employee
```

### Checklist

- [ ] RPC ครบ 10 ตัวด้านบน
- [ ] `restore_*` มี `is_admin_or_owner()` ใน function body
- [ ] Policy `companies_select` / `contacts_select` — employee เห็นแค่ `deleted_at IS NULL`

---

## ชั้น 2 — API (RPC)

Login เอา JWT ก่อน (หรือใช้ Browser Network tab ดู response)

### Customer

| # | RPC | Input สั้น ๆ | คาดหวัง |
|---|-----|--------------|---------|
| A1 | `create_company` | name, email, phone | 200 + uuid |
| A2 | `update_company` | id + payload | 200 |
| A3 | `soft_delete_company` | id ไม่มี contact | 200 |
| A4 | `soft_delete_company` | id **มี** contact | 200 + contact cascade |
| A5 | `restore_company` | id ที่ลบแล้ว | 200 + contact cascade กลับ |

### Contact

| # | RPC | คาดหวัง |
|---|-----|---------|
| B1 | `create_contact` | 200 (ไม่ใช่ 404) |
| B2 | `update_contact` | 200 |
| B3 | `soft_delete_contact` | 200 |
| B4 | `restore_contact` | 200 ถ้าลูกค้ายัง active |
| B5 | `create_contact` ชี้ลูกค้าที่ลบแล้ว | error `Customer is deleted` |

### Permission (API)

| # | RPC | Role | คาดหวัง |
|---|-----|------|---------|
| P1 | `restore_company` | employee | 403 / Forbidden |
| P2 | `list deleted` via REST | employee | 0 rows |

---

## ชั้น 3 — UI (Browser)

### ลูกค้า `/app/customer`

| # | กรณี | ขั้นตอน | คาดหวัง |
|---|------|---------|---------|
| U-C1 | รายการ | เปิด list | แสดงรายการ · search · status tabs |
| U-C2 | สร้าง | `/app/customer/new` | บันทึกได้ → หน้า view |
| U-C3 | ดู / แก้ | view → edit | ฟิลด์ครบ · บันทึกได้ |
| U-C4 | ลบ | view → Delete modal | ยืนยัน · หายจาก list · modal ยกเลิก **ปุ่มเดียว** |
| U-C5 | Panel ผู้ติดต่อ | view ลูกค้า | รายชื่อ contact · ปุ่ม Add → modal · **ไม่มี** select ลูกค้า |
| U-C6 | แท็บ ถูกลบ | owner login | เห็นแท็บ ใช้งาน/ถูกลบ |
| U-C7 | กู้คืน | แท็บ ถูกลบ → Restore | กลับแท็บ ใช้งาน · contact cascade กลับ |

### ผู้ติดต่อ `/app/contact`

| # | กรณี | คาดหวัง |
|---|------|---------|
| U-T1 | List + filter ลูกค้า | autocomplete ทำงาน |
| U-T2 | สร้าง / แก้ / ลบ | CRUD ครบ · error message จาก server |
| U-T3 | แท็บ ถูกลบ + restore | เหมือน U-C6/U-C7 |
| U-T4 | i18n | สลับ th/en ข้อความ UI ไม่ hardcode |

---

## ชั้น 4 — Permission / Role

| บัญชี | role | ใช้ทดสอบ |
|--------|------|----------|
| `browser-test-owner@crm-kai.test` | owner | ครบทุกอย่าง |
| (สร้างใน Setup → ผู้ใช้) | admin | เหมือน owner เรื่อง archive tabs |
| (สร้างใน Setup → ผู้ใช้) | employee | **ไม่เห็น** แท็บ ใช้งาน/ถูกลบ · restore ไม่ได้ |

### Checklist employee

- [ ] `/app/customer` — **ไม่มี** แท็บ ใช้งาน/ถูกลบ
- [ ] `/app/contact` — **ไม่มี** แท็บ ใช้งาน/ถูกลบ
- [ ] ลบ/สร้าง ตาม org role permission (ถ้ามีสิทธิ์ module)

---

## ชั้น 5 — E2E Flow (แนะนำ 3 flow)

### Flow 1 — ลูกค้าใหม่ + ผู้ติดต่อจากหน้าลูกค้า

1. สร้างลูกค้า  
2. หน้า view → Add contact (modal)  
3. ตรวจ contact ใน panel + `/app/contact`  
4. แก้ contact  
5. ลบ contact อย่างเดียว → ลูกค้ายังอยู่  

### Flow 2 — ลบลูกค้า cascade

1. ลูกค้ามี ≥1 contact  
2. ลบลูกค้า (modal แจ้ง contact ถูกลบด้วย)  
3. contact หายจาก list active  
4. owner → แท็บ ถูกลบ → กู้ลูกค้า → contact กลับ  

### Flow 3 — สิทธิ์

1. employee login → ไม่เห็น archive tabs  
2. owner login → เห็นและกู้คืนได้  

---

## ชั้น 6 — Audit (`data_change_logs`)

| Action | ดูที่ | คาดหวัง |
|--------|-------|---------|
| สร้าง/แก้/ลบ ลูกค้า | Setup → กิจกรรมผู้ใช้ | entity `companies` |
| สร้าง/แก้/ลบ ผู้ติดต่อ | เดียวกัน | entity `contacts` |
| ลบลูกค้า cascade | log contact | `metadata.cascade = true` |
| กู้คืน | log update | `metadata.restore = true` |

---

## ชั้น 7 — Bypass / API นอกระบบ (Penetration)

> **เป้าหมาย:** พิสูจน์ว่า **ยิงทะลุไม่ได้** — endpoint / RPC ที่ Phase 1 **ไม่มี** ต้องไม่เปิด CRM · ไม่ login ต้องไม่ mutate · ทะลุ UI ต้องโดน RLS/RPC บล็อก

### ขอบเขต Phase 1 (สิ่งที่ **ไม่มี** ในระบบ)

| ไม่มี | หมายเหตุ |
|------|----------|
| Node CRM API | `api/` เป็น scaffold — มีแค่ `GET /health` |
| `/register` · provision · tenant config | Phase 3+ |
| Nuxt server CRM routes | มีแค่ `GET /api/session/client-info` |
| Service role ใน browser | frontend ใช้ **anon key** เท่านั้น |

CRM จริง → **Supabase PostgREST + RPC** ผ่าน JWT เท่านั้น (ดู [phase1-only.md](../09-flows/phase1-only.md))

### เตรียมตัว

```bash
# จาก frontend/.env
export SUPABASE_URL="https://xxx.supabase.co"
export ANON_KEY="sb_publishable_..."
# JWT หลัง login — copy จาก DevTools → Application → localStorage
# หรือ Network tab  header Authorization: Bearer ...
export ACCESS_TOKEN="eyJ..."
```

### 7A — Endpoint ที่ไม่อยู่ในระบบ (ต้อง **ไม่** ได้ CRM)

| # | ยิงไปที่ | Method | คาดหวัง (PASS = ทะลุไม่ได้) |
|---|----------|--------|------------------------------|
| X1 | `http://localhost:4000/health` | GET | **200** — มีแค่ health check |
| X2 | `http://localhost:4000/api/companies` | GET/POST | **404** หรือไม่มี route CRM |
| X3 | `http://localhost:4000/register` | POST | **404** |
| X4 | `http://localhost:3000/api/companies` | GET | **404** (Nuxt ไม่มี route นี้) |
| X5 | `http://localhost:3000/api/session/client-info` | GET | **200** แต่ได้แค่ `{ ip }` — ไม่มี CRM data |

```bash
# X2 ตัวอย่าง
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4000/api/companies
# คาดหวัง: 404
```

### 7B — Supabase โดยไม่ login / token ปลอม

| # | กรณี | คาดหวัง |
|---|------|---------|
| X6 | REST `GET /rest/v1/companies` — มีแค่ `apikey` + `Authorization: Bearer $ANON_KEY` (ไม่ใช่ user JWT) | ไม่ได้ข้อมูล org · `[]` หรือ error |
| X7 | RPC `restore_company` — ไม่ส่ง `Authorization` | **401** |
| X8 | RPC ชื่อปลอม `POST /rest/v1/rpc/fake_crm_api` | **404** / function not found |
| X9 | JWT หมดอายุ / แก้ payload แล้วยิงใหม่ | **401** JWT invalid |

```bash
# X6
curl -s "$SUPABASE_URL/rest/v1/companies?select=id,name&limit=5" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY"
# คาดหวัง: [] หรือไม่ leak ข้อมูลลูกค้า

# X8
curl -s -o /dev/null -w "%{http_code}\n" \
  -X POST "$SUPABASE_URL/rest/v1/rpc/fake_crm_api" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
# คาดหวัง: 404
```

### 7C — ทะลุ UI (ยิง Supabase ตรง แต่ไม่ใช่ flow ที่แอปออกแบบ)

| # | กรณี | Role | คาดหวัง |
|---|------|------|---------|
| X10 | RPC `restore_company` | employee JWT | **403** / Forbidden |
| X11 | RPC `admin_create_org_user` | employee JWT | **403** |
| X12 | REST `GET companies?deleted_at=not.is.null` | employee JWT | **0 rows** (ไม่เห็น archive) |
| X13 | REST `PATCH companies` เปลี่ยน `org_id` เป็นค่าปลอม | owner JWT | **0 rows updated** / RLS block |
| X14 | REST `GET companies?id=eq.<uuid org อื่น>` | owner JWT | **0 rows** (ข้าม org ไม่ได้) |

```bash
# X10
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/restore_company" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $EMPLOYEE_JWT" \
  -H "Content-Type: application/json" \
  -d '{"p_company_id":"00000000-0000-0000-0000-000000000001"}'
# คาดหวัง: error สิทธิ์ ไม่ใช่ 200
```

### 7D — Secret / key ห้ามรั่ว

| # | ตรวจ | คาดหวัง |
|---|------|---------|
| X15 | ค้นใน frontend bundle / `.env` — ไม่มี `service_role` | ไม่พบ |
| X16 | DevTools Sources — ไม่มี Supabase service key | ไม่พบ |
| X17 | ยิงด้วย service role (ถ้า tester มีใน Supabase dashboard **เท่านั้น**) — ยืนยันไม่ embed ใน app | แยกจาก client test |

### 7E — Integrity (ทางเลือก — รายงานถ้าพบ)

แอปออกแบบให้ mutate ผ่าน **RPC** เพื่อ audit log — ถ้ายิง REST INSERT/UPDATE ตรงแล้ว**สำเร็จโดยไม่มี log** ให้บันทึกเป็น **finding** (ไม่ใช่ PASS ชั้น 7 ถ้า policy ยังเปิด)

| # | กรณี | คาดหวัง ideal |
|---|------|----------------|
| X18 | `POST /rest/v1/companies` ตรง (ไม่ผ่าน `create_company`) | block หรือมี finding ว่า bypass audit ได้ |

---

### Checklist ชั้น 7

- [ ] X1–X5 — API/route นอกระบบ ไม่เปิด CRM
- [ ] X6–X9 — ไม่ login / RPC ปลอม ทะลุไม่ได้
- [ ] X10–X14 — ทะลุสิทธิ์ / ข้าม org ไม่ได้
- [ ] X15–X16 — ไม่รั่ว service role
- [ ] X18 (optional) — บันทึกถ้า REST ตรง bypass audit ได้

**PASS ชั้น 7:** ทุก X1–X16 ทะลุไม่ได้ตาม Expected · ไม่มีข้อมูล org อื่นรั่ว

---

## วิธีบันทึกผล / แจ้งบัค

### สรุปรอบทดสอบ (คัดลอกไปรายงาน)

```markdown
## QA Run — YYYY-MM-DD
- **Tester:** ชื่อ
- **Env:** local:3000 · Supabase project xxx
- **Migration:** 39–44 applied  yes/no

| ชั้น | ผล | หมายเหตุ |
|------|-----|----------|
| 0 Environment | PASS/FAIL | |
| 1 Database | | |
| 2 API | | |
| 3 UI | | |
| 4 Permission | | |
| 5 E2E | | |
| 6 Audit | | |
| 7 Bypass / นอกระบบ | | |
```

### รูปแบบบัค (1 บัค = 1 บล็อก)

| ฟิลด์ | ตัวอย่าง |
|-------|----------|
| **ID** | BUG-CC-01 |
| **ชั้น** | 2 API · **7 Bypass** |
| **โมดูล** | ลูกค้า |
| **Repro** | ขั้นตอนสั้น ๆ |
| **Expected** | … |
| **Actual** | error message / screenshot |
| **Severity** | Blocker / Major / Minor |

---

## โมดูล Master Data — checklist ละเอียด

→ [QA-CUSTOMER-CONTACT.md](./QA-CUSTOMER-CONTACT.md) (matrix + บัคที่เคยพบ + retest)

---

## Agent / CI (อนาคต)

| ชั้น | Automate ได้ |
|------|----------------|
| 0–1 | script ตรวจ migration + RPC exists |
| 2 | curl suite หลัง login |
| **7** | curl script X1–X14 (negative tests) |
| 3–5 | Playwright / browser MCP |
| 6 | query `data_change_logs` หลัง seed action |

Phase 1 ใช้ **manual ตามชั้น** เป็นหลัก
