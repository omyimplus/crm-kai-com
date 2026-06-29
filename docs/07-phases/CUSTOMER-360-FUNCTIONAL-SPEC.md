# Customer 360 — Functional Specification (ลูกค้า) + Gap Analysis

> **ที่มา:** `Functional Specification.docx` (ลูกค้า) — วิเคราะห์เทียบ **CRM Kai** ณ 2026-06-22  
> **สถานะโปรเจกต์:** Phase 1 Master Data ✅ · CRM Menu บางส่วน implement แล้ว (Tasks, Leads, Opportunities)  
> **อ้างอิงสถานะ code:** [PROJECT-STATUS.md](../00-overview/PROJECT-STATUS.md) · [tables.md](../06-crm-schema/tables.md)

---

## สรุปสั้น

เอกสารลูกค้าอธิบาย **Customer 360** เป็นศูนย์กลางข้อมูลลูกค้าแบบครบวงจร (Sales + Service + Contract + Asset + Renewal + AI) — ใกล้กับทิศทาง **demo KuTo** ที่เรากำลังทำ UI mock อยู่

| กลุ่ม | สรุป |
|--------|------|
| **ตรง/ใกล้เคียงแล้ว** | ลูกค้า (master), ผู้ติดต่อ, ลีด, โอกาสขาย, งาน (Tasks), สิทธิ์แบบ org role, ข้อมูลหลัก (สินค้า/หมวด/ทีมขาย/แหล่งลีด ฯลฯ) |
| **มีแต่ยังไม่ครบ** | หน้า Customer 360 รวมแท็บ, Dashboard KPI จริง, Activity timeline แบบ CRM เต็ม, ฟิลด์ลูกค้า/ผู้ติดต่อบางตัว |
| **ยังไม่มี (เมนู/Coming soon)** | ใบเสนอราคา, สัญญา/Renewal, Asset/Installed Base, Ticket, เอกสาร, Integration |
| **Phase 2–3 ตาม spec ลูกค้า** | AI Insight, Automation, ERP/365/LINE, Health Score คำนวณจริง |

**สัญลักษณ์**

| สัญลักษณ์ | ความหมาย |
|-----------|----------|
| ✅ | มีในระบบแล้ว · ใช้งานได้ (อาจชื่อ/รายละเอียดต่างเล็กน้อย) |
| 🟡 | มีบางส่วน / โครงสร้างใกล้เคียง · ยังไม่ครบตาม spec |
| ⏳ | UI mock / scaffold เท่านั้น |
| ❌ | ยังไม่มีใน schema + UI |
| 🔮 | ลูกค้าวาง Phase 2–3 · ยังไม่ implement |

---

## 1. วัตถุประสงค์ Customer 360

**Spec:** หน้าเดียวเห็น บริษัท · ผู้ติดต่อ · Opp · Quotation · สัญญา · Asset · Ticket · กิจกรรม · รายได้ · Health · Upsell

| รายการ | CRM Kai |
|--------|---------|
| ศูนย์กลางข้อมูลลูกค้าแบบครบวงจร | 🟡 แยกเป็น Master Data + CRM Menu · **ยังไม่มี route `/app/customer/:id/360`** |
| Dashboard mock (KPI + ตารางลูกค้า + แท็บ 360 + AI) | ⏳ `DashboardMockView` บน `/app` — ข้อมูลจำลอง |
| Customer 360 ใน demo KuTo | ⏳ แท็บ + widget ใน mock เท่านั้น |

---

## 2. User Roles (สิทธิ์)

**Spec:** Sales User · Sales Manager · Service Agent · Engineer · Finance · Admin · Executive

| Role (spec) | CRM Kai | หมายเหตุ |
|-------------|---------|----------|
| Sales User | 🟡 | `org_roles` + permission `app.lead` / `app.opportunity` / `master.customer` ฯลฯ — ไม่มี template ชื่อ Sales User ตรง ๆ |
| Sales Manager | 🟡 | ทำได้ด้วย org role +สิทธิ์กว้างขึ้น · ไม่มี Forecast/Approval workflow |
| Service Agent | ❌ | ยังไม่มีโมดูล Ticket/Service |
| Engineer | ❌ | ยังไม่มี Asset/Ticket assignment |
| Finance | 🟡 | ดูลูกค้า/เครดิตใน master ได้บางส่วน · ไม่มี Invoice module |
| Admin | ✅ | `owner` / `admin` + Setup (users, roles, master) |
| Executive | ⏳ | Dashboard executive ยังเป็น mock |

