<script setup lang="ts">
import {
  CircleDollarSign,
  Filter,
  Headphones,
  ShieldCheck,
  Sparkles,
  Target,
  TrendingUp,
} from 'lucide-vue-next'
import { tx } from '~/utils/i18n'

const { lang } = useLang()

const copy = {
  title: {
    th: 'ศูนย์ควบคุมธุรกิจ KC KuTo CRM',
    en: 'KC KuTo CRM Business Command Center',
  },
  subtitle: {
    th: 'ระบบ CRM องค์กรพร้อมโครงสร้างภาษาไทยและอังกฤษแบบแยกสถานะจริง',
    en: 'Enterprise CRM with true separated Thai and English localization states',
  },
  customerList: { th: 'รายชื่อลูกค้า', en: 'Customer List' },
  customer360: { th: 'มุมมองลูกค้า 360 องศา', en: 'Customer 360' },
  aiPanel: { th: 'แผงข้อมูล AI', en: 'AI Insights Panel' },
}

const kpis = [
  [{ th: 'เป้ายอดขาย', en: 'Sales Target' }, '฿48.2M', Target],
  [{ th: 'ยอดขายที่ปิดได้', en: 'Won Revenue' }, '฿31.6M', CircleDollarSign],
  [{ th: 'มูลค่า Pipeline ที่เปิดอยู่', en: 'Open Pipeline' }, '฿86.9M', TrendingUp],
  [{ th: 'ยอดขายคาดการณ์', en: 'Forecast Revenue' }, '฿42.8M', TrendingUp],
  [{ th: 'Ticket ที่ยังไม่ปิด', en: 'Open Tickets' }, '284', Headphones],
  [{ th: 'แจ้งเตือนรายการต่ออายุ', en: 'Renewal Alert' }, '26', ShieldCheck],
] as const

const headers = [
  { th: 'ชื่อลูกค้า', en: 'Customer Name' },
  { th: 'รหัสลูกค้า', en: 'Customer Code' },
  { th: 'ประเภทธุรกิจ', en: 'Industry' },
  { th: 'ประเภทลูกค้า', en: 'Customer Type' },
  { th: 'ผู้ดูแลลูกค้า', en: 'Account Owner' },
  { th: 'ระดับลูกค้า', en: 'Customer Tier' },
  { th: 'รายได้สะสม', en: 'Total Revenue' },
  { th: 'Pipeline ที่เปิดอยู่', en: 'Open Pipeline' },
  { th: 'Ticket ที่ยังไม่ปิด', en: 'Open Tickets' },
  { th: 'คะแนนสุขภาพลูกค้า', en: 'Health Score' },
]

const customers = [
  ['Siam Cement Group', 'CUS-1024', 'Manufacturing', 'Enterprise', 'นิชา', 'Platinum', '฿18.2M', '฿7.4M', '6', 92],
  ['CP All', 'CUS-1098', 'Retail', 'Key Account', 'ภาคิน', 'Gold', '฿15.7M', '฿5.1M', '2', 86],
  ['Bangkok Dusit Medical', 'CUS-1187', 'Healthcare', 'Enterprise', 'มินตรา', 'Platinum', '฿12.4M', '฿3.8M', '9', 73],
]

const status = [
  { th: 'ใช้งานอยู่', en: 'Active' },
  { th: 'ลูกค้าเป้าหมาย', en: 'Prospect' },
  { th: 'มีความเสี่ยง', en: 'At Risk' },
  { th: 'อนุมัติแล้ว', en: 'Approved' },
  { th: 'ชนะการขาย', en: 'Won' },
  { th: 'แพ้การขาย', en: 'Lost' },
]

const customer360Tabs = [
  { th: 'ภาพรวม', en: 'Overview' },
  { th: 'ข้อมูลบริษัท', en: 'Company Info' },
  { th: 'ผู้ติดต่อ', en: 'Contacts' },
  { th: 'โอกาสการขาย', en: 'Opportunities' },
  { th: 'เอกสาร', en: 'Documents' },
  { th: 'การเงิน', en: 'Financial' },
]

const customer360Cards = [
  { th: 'ข้อมูลลูกค้า', en: 'Customer Profile' },
  { th: 'สรุปรายได้', en: 'Revenue Summary' },
  { th: 'คำแนะนำจาก AI', en: 'AI Recommendation' },
]

const statusTone = (index: number) => {
  if (index === 2) return 'red'
  if (index === 5) return 'blue'
  return 'emerald'
}
</script>

