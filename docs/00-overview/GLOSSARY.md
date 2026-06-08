# Glossary — ศัพท์เดียว (source of truth)

> ใช้คำตามตารางนี้ทั้ง docs และ code — **ห้ามสลับ**  
> ประวัติ → [CHANGELOG.md](./CHANGELOG.md)

---

## โดเมน SaaS / Infra

| คำ | ความหมาย | ตัวอย่าง | ห้ามใช้แทน |
|----|----------|----------|------------|
| **organization / org** | ลูกค้า SaaS ที่สมัครใช้ CRM (tenant) | บริษัท A สมัคร CRM | company |
| **Control DB** | DB กลาง 1 ตัว — login, org registry, trial, routing | Phase 3+ | CRM DB |
| **Tenant DB** | DB CRM ของ org หนึ่ง (1 org = 1 DB ใน Phase 3+) | Supabase project ของ A | Control DB |
| **Control Plane / Node API** | Backend จัดการ org, trial, provision | Phase 3+ | CRM API |
| **provision** | สร้าง Tenant DB + migration ให้ org ใหม่ | หลังสมัคร | register |

---

## โดเมน CRM (ข้อมูลใน Tenant / Phase 1 same DB)

| คำ | ความหมาย | ตัวอย่าง | ห้ามใช้แทน |
|----|----------|----------|------------|
| **company** | ลูกค้า/บัญชีที่ทีมขายตามใน CRM | บริษัท X | org |
| **contact** | บุคคลที่ติดต่อใน CRM | คุณสมชาย | user |
| **deal** | ดีล / โอกาสขาย | ขาย 500k | order |
| **pipeline** | ชุด stage การขาย | Sales pipeline | funnel (ใน UI ได้) |
| **stage** | ขั้นใน pipeline | Lead, Won | status (deal มี status แยก) |
| **activity** | note, call, meeting, task ใน timeline | โทรติดตาม | log |
| **owner** | user ที่รับผิดชอบ record | sales คน A | assignee (ใช้ field `owner_id`) |

---

## Auth / User

| คำ | ความหมาย |
|----|----------|
| **user** | คนที่ login ได้ (Supabase `auth.users`) |
| **profile** | ข้อมูล user ใน org + role (`profiles`) |
| **role** | owner \| admin \| sales \| readonly |

---

## Phase

| คำ | ความหมาย |
|----|----------|
| **Phase 1** | CRM core, 1 Supabase, org_id — **ตอนนี้** |
| **Phase 3+** | Multi-tenant แยก DB จริง |