**ของเรา:** Platform role (`owner` / `admin` / `employee`) + **org_roles** แบบกำหนด permission ราย key — ยืดหยุ่นกว่า spec แต่ต้อง **ออกแบบ template บทบาท** ให้ตรงลูกค้าเอง

---

## 3. Customer 360 — Header (สรุปด้านบน)

| ฟิลด์ (spec) | CRM Kai (`companies`) | สถานะ |
|--------------|----------------------|--------|
| Customer Name | `name` | ✅ |
| Customer Code | — | ❌ ยังไม่มี auto number (มี `job_code` เฉพาะ lead/opp/task) |
| Customer Type | `customer_type` | 🟡 เราใช้ `company` / `individual` · spec ใช้ Corporate/Government/Education/… |
| Industry | `industry_segment` + `industry` | ✅ |
| Account Owner | `owner_id` | ✅ |
| Customer Status | `status` | 🟡 มี lifecycle (active/inactive/prospect/…) · ยังไม่มี `blacklist` ชัดใน enum |
| Customer Tier | `sales_grade` | 🟡 คล้าย Platinum/Gold/… แต่ชื่อฟิลด์ต่าง |
| Credit Term | Tax & Payment section | 🟡 มี payment term / credit บางส่วน · ไม่ครบทุกค่า spec |
| Last / Next Activity | — | ❌ ยังไม่ aggregate ที่หน้าลูกค้า |
| Total Revenue | — | ❌ |
| Open Pipeline | — | 🟡 คำนวณได้จาก `opportunities` แต่ยังไม่แสดงบนหน้า 360 |
| Open Ticket | — | ❌ |

---

## 4. แท็บ Customer 360 (10+ แท็บ)

### Tab 1 — Overview

| Widget (spec) | CRM Kai |
|---------------|---------|
| Customer Profile | ✅ ฟอร์มลูกค้า `/app/customer` |
| Revenue Summary | ❌ |
| Open Opportunities | 🟡 รายการ opp แยก `/app/opportunities` · filter ตามลูกค้ายังไม่รวมใน 360 |
| Active Contracts | ❌ |
| Renewal Alert | ⏳ mock dashboard |
| Open Tickets | ⏳ mock dashboard |
| Installed Assets | ❌ |
| Recent Activities | 🟡 `tasks` + legacy `activities` · ยังไม่รวม timeline ต่อลูกค้า |
| Customer Health Score | ⏳ mock badge |
| AI Recommendation | ⏳ mock panel |

### Tab 2 — Company Information

| กลุ่มฟิลด์ (spec) | CRM Kai |
|-------------------|---------|
| Company Name, Tax ID, Branch, Website, Phone, Email, Address | 🟡 ส่วนใหญ่มีใน [CUSTOMER-MASTER-FIELDS.md](../06-crm-schema/CUSTOMER-MASTER-FIELDS.md) · Province/Country แยกละเอียดน้อยกว่า spec |
| Customer Source | 🟡 ผ่าน Lead → `lead_sources` master · ไม่เก็บบน company โดยตรงทุก case |
| Customer Grade / Tier | 🟡 `sales_grade` |
| Credit Limit / Term | 🟡 Tax & payment |
| Account Owner | ✅ `owner_id` |
| Service / Engineer / Renewal Owner | ❌ มีแค่ owner เดียว |

### Tab 3 — Contacts

| ฟิลด์/ฟังก์ชัน (spec) | CRM Kai |
|------------------------|---------|
| Full Name, Position, Department, Email, Mobile | ✅ [CONTACT-MASTER-FIELDS.md](../06-crm-schema/CONTACT-MASTER-FIELDS.md) |
| Office Phone | 🟡 ใช้ `phone` |
| LINE ID | ❌ |
| Decision Role | 🟡 `contact_role`: decision_maker, influencer, user, gatekeeper · ไม่มี purchasing/IT |
| Primary Contact | ✅ `is_main_contact` (1 ต่อลูกค้า) |
| Contact Status Active/Inactive | 🟡 soft delete · ไม่มี status แยก |
| ประวัติติดต่อรายบุคคล | ❌ |
| เชื่อม Opp / Quotation / Ticket | 🟡 Opp ผ่าน company · ที่เหลือ ❌ |