<template>
  <div class="space-y-6 p-4 lg:p-7">
    <div>
      <p class="font-semibold uppercase tracking-[0.18em] text-emerald-700">
        {{ lang === 'th' ? 'โหมดภาษาไทย' : 'English Mode' }}
      </p>
      <h1 class="mt-1 text-3xl font-extrabold text-slate-950 md:text-4xl">
        {{ tx(copy.title, lang) }}
      </h1>
      <p class="mt-2 max-w-4xl text-muted-foreground">
        {{ tx(copy.subtitle, lang) }}
      </p>
    </div>

    <section class="grid gap-4 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-6">
      <UiAppCard v-for="[label, value, Icon] in kpis" :key="label.en" class="p-5">
        <div class="flex justify-between">
          <div>
            <p class="text-sm font-semibold">{{ tx(label, lang) }}</p>
            <p class="mt-3 text-2xl font-extrabold">{{ value }}</p>
          </div>
          <div class="rounded-2xl bg-emerald-50 p-3 text-emerald-700">
            <component :is="Icon" class="size-5" />
          </div>
        </div>
      </UiAppCard>
    </section>

    <div class="grid gap-6 xl:grid-cols-[1fr_360px]">
      <div class="space-y-6">
        <UiAppCard class="overflow-hidden">
          <div class="flex items-center justify-between border-b p-5">
            <div>
              <h2 class="text-2xl font-extrabold">{{ tx(copy.customerList, lang) }}</h2>
              <p class="text-sm text-muted-foreground">
                {{
                  lang === 'th'
                    ? 'แสดงหัวตาราง ปุ่ม และสถานะเป็นภาษาไทยเท่านั้น'
                    : 'Table headers, buttons, and statuses display in English only'
                }}
              </p>
            </div>
            <button type="button" class="rounded-2xl bg-primary px-4 py-2 text-sm font-bold text-primary-foreground">
              {{ lang === 'th' ? 'เพิ่มลูกค้าใหม่' : 'New Customer' }}
            </button>
          </div>

          <div class="grid gap-3 border-b bg-slate-50 p-4 md:grid-cols-[1fr_auto]">
            <input
              class="rounded-2xl border bg-white px-4 py-3 text-sm"
              :placeholder="lang === 'th' ? 'ค้นหาลูกค้า' : 'Search customers'"
            >
            <button type="button" class="rounded-2xl border bg-white px-4 py-3 text-sm">
              <Filter class="mr-2 inline size-4" />
              {{ lang === 'th' ? 'ตัวกรอง' : 'Filter' }}
            </button>
          </div>

          <div class="overflow-x-auto">
            <table class="w-full min-w-[1100px] text-left text-sm">
              <thead class="bg-white text-xs">
                <tr>
                  <th v-for="header in headers" :key="header.en" class="px-4 py-3 font-bold">
                    {{ tx(header, lang) }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="row in customers"
                  :key="row[1]"
                  class="border-t hover:bg-slate-50"
                >
                  <td
                    v-for="(cell, index) in row"
                    :key="`${row[1]}-${index}`"
                    class="px-4 py-3"
                  >
                    <UiAppBadge v-if="index === 9">{{ cell }}</UiAppBadge>
                    <template v-else>{{ cell }}</template>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </UiAppCard>

        <UiAppCard class="p-5">
          <h2 class="text-2xl font-extrabold">{{ tx(copy.customer360, lang) }}</h2>
          <div class="mt-4 flex gap-2 overflow-x-auto">
            <button
              v-for="(tab, index) in customer360Tabs"
              :key="tab.en"
              type="button"
              :class="[
                'shrink-0 rounded-2xl px-4 py-2 text-sm',
                index === 0 ? 'bg-primary text-primary-foreground' : 'bg-slate-100',
              ]"
            >
              {{ tx(tab, lang) }}
            </button>
          </div>
          <div class="mt-5 grid gap-4 md:grid-cols-3">
            <div
              v-for="card in customer360Cards"
              :key="card.en"
              class="rounded-2xl bg-slate-50 p-4"
            >
              <b>{{ tx(card, lang) }}</b>
              <p class="mt-2 text-sm text-muted-foreground">
                {{
                  lang === 'th'
                    ? 'ข้อมูลตัวอย่างสำหรับการพัฒนา CRM จริง'
                    : 'Sample data ready for real CRM development'
                }}
              </p>
            </div>
          </div>
        </UiAppCard>
      </div>

      <aside class="sticky top-24 h-fit rounded-3xl border bg-white p-5 shadow-xl">
        <Sparkles class="mb-3 size-5 text-emerald-600" />
        <h2 class="text-xl font-extrabold">{{ tx(copy.aiPanel, lang) }}</h2>
        <div class="mt-4 space-y-3">
          <UiAppBadge tone="amber">
            {{ lang === 'th' ? 'มีความเสี่ยง' : 'At Risk' }}
          </UiAppBadge>
          <p class="text-sm text-muted-foreground">
            {{
              lang === 'th'
                ? 'แนะนำให้นัดติดตามการต่ออายุภายใน 7 วัน'
                : 'Recommended to schedule renewal follow-up within 7 days'
            }}
          </p>
          <button type="button" class="w-full rounded-2xl bg-primary px-4 py-3 text-sm font-bold text-primary-foreground">
            {{ lang === 'th' ? 'สร้างกิจกรรม' : 'Create Activity' }}
          </button>
          <button type="button" class="w-full rounded-2xl bg-emerald-600 px-4 py-3 text-sm font-bold text-white">
            {{ lang === 'th' ? 'สร้าง Opportunity' : 'Create Opportunity' }}
          </button>
          <button type="button" class="w-full rounded-2xl bg-amber-500 px-4 py-3 text-sm font-bold text-white">
            {{ lang === 'th' ? 'สร้าง Ticket' : 'Create Ticket' }}
          </button>
        </div>
      </aside>
    </div>

    <UiAppCard class="p-5">
      <h2 class="text-2xl font-extrabold">
        {{ lang === 'th' ? 'ป้ายสถานะ' : 'Status Badges' }}
      </h2>
      <div class="mt-4 flex flex-wrap gap-2">
        <UiAppBadge
          v-for="(item, index) in status"
          :key="item.en"
          :tone="statusTone(index)"
        >
          {{ tx(item, lang) }}
        </UiAppBadge>
      </div>
    </UiAppCard>
  </div>
</template>
