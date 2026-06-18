<script setup lang="ts">
import type { Lead } from '~/types/crm'
import { computeLeadSummary } from '~/utils/masterLeads'

const props = defineProps<{
  leads: Lead[]
  hotFilterActive?: boolean
  /** มีตัวกรองนอกจากกรองลีดร้อนแรง — แสดงป้ายบนการ์ดมูลค่า */
  filtered?: boolean
}>()

const emit = defineEmits<{
  'toggle-hot': []
  'show-all': []
}>()

const { t } = useI18n()
const { formatCurrency } = useFormat()

const summary = computed(() => computeLeadSummary(props.leads))

const cards = computed(() => [
  {
    key: 'active' as const,
    label: t('leads.summary.active'),
    value: String(summary.value.activeCount),
    icon: 'i-lucide-target',
    iconClass: 'bg-emerald-100 text-emerald-700 dark:bg-emerald-950/60 dark:text-emerald-300',
    interactive: true,
    active: !props.hotFilterActive
  },
  {
    key: 'hot' as const,
    label: t('leads.summary.hot'),
    value: String(summary.value.hotCount),
    icon: 'i-lucide-flame',
    iconClass: 'bg-orange-100 text-orange-700 dark:bg-orange-950/60 dark:text-orange-300',
    interactive: true,
    active: props.hotFilterActive === true
  },
  {
    key: 'value' as const,
    label: props.filtered
      ? t('leads.summary.potentialValueFiltered')
      : t('leads.summary.potentialValue'),
    value: formatCurrency(summary.value.potentialValue),
    icon: 'i-lucide-circle-dollar-sign',
    iconClass: 'bg-sky-100 text-sky-700 dark:bg-sky-950/60 dark:text-sky-300',
    interactive: false,
    active: false
  }
])

function onCardClick(key: 'active' | 'hot' | 'value') {
  if (key === 'hot') {
    emit('toggle-hot')
    return
  }
  if (key === 'active') {
    emit('show-all')
  }
}
</script>

<template>
  <div class="grid gap-3 sm:grid-cols-3">
    <component
      :is="card.interactive ? 'button' : 'div'"
      v-for="card in cards"
      :key="card.key"
      :type="card.interactive ? 'button' : undefined"
      class="rounded-2xl border bg-white px-4 py-4 text-start transition-all dark:bg-gray-900"
      :class="[
        card.interactive ? 'cursor-pointer' : '',
        card.active
          ? 'border-menu-section ring-2 ring-menu-section/30 shadow-sm dark:border-primary dark:ring-primary/30'
          : 'border-gray-200 dark:border-gray-800',
        card.interactive && !card.active
          ? 'hover:border-gray-300 hover:shadow-sm dark:hover:border-gray-700'
          : ''
      ]"
      @click="card.interactive ? onCardClick(card.key) : undefined"
    >
      <div class="flex items-center gap-3">
        <span
          class="inline-flex size-10 shrink-0 items-center justify-center rounded-xl"
          :class="card.iconClass"
        >
          <UIcon
            :name="card.icon"
            class="size-5"
          />
        </span>
        <div class="min-w-0">
          <p class="truncate text-sm text-gray-500 dark:text-gray-400">
            {{ card.label }}
          </p>
          <p class="text-2xl font-semibold text-gray-900 dark:text-gray-100">
            {{ card.value }}
          </p>
        </div>
      </div>
    </component>
  </div>
</template>