### Tab 4 — Opportunities

| รายการ (spec) | CRM Kai |
|---------------|---------|
| Opp list ต่อลูกค้า | 🟡 filter ได้ใน list · ยังไม่ embed ใน 360 |
| สร้าง Opp จาก Customer 360 | 🟡 `/app/opportunities/new` + เลือกลูกค้า · ไม่มีปุ่มจากหน้า 360 |
| Stage / Amount / Probability / Close Date / Owner | ✅ [OPPORTUNITIES-MODULE.md](../05-frontend/OPPORTUNITIES-MODULE.md) |
| Product/Solution Type | 🟡 line items สินค้า/บริการ (migration 088) · ไม่ใช่ enum Hardware/Cloud แบบ spec |
| Competitor / Win-Lost Reason | 🟡 ต้องเช็คฟิลด์ opp รายละเอียด — v1 อาจไม่ครบ |
| Weighted Pipeline / Forecast | 🟡 การ์ดสรุปบน list · ไม่มี forecast รายเดือนใน 360 |
| จาก Lead convert | ✅ `/app/opportunities/from-lead/:id` |

### Tab 5 — Quotations

| รายการ | CRM Kai |
|--------|---------|
| โมดูล Quotation | ❌ เมนู `/app/quotations` = Coming soon |
| Approval / PDF / Email / Version | ❌ |

### Tab 6 — Contracts & Renewal

| รายการ | CRM Kai |
|--------|---------|
| Contract types (M365, Firewall, SLA, …) | ❌ เมนู `contract-agreements` = Coming soon |
| Renewal alert 30/60/90 | ⏳ mock KPI |
| Auto Renewal Opportunity | ❌ |

### Tab 7 — Assets / Installed Base

| รายการ | CRM Kai |
|--------|---------|
| Asset categories (Server, Network, POS, …) | ❌ ไม่มีตาราง asset |
| Serial / Warranty / SLA / Engineer | ❌ |
| **หมายเหตุ:** `/app/service` ของเรา = **บริการใน master catalog** ไม่ใช่ installed base ต่อลูกค้า |

### Tab 8 — Tickets / Service History

| รายการ | CRM Kai |
|--------|---------|
| Ticket module | ❌ |
| SLA / Escalation / Root Cause | ❌ |

### Tab 9 — Activities

| รายการ (spec) | CRM Kai |
|---------------|---------|
| Activity types (Call, Email, Meeting, Visit, LINE, …) | 🟡 **Tasks** มี Task/Call/Email/Meeting/Visit · ไม่มี LINE · ไม่ครบทุก subtype spec |
| Timeline + Reminder + Calendar | 🟡 Tasks มี calendar view · ยังไม่ sync M365/Google |
| ตาราง `activities` (legacy) | 🟡 ผูก deal/contact/company · ไม่ใช่หน้า Activity หลัก |

### Tab 10 — Files & Documents

| รายการ | CRM Kai |
|--------|---------|
| Document library + version + permission | ❌ (มี image upload บาง preset เช่น avatar, product) |

---

## 5. Customer Health Score

| รายการ (spec) | CRM Kai |
|---------------|---------|
| สูตรคำนวณ (Revenue, Opp, Ticket, SLA, Renewal, Last Activity) | ❌ |
| สถานะ Healthy / Normal / Attention / At Risk | ⏳ mock badge บน dashboard |
| ตั้งค่า weight | ❌ |

---

## 6. Business Rules (ตัวอย่างสำคัญ)

