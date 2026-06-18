# Charts — กราฟใน CRM Kai

> **Library:** [nuxt-charts](https://www.npmjs.com/package/nuxt-charts) (wrapper ของ [vue-chrts](https://github.com/dennisadriaans/vue-chrts) / Unovis)  
> **Component กลาง:** `AppLineChart` · config สี/ padding: `config/appChart.ts`

---

## ติดตั้ง (ทำแล้วในโปรเจกต์)

```bash
cd frontend && pnpm add nuxt-charts
```

```ts
// nuxt.config.ts
export default defineNuxtConfig({
  modules: ['@nuxt/eslint', '@nuxt/ui', '@nuxtjs/supabase', '@nuxtjs/i18n', 'nuxt-charts']
})
```

Module จะ auto-import `LineChart`, `BarChart`, `AreaChart`, `DonutChart` จาก vue-chrts — **แต่ใน CRM Kai ให้ใช้ wrapper กลางก่อน** เพื่อสี/padding/SSR ให้ตรงกันทั้งระบบ

---

## `AppLineChart` — กราฟเส้นมาตรฐาน

| ไฟล์ | หน้าที่ |
|------|---------|
| `components/AppLineChart.vue` | wrapper รอบ `LineChart` · `ClientOnly` · legend · grid |
| `config/appChart.ts` | สี brand, padding, helper `appChartCategories` |

### Props

| Prop | ชนิด | ค่าเริ่มต้น | หมายเหตุ |
|------|------|------------|----------|
| `data` | `Record<string, number \| null \| undefined>[]` | — | 1 แถว = 1 จุดบนแกน X |
| `series` | `AppChartSeries[]` | — | key ต้องตรง field ใน `data` |
| `height` | `number` | `280` | ความสูง px |
| `xLabel` / `yLabel` | `string` | — | ป้ายแกน (i18n) |
| `xFormatter` | `(tick, index?) => string` | — | ป้าย tick แกน X |
| `yFormatter` | `(tick) => string` | — | ป้าย tick แกน Y |
| `yDomain` | `[min, max]` | auto | ช่วงแกน Y |
| `hideLegend` | `boolean` | `false` | ซ่อน legend |
| `ariaLabel` | `string` | — | a11y |
| `xNumTicks` | `number` | `6` | จำนวน tick แกน X |

### `AppChartSeries`

```ts
{
  key: 'cumulative',      // field ใน data
  label: 'ยอดสะสม',      // legend (ผ่าน i18n)
  color: '#5fb76a',       // ใช้ APP_CHART_COLORS.primary
  dashed?: true            // เส้นประ (เช่น เป้าหมาย)
}
```

### ตัวอย่าง — 2 เส้น (ยอดสะสม + เป้า)

```vue
<script setup lang="ts">
import { APP_CHART_COLORS, formatChartAxisAmount } from '~/config/appChart'
import type { AppChartSeries } from '~/config/appChart'

const { t, locale } = useI18n()

const data = [
  { cumulative: 0, target: 100000, dateLabel: '1 ม.ค.' },
  { cumulative: 25000, target: 100000, dateLabel: '8 ม.ค.' },
  { cumulative: 50000, target: 100000, dateLabel: '15 ม.ค.' }
]

const series: AppChartSeries[] = [
  {
    key: 'cumulative',
    label: t('masterData.salesTarget.progressChart.legendCumulative'),
    color: APP_CHART_COLORS.primary
  },
  {
    key: 'target',
    label: t('masterData.salesTarget.progressChart.legendTarget'),
    color: APP_CHART_COLORS.target,
    dashed: true
  }
]
</script>

<template>
  <AppLineChart
    :data="data"
    :series="series"
    :y-domain="[0, 110000]"
    :x-formatter="(_tick, index) => data[index ?? 0]?.dateLabel ?? ''"
    :y-formatter="tick => formatChartAxisAmount(tick, locale)"
    :aria-label="t('masterData.salesTarget.progressChart.title')"
  />
</template>
```

---

## สีมาตรฐาน (`APP_CHART_COLORS`)

| Token | Hex | ใช้เมื่อ |
|-------|-----|----------|
| `primary` | `#5fb76a` | เส้นหลัก / brand |
| `target` | `#f59e0b` | เป้าหมาย / benchmark |
| `neutral` | `#94a3b8` | ข้อมูลรอง |
| `error` | `#ef4444` | ต่ำกว่าเป้า |
| `info` | `#0ea5e9` | ข้อมูลเสริม |

---

## ใช้ chart โดยตรง (ไม่แนะนำ — ยกเว้น prototype)

ถ้าจำเป็นต้องใช้ component จาก vue-chrts โดยตรง (เช่น `DonutChart` ที่ยังไม่มี wrapper):

```vue
<script setup lang="ts">
import { DonutChart } from 'vue-chrts'
</script>

<template>
  <ClientOnly>
    <DonutChart :data="rows" :height="240" :categories="categories" />
  </ClientOnly>
</template>
```

เมื่อใช้ซ้ำใน production → **สร้าง `AppDonutChart.vue`** ตาม pattern เดียวกับ `AppLineChart`

---

## ตัวอย่างในโปรเจกต์ — เป้ายอดขาย

| ไฟล์ | หน้าที่ |
|------|---------|
| `utils/salesTargetProgressChart.ts` | จำลองวันปิดดีล + สร้าง `chartRows` |
| `components/master-data/MasterDataSalesTargetProgressChart.vue` | UI กราฟ + รายการวันปิดดีล |

หน้าดูเป้า `/app/sales-target/:id` แสดงกราฟใน section ความคืบหน้า — ข้อมูลจำลองจาก `current_amount` (Phase ถัดไปผูกดีล Won จริง)

---

## Checklist กราฟใหม่

- [ ] ใช้ `AppLineChart` (หรือ wrapper ใหม่) — ไม่ inline SVG
- [ ] สีจาก `APP_CHART_COLORS` หรือขยายใน `appChart.ts`
- [ ] ข้อความ UI ผ่าน i18n th + en
- [ ] `ClientOnly` (อยู่ใน wrapper แล้ว)
- [ ] `aria-label` บนกราฟ
- [ ] อัปเดต `docs/05-frontend/CHANGELOG.md` + `frontend/CHANGELOG.md`

---

## เอกสารที่เกี่ยวข้อง

- [SHARED-COMPONENTS.md](./SHARED-COMPONENTS.md)
- [SALES-TARGET-MASTER-FIELDS.md](../06-crm-schema/SALES-TARGET-MASTER-FIELDS.md)
