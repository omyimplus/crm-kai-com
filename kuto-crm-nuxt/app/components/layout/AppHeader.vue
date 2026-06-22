<script setup lang="ts">
import { Bell, Menu, Plus, Search } from 'lucide-vue-next'
import { tx } from '~/utils/i18n'

const { lang, setLang } = useLang()

const copy = {
  search: { th: 'ค้นหาทั้งระบบ', en: 'Global Search' },
  quick: { th: 'สร้างรายการด่วน', en: 'Quick Create' },
  approval: { th: 'งานรออนุมัติ', en: 'Approval Tasks' },
  role: { th: 'ผู้จัดการฝ่ายขาย', en: 'Sales Manager' },
}

const quickCreate = [
  { th: 'เพิ่ม Lead ใหม่', en: 'New Lead' },
  { th: 'เพิ่มลูกค้าใหม่', en: 'New Customer' },
  { th: 'เพิ่มผู้ติดต่อ', en: 'New Contact' },
  { th: 'เพิ่มโอกาสการขาย', en: 'New Opportunity' },
  { th: 'สร้างใบเสนอราคา', en: 'New Quotation' },
  { th: 'สร้างสัญญา', en: 'New Contract' },
  { th: 'สร้าง Ticket', en: 'New Ticket' },
  { th: 'เพิ่มกิจกรรม', en: 'New Activity' },
]
</script>

<template>
  <header class="sticky top-0 z-10 border-b border-border bg-white/85 backdrop-blur-xl">
    <div class="flex items-center gap-3 px-4 py-4 lg:px-7">
      <button type="button" class="rounded-xl border p-2 lg:hidden" aria-label="Menu">
        <Menu class="size-5" />
      </button>

      <div class="relative max-w-2xl flex-1">
        <Search class="absolute left-4 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
        <input
          class="h-12 w-full rounded-2xl border border-border bg-input-background pl-11 pr-4 text-sm outline-none focus:ring-2 focus:ring-emerald-200"
          :placeholder="tx(copy.search, lang)"
        >
      </div>

      <details class="relative hidden md:block">
        <summary class="flex cursor-pointer list-none items-center rounded-2xl bg-primary px-4 py-3 text-sm font-bold text-primary-foreground">
          <Plus class="mr-2 size-4" />
          {{ tx(copy.quick, lang) }}
        </summary>
        <div class="absolute right-0 top-14 z-20 w-64 rounded-2xl border bg-white p-2 shadow-xl">
          <button
            v-for="item in quickCreate"
            :key="item.en"
            type="button"
            class="block w-full rounded-xl px-3 py-2 text-left text-sm hover:bg-slate-50"
          >
            {{ tx(item, lang) }}
          </button>
        </div>
      </details>

      <button
        type="button"
        class="hidden rounded-2xl border bg-white px-3 py-2 text-sm font-bold xl:block"
      >
        {{ tx(copy.approval, lang) }}
        <span class="ml-1 rounded-full bg-amber-100 px-2 text-amber-700">5</span>
      </button>

      <div class="flex rounded-2xl border bg-white p-1">
        <button
          type="button"
          :class="[
            'rounded-xl px-3 py-1.5 text-sm font-bold',
            lang === 'th' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground',
          ]"
          @click="setLang('th')"
        >
          TH
        </button>
        <button
          type="button"
          :class="[
            'rounded-xl px-3 py-1.5 text-sm font-bold',
            lang === 'en' ? 'bg-primary text-primary-foreground' : 'text-muted-foreground',
          ]"
          @click="setLang('en')"
        >
          EN
        </button>
      </div>

      <button
        type="button"
        class="relative rounded-2xl border bg-white p-3"
        :title="lang === 'th' ? 'การแจ้งเตือน' : 'Notifications'"
      >
        <Bell class="size-5" />
        <span class="absolute right-2 top-2 size-2 rounded-full bg-red-500" />
      </button>

      <button type="button" class="flex items-center gap-2 rounded-2xl border bg-white px-2 py-2">
        <div class="grid size-8 place-items-center rounded-xl bg-emerald-100 text-sm font-bold text-emerald-700">
          NS
        </div>
        <div class="hidden text-left xl:block">
          <p class="text-xs font-bold">Nicha</p>
          <p class="text-[10px] text-muted-foreground">{{ tx(copy.role, lang) }}</p>
        </div>
      </button>
    </div>
  </header>
</template>