| กฎ (spec) | CRM Kai |
|-----------|---------|
| Customer Code auto | ❌ |
| Customer Name + Tax ID ไม่ซ้ำ | 🟡 validation บางส่วน · ต้องยืนยัน unique rule |
| ต้องมี Account Owner | 🟡 UI แนะนำ · ต้องเช็คบังคับ DB |
| Blacklist → ห้าม Quotation | ❌ (ยังไม่มีทั้งสองอย่าง) |
| No activity 90 วัน → Alert | ❌ |
| Opp ต้องมี Expected Close Date | 🟡 มี `close_date` · validation ต้องเช็ค |
| Won ต้องมี Quotation/PO | ❌ |
| Lost ต้องมีเหตุผล | 🟡 ขึ้นกับ stage workflow |
| Contract expiry alert / auto expired | ❌ |
| Ticket + SLA rules | ❌ |

---

## 7. Dashboard (ใน/นอก Customer 360)

| Dashboard (spec) | CRM Kai |
|------------------|---------|
| Sales (Revenue, Pipeline, Win rate, Forecast) | 🟡 `/app` mock + opp summary cards · legacy `/app/deals` |
| Service (Ticket, SLA) | ⏳ mock |
| Renewal | ⏳ mock |
| Executive (CLV, At Risk, Upsell) | ⏳ mock |

---

## 8. Integration Requirements

ทั้งหมด **❌** ใน Phase ปัจจุบัน (ลูกค้าวาง Phase 2):

Microsoft 365 · Google Workspace · LINE OA · Website lead form · ERP · Service Desk · Quotation system · PBX · Power BI · Email Marketing

---

## 9. Database Entities (spec §9)

| Entity (spec) | ตาราง CRM Kai | สถานะ |
|---------------|---------------|--------|
| Customer | `companies` | ✅ |
| Contact | `contacts` | ✅ |
| Lead | `leads` | ✅ |
| Opportunity | `opportunities` | ✅ |
| Quotation / Quotation Item | — | ❌ |
| Contract | — | ❌ |
| Asset | — | ❌ |
| Ticket | — | ❌ |
| Activity | `activities` (legacy) + `tasks` | 🟡 |
| Document | — | ❌ |
| Product | `products` | ✅ |
| Service | `services` | 🟡 catalog master (migration 088) |
| User / Team | `profiles` · `sales_teams` | ✅ |
| Customer Health Score | — | ❌ |

ความสัมพันธ์หลัก (Customer → many Contact/Opp/…) **ออกแบบตรงแนว spec แล้ว** สำหรับ entity ที่มีอยู่

---

## 10. MVP Scope ลูกค้า vs แผนเรา

### Phase 1 Core (spec ลูกค้า)

| รายการ MVP ลูกค้า | CRM Kai ปัจจุบัน |
|-------------------|------------------|
| Customer Profile | ✅ Master Data |
| Contact Management | ✅ |
| Opportunity | ✅ |
| Quotation Summary | ❌ |
| Contract & Renewal | ❌ |
| Asset / Installed Base | ❌ |
| Ticket Summary | ❌ |
| Activity Timeline | 🟡 Tasks |
| Document Management | ❌ |
| Basic Dashboard | ⏳ mock |

### Phase 2 Automation (spec ลูกค้า)

Calendar · Email · LINE · Renewal alert · Quotation approval · ERP · SLA — **ยังไม่เริ่ม**

### Phase 3 AI (spec ลูกค้า)

AI Summary · Next action · Renewal risk · Scoring — **⏳ mock UI เท่านั้น**

---

## 11. เมนูที่ spec แนะนำ vs CRM Kai

| เมนู (spec) | CRM Kai (`appMenu` / Master Data) |
|-------------|-----------------------------------|
| Dashboard | ✅ `/app` |
| Leads | ✅ `/app/leads` |
| Customers / Customer 360 | 🟡 `/app/customer` (list/form) · **ไม่มี 360** |
| Contacts | ✅ `/app/contact` (Master Data) |
| Activities | 🟡 `/app/tasks` |
| Opportunities | ✅ `/app/opportunities` |
| Quotations | ⏳ Coming soon |
| Contracts & Renewal | ⏳ Coming soon |
| Assets | ❌ |
| Tickets | ❌ (มี `/app/service` = catalog บริการ) |
| Reports | ⏳ Coming soon |
| Settings | ✅ `/app/setup` + Master Data |

---

