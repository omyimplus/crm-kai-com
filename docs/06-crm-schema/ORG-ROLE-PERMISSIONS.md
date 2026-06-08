# Org Role Permissions

> สิทธิ์ต่อโมดูล/เมนูสำหรับ `org_roles` — กำหนดที่ `/app/master-data/roles/:id/permissions`

---

## โครงสร้าง `permissions` (jsonb)

```json
{
  "app.dashboard": ["view"],
  "app.leads": ["view", "create", "edit"],
  "master.products": ["view"]
}
```

- **Key:** `{group}.{menuKey}` — derive จาก `appMenu.ts` + `masterDataMenu.ts`
- **Value:** array ของ action — `view` | `create` | `edit` | `delete` | `export`
- **`app.reports`:** รองรับ `export` เพิ่ม
- **Setup menu:** ไม่อยู่ใน org role — ผูก system role (`owner`/`admin`) เท่านั้น

---

## Sync สร้าง / ลบ Role

| เหตุการณ์ | พฤติกรรม |
|-----------|----------|
| **สร้าง role** | `create_org_role` → `normalize_org_role_permissions()` ใส่ key ทุกโมดูล (เริ่ม `[]`) |
| **แก้สิทธิ์** | `update_org_role` + หน้า permissions |
| **ลบ role** | `delete_org_role` — ลบแถว + permissions ใน jsonb; ห้ามลบถ้ามี user ผูกอยู่ |

---

## Source of truth (ต้อง sync คู่กัน)

| ที่ | ไฟล์ |
|----|------|
| Frontend registry | `frontend/app/config/permissionModules.ts` |
| DB normalize | `org_role_permission_keys()` ใน migration |

เพิ่มเมนูใหม่ → อัปเดตทั้งสองที่ + migration backfill

---

## RPC

| ฟังก์ชัน | ใช้เมื่อ |
|---------|---------|
| `get_org_role(uuid)` | โหลดหน้า permissions |
| `normalize_org_role_permissions(jsonb)` | validate + เติม key ที่ขาด |
| `delete_org_role(uuid)` | ลบ role (log §13) |

---

## เอกสารที่เกี่ยวข้อง

- [MASTER-DATA-MENU.md](../05-frontend/MASTER-DATA-MENU.md) §10
- [permissions.md](./permissions.md)
- [DATA-CHANGE-LOG.md](./DATA-CHANGE-LOG.md)
