<script setup lang="ts">
import { Construction } from 'lucide-vue-next'
import { navItems } from '~/data/navigation'
import { tx } from '~/utils/i18n'

const route = useRoute()
const { lang } = useLang()

const pageTitle = computed(() => {
  const path = route.path

  for (const item of navItems) {
    const sub = item.subs.find((entry) => entry.path === path)
    if (sub) return sub
  }

  return { th: 'หน้านี้', en: 'This page' }
})
</script>

<template>
  <div class="flex min-h-[60vh] flex-col items-center justify-center p-8 text-center">
    <div class="rounded-3xl border border-border bg-white p-10 shadow-sm shadow-slate-200/70">
      <div class="mx-auto mb-4 grid size-16 place-items-center rounded-2xl bg-slate-100 text-primary">
        <Construction class="size-8" />
      </div>
      <p class="text-sm font-semibold uppercase tracking-[0.18em] text-emerald-700">
        {{ lang === 'th' ? 'กำลังพัฒนา' : 'In Development' }}
      </p>
      <h1 class="mt-2 text-3xl font-extrabold text-slate-950">
        {{ tx(pageTitle, lang) }}
      </h1>
      <p class="mt-3 max-w-md text-muted-foreground">
        {{
          lang === 'th'
            ? 'ฟีเจอร์นี้จะเปิดให้ใช้งานเร็ว ๆ นี้ ขณะนี้มีเฉพาะหน้า Dashboard ที่พร้อมใช้งาน'
            : 'This feature is coming soon. Only the Dashboard page is available for now.'
        }}
      </p>
      <NuxtLink
        to="/"
        class="mt-6 inline-flex rounded-2xl bg-primary px-5 py-3 text-sm font-bold text-primary-foreground"
      >
        {{ lang === 'th' ? 'กลับไปหน้า Dashboard' : 'Back to Dashboard' }}
      </NuxtLink>
    </div>
  </div>
</template>