## 12. สิ่งที่ **ตรงกับระบบเราแล้ว** (ทำต่อได้เลย)

1. **Master ลูกค้า + ผู้ติดต่อ** — ฟิลด์หลักครบ · FK · main contact · owner · industry · grade/status  
2. **Lead → Opportunity** — flow ตรงแนวคิด spec  
3. **Opportunity** — stage, มูลค่า, owner, line items สินค้า/บริการ  
4. **Tasks** — งานประจำวัน / call / meeting (เป็นรากของ Activity tab)  
5. **สิทธิ์แบบ org role** — ปรับ template ให้ตรง Sales/Finance ได้  
6. **ข้อมูลหลักรอง** — สินค้า, หมวด, หน่วย, แหล่งลีด, ทีมขาย, job code, module status  
7. **UI mock KuTo** — ตารางลูกค้า + KPI + แท็บ 360 + AI panel (นำไป implement จริงได้)

---

## 13. Gap สำคัญที่ควรวางแผนก่อน (แนะนำลำดับ)

| ลำดับ | งาน | เหตุผล |
|-------|-----|--------|
| 1 | **หน้า Customer 360** (`/app/customer/:id` หรือ `/360`) — header + แท็บ Overview/Contacts/Opp | ใจกลาง spec · ใช้ข้อมูลที่มีอยู่แล้ว |
| 2 | **Customer Code** (job_code แบบ module `customer`) | spec บังคับ · ใช้ร่วมกับรายงาน |
| 3 | **Aggregate KPI** (pipeline, last activity จาก tasks) | header + Overview widgets |
| 4 | **Quotation module** (อย่างน้อย read-only list ใน 360) | MVP ลูกค้า Phase 1 |
| 5 | **Contract + Renewal** | ธุรกิจ IT + maintenance ของลูกค้า |
| 6 | **Asset + Ticket** | Service-centric ตาม spec |
| 7 | **Health Score + Business rules** | หลังมีข้อมูล Ticket/Renewal |
| 8 | **Integration + AI** | Phase 2–3 ตาม spec ลูกค้า |

---

## 14. ความเสี่ยง / จุดที่ต้องตกลงกับลูกค้า

| หัวข้อ | รายละเอียด |
|--------|------------|
| **Customer Type** | Spec ใช้ Corporate/Government/… · เราใช้ company/individual + industry — ต้อง map หรือขยาย enum |
| **Tier vs Sales Grade** | ชื่อต่าง · ค่าใกล้เคียง |
| **Activities vs Tasks** | Spec แยก Activity timeline · เราใช้ `tasks` เป็นหลัก — รวมหรือแยกตาราง |
| **Service master vs Installed Asset** | คนละ domain · ห้ามสับสนใน UI |
| **Phase ของเรา vs Phase ลูกค้า** | ลูกค้า MVP รวม Quotation/Contract/Asset/Ticket · เรายังไม่ถึง — ต้อง align roadmap |

---

## 15. เอกสารที่เกี่ยวข้องใน repo

| เอกสาร | เนื้อหา |
|--------|---------|
| [CUSTOMER-MASTER-FIELDS.md](../06-crm-schema/CUSTOMER-MASTER-FIELDS.md) | ฟิลด์ลูกค้าปัจจุบัน |
| [CONTACT-MASTER-FIELDS.md](../06-crm-schema/CONTACT-MASTER-FIELDS.md) | ฟิลด์ผู้ติดต่อ |
| [LEADS-MODULE.md](../05-frontend/LEADS-MODULE.md) | ลีด |
| [OPPORTUNITIES-MODULE.md](../05-frontend/OPPORTUNITIES-MODULE.md) | โอกาสขาย |
| [TASKS-MODULE.md](../05-frontend/TASKS-MODULE.md) | งาน / กิจกรรม |
| [APP-MENU.md](../05-frontend/APP-MENU.md) | เมนู CRM + Coming soon |
| [PHASE-1-CHECKLIST.md](./PHASE-1-CHECKLIST.md) | Phase 1 done |

---

## ประวัติ

| วันที่ | รายการ |
|--------|--------|
| 2026-06-22 | สร้างเอกสารจาก `Functional Specification.docx` · gap analysis ครั้งแรก |
