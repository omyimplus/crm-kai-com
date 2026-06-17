# Supabase — CRM Kai

> Migrations และ seed สำหรับ Phase 1  
> Docs: [docs/02-database/DB-SCHEMA.md](../docs/02-database/DB-SCHEMA.md) · [DB-CHANGELOG.md](../docs/02-database/DB-CHANGELOG.md)

## Migrations

| File | เนื้อหา |
|------|---------|
| `20260608120000_crm_schema.sql` | tables, indexes, triggers |
| `20260608120001_rls_and_helpers.sql` | RLS, helpers, signup_profile |
| `20260608120002_grants_and_profile_policies.sql` | GRANT authenticated + profiles_select_own |
| `20260608120003_system_users_admin.sql` | list_org_users + admin_update_profile (Setup) |
| `20260608120004_system_users_fields.sql` | username + create/update user (email, password) |
| `20260608120005_data_change_logs.sql` | ตาราง `data_change_logs` + `write_data_change_log()` (กฎ §13) |
| `20260608120006_org_roles.sql` | `org_roles` + wire system users |
| `20260608120007_org_role_permissions.sql` | normalize permissions + delete role |
| `20260608120008_list_data_change_logs.sql` | `list_data_change_logs` — User Activity UI |
| `20260608120017_resolve_login_email.sql` | username → email ก่อน login |
| `20260608120030_companies_customer_status.sql` | companies.status 5 lifecycle values |
| `20260608120031_companies_customer_master_fields.sql` | customer master columns + `company_ship_addresses` |
| `20260608120032_companies_soft_delete_rpc.sql` | soft delete customer + data_change_logs |
| `20260608120033_company_ship_addresses_is_default.sql` | ship-to default + `get_company_default_ship_address` |
| `20260608120034_companies_individual_type_rules.sql` | individual customer → segment/industry CHECK |
| `20260608120035_company_bill_addresses.sql` | bill-to addresses + default RPC + migrate legacy address |
| `20260608120040_companies_crud_rpc.sql` | create/update customer RPC + data_change_logs |
| `20260608120039_contacts_crud_rpc.sql` | contact CRUD RPC + data_change_logs |
| `20260608120038_contacts_master_fields.sql` | contact master fields + company relation index |

**บัญชีทดสอบ:** [docs/11-dev-setup/TEST-ACCOUNTS.md](../docs/11-dev-setup/TEST-ACCOUNTS.md)

## Local

```bash
supabase start
supabase db reset   # migrations + seed.sql
supabase status     # URL + anon key → frontend/.env
```

## Demo org

- slug: `demo`
- id: `11111111-1111-1111-1111-111111111111`

Signup ใช้ RPC `signup_profile(full_name)` ผูก user กับ demo org
