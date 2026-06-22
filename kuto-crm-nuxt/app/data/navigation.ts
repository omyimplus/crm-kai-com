import type { Component } from 'vue'
import {
  Bot,
  BriefcaseBusiness,
  Building2,
  CalendarCheck,
  FileText,
  FolderOpen,
  Headphones,
  LayoutDashboard,
  PackageCheck,
  Settings,
  ShieldCheck,
  TrendingUp,
  Users,
} from 'lucide-vue-next'
import type { Label } from '~/utils/i18n'

export type NavSubItem = Label & { path: string }

export type NavItem = {
  label: Label
  icon: Component
  path?: string
  subs: NavSubItem[]
}

const sub = (th: string, en: string, slug: string): NavSubItem => ({
  th,
  en,
  path: slug,
})

export const navItems: NavItem[] = [
  {
    label: { th: 'แดชบอร์ด', en: 'Dashboard' },
    icon: LayoutDashboard,
    path: '/',
    subs: [
      sub('แดชบอร์ดของฉัน', 'My Dashboard', '/'),
      sub('แดชบอร์ดฝ่ายขาย', 'Sales Dashboard', '/dashboard/sales'),
      sub('แดชบอร์ดผู้จัดการ', 'Manager Dashboard', '/dashboard/manager'),
      sub('แดชบอร์ดผู้บริหาร', 'Executive Dashboard', '/dashboard/executive'),
      sub('แดชบอร์ดงานบริการ', 'Service Dashboard', '/dashboard/service'),
      sub('แดชบอร์ดต่ออายุสัญญา', 'Renewal Dashboard', '/dashboard/renewal'),
    ],
  },
  {
    label: { th: 'ลูกค้าเป้าหมาย', en: 'Leads' },
    icon: Users,
    subs: [
      sub('กล่องรับ Lead', 'Lead Inbox', '/leads/inbox'),
      sub('Lead ทั้งหมด', 'All Leads', '/leads/all'),
      sub('เพิ่ม Lead ใหม่', 'New Lead', '/leads/new'),
      sub('มุมมอง Kanban', 'Lead Kanban', '/leads/kanban'),
      sub('การมอบหมาย Lead', 'Lead Assignment', '/leads/assignment'),
      sub('คะแนน Lead', 'Lead Scoring', '/leads/scoring'),
      sub('แหล่งที่มาของ Lead', 'Lead Sources', '/leads/sources'),
      sub('Lead ซ้ำ', 'Duplicate Leads', '/leads/duplicates'),
      sub('นำเข้า Lead', 'Import Leads', '/leads/import'),
      sub('Lead ที่แปลงแล้ว', 'Converted Leads', '/leads/converted'),
    ],
  },
  {
    label: { th: 'ลูกค้า', en: 'Customers' },
    icon: Building2,
    subs: [
      sub('รายชื่อลูกค้า', 'Customer List', '/customers/list'),
      sub('มุมมองลูกค้า 360 องศา', 'Customer 360', '/customers/360'),
      sub('บัญชีลูกค้า', 'Accounts', '/customers/accounts'),
      sub('ผู้ติดต่อ', 'Contacts', '/customers/contacts'),
      sub('กลุ่มลูกค้า', 'Customer Groups', '/customers/groups'),
      sub('เอกสารลูกค้า', 'Customer Documents', '/customers/documents'),
      sub('สุขภาพลูกค้า', 'Customer Health', '/customers/health'),
      sub('ระดับลูกค้า', 'Customer Tier', '/customers/tier'),
      sub('จัดการข้อมูลซ้ำ', 'Duplicate Management', '/customers/duplicates'),
      sub('นำเข้าข้อมูลลูกค้า', 'Import Customers', '/customers/import'),
    ],
  },
  {
    label: { th: 'โอกาสการขาย', en: 'Opportunities' },
    icon: BriefcaseBusiness,
    subs: [
      sub('Pipeline แบบ Kanban', 'Pipeline Kanban', '/opportunities/kanban'),
      sub('รายการโอกาสการขาย', 'Opportunity List', '/opportunities/list'),
      sub('รายละเอียดโอกาสการขาย', 'Opportunity Detail', '/opportunities/detail'),
      sub('คาดการณ์ยอดขาย', 'Forecast', '/opportunities/forecast'),
    ],
  },
  {
    label: { th: 'ใบเสนอราคา', en: 'Quotations' },
    icon: FileText,
    subs: [
      sub('รายการใบเสนอราคา', 'Quotation List', '/quotations/list'),
      sub('สร้างใบเสนอราคา', 'Create Quotation', '/quotations/create'),
      sub('อนุมัติใบเสนอราคา', 'Quotation Approval', '/quotations/approval'),
      sub('ราคาสินค้า', 'Price Book', '/quotations/price-book'),
    ],
  },
  {
    label: { th: 'สัญญาและต่ออายุ', en: 'Contracts & Renewal' },
    icon: ShieldCheck,
    subs: [
      sub('สัญญาทั้งหมด', 'All Contracts', '/contracts/all'),
      sub('แจ้งเตือนต่ออายุ', 'Renewal Alerts', '/contracts/renewal-alerts'),
      sub('คาดการณ์รายได้ต่ออายุ', 'Renewal Forecast', '/contracts/renewal-forecast'),
    ],
  },
  {
    label: { th: 'Asset และระบบที่ติดตั้ง', en: 'Assets / Installed Base' },
    icon: PackageCheck,
    subs: [
      sub('Storage', 'Storage', '/assets/storage'),
      sub('Network', 'Network', '/assets/network'),
      sub('Security', 'Security', '/assets/security'),
      sub('Cloud', 'Cloud', '/assets/cloud'),
      sub('Software', 'Software', '/assets/software'),
      sub('POS', 'POS', '/assets/pos'),
      sub('ระบบจองห้องประชุม', 'Room Booking', '/assets/room-booking'),
      sub('อุปกรณ์เช่า', 'Rental', '/assets/rental'),
      sub('Industrial PC', 'Industrial PC', '/assets/industrial-pc'),
    ],
  },
  {
    label: { th: 'Ticket และประวัติงานบริการ', en: 'Tickets / Service History' },
    icon: Headphones,
    subs: [
      sub('กระดาน Ticket', 'Ticket Board', '/tickets/board'),
      sub('รายการ Ticket', 'Ticket List', '/tickets/list'),
      sub('สร้าง Ticket', 'Create Ticket', '/tickets/create'),
      sub('Ticket ของฉัน', 'My Tickets', '/tickets/my'),
      sub('ติดตาม SLA', 'SLA Monitoring', '/tickets/sla'),
      sub('ฐานความรู้', 'Knowledge Base', '/tickets/knowledge-base'),
    ],
  },
  {
    label: { th: 'กิจกรรม', en: 'Activities' },
    icon: CalendarCheck,
    subs: [
      sub('กิจกรรมของฉัน', 'My Activities', '/activities/my'),
      sub('Timeline กิจกรรม', 'Activity Timeline', '/activities/timeline'),
      sub('มุมมองปฏิทิน', 'Calendar View', '/activities/calendar'),
      sub('การประชุม', 'Meetings', '/activities/meetings'),
      sub('การติดตามงาน', 'Follow-ups', '/activities/follow-ups'),
    ],
  },
  {
    label: { th: 'เอกสาร', en: 'Documents' },
    icon: FolderOpen,
    subs: [
      sub('เอกสารทั้งหมด', 'All Documents', '/documents/all'),
      sub('เอกสารลูกค้า', 'Customer Documents', '/documents/customers'),
      sub('เอกสารสัญญา', 'Contract Documents', '/documents/contracts'),
      sub('ควบคุม Version', 'Version Control', '/documents/versions'),
    ],
  },
  {
    label: { th: 'รายงานและการวิเคราะห์', en: 'Reports & Analytics' },
    icon: TrendingUp,
    subs: [
      sub('ผลงานฝ่ายขาย', 'Sales Performance', '/reports/sales'),
      sub('รายงาน Pipeline', 'Pipeline Report', '/reports/pipeline'),
      sub('รายงาน Forecast', 'Forecast Report', '/reports/forecast'),
      sub('สรุปผู้บริหาร', 'Executive Summary', '/reports/executive'),
    ],
  },
  {
    label: { th: 'ข้อมูลเชิงลึกจาก AI', en: 'AI Insights' },
    icon: Bot,
    subs: [
      sub('สรุปลูกค้าด้วย AI', 'AI Customer Summary', '/ai/customer-summary'),
      sub('คำแนะนำสิ่งที่ควรทำถัดไป', 'AI Next Best Action', '/ai/next-best-action'),
      sub('วิเคราะห์ความเสี่ยงการต่ออายุ', 'AI Renewal Risk', '/ai/renewal-risk'),
    ],
  },
  {
    label: { th: 'ตั้งค่าระบบ', en: 'Settings' },
    icon: Settings,
    subs: [
      sub('ข้อมูลบริษัท', 'Company Profile', '/settings/company'),
      sub('ผู้ใช้งาน', 'Users', '/settings/users'),
      sub('บทบาทและสิทธิ์', 'Roles & Permissions', '/settings/roles'),
      sub('ตั้งค่าภาษา', 'Language Settings', '/settings/language'),
      sub('ประวัติการใช้งานระบบ', 'Audit Logs', '/settings/audit-logs'),
    ],
  },
]
