<script setup lang="ts">
import type { Task } from '~/types/crm'
import { groupTasksByStartDate } from '~/utils/masterTasks'

const props = defineProps<{
  tasks: Task[]
  month: Date
}>()

const emit = defineEmits<{
  'update:month': [value: Date]
  select: [task: Task]
}>()

const { t, locale } = useI18n()

const dayDialogOpen = ref(false)
const selectedDateKey = ref<string | null>(null)

const weekdayLabels = computed(() => {
  const base = locale.value.startsWith('th') ? 'th-TH' : 'en-US'
  return Array.from({ length: 7 }, (_, index) => {
    const date = new Date(2024, 0, index)
    return new Intl.DateTimeFormat(base, { weekday: 'short' }).format(date)
  })
})

const monthLabel = computed(() => {
  const base = locale.value.startsWith('th') ? 'th-TH' : 'en-US'
  return new Intl.DateTimeFormat(base, { month: 'long', year: 'numeric' }).format(props.month)
})

const calendarCells = computed(() => {
  const year = props.month.getFullYear()
  const monthIndex = props.month.getMonth()
  const firstDay = new Date(year, monthIndex, 1)
  const startOffset = firstDay.getDay()
  const daysInMonth = new Date(year, monthIndex + 1, 0).getDate()
  const cells: Array<{ key: string, day: number | null, dateKey: string | null }> = []

  for (let i = 0; i < startOffset; i += 1) {
    cells.push({ key: `empty-start-${i}`, day: null, dateKey: null })
  }

  for (let day = 1; day <= daysInMonth; day += 1) {
    const dateKey = `${year}-${String(monthIndex + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`
    cells.push({ key: dateKey, day, dateKey })
  }

  while (cells.length % 7 !== 0) {
    cells.push({ key: `empty-end-${cells.length}`, day: null, dateKey: null })
  }

  return cells
})

const tasksByStartDate = computed(() => groupTasksByStartDate(props.tasks))

const selectedDayTasks = computed(() => {
  if (!selectedDateKey.value) return []
  return tasksByStartDate.value.get(selectedDateKey.value) ?? []
})

function taskCount(dateKey: string) {
  return tasksByStartDate.value.get(dateKey)?.length ?? 0
}

function isToday(dateKey: string | null): boolean {
  if (!dateKey) return false
  return dateKey === new Date().toISOString().slice(0, 10)
}

function openDay(dateKey: string) {
  selectedDateKey.value = dateKey
  dayDialogOpen.value = true
}

function shiftMonth(delta: number) {
  const next = new Date(props.month)
  next.setMonth(next.getMonth() + delta)
  emit('update:month', next)
}
</script>

<template>
  <div class="rounded-2xl border border-gray-200 bg-white p-4 dark:border-gray-800 dark:bg-gray-900">
    <div class="mb-4 flex items-center justify-between gap-3">
      <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100">
        {{ monthLabel }}
      </h2>
      <div class="flex items-center gap-2">
        <UButton
          variant="outline"
          color="neutral"
          icon="i-lucide-chevron-left"
          :aria-label="t('tasks.calendar.prevMonth')"
          @click="shiftMonth(-1)"
        />
        <UButton
          variant="outline"
          color="neutral"
          icon="i-lucide-chevron-right"
          :aria-label="t('tasks.calendar.nextMonth')"
          @click="shiftMonth(1)"
        />
      </div>
    </div>

    <div class="grid grid-cols-7 gap-2 text-center text-xs font-semibold uppercase tracking-wide text-gray-500 dark:text-gray-400">
      <div
        v-for="(label, index) in weekdayLabels"
        :key="`${label}-${index}`"
      >
        {{ label }}
      </div>
    </div>

    <div class="mt-2 grid grid-cols-7 gap-2">
      <div
        v-for="cell in calendarCells"
        :key="cell.key"
        class="flex min-h-28 flex-col rounded-xl border p-2 transition-colors"
        :class="cell.day
          ? cell.dateKey && taskCount(cell.dateKey)
            ? 'border-primary/35 bg-primary/5 shadow-sm dark:border-primary/45 dark:bg-primary/10'
            : isToday(cell.dateKey)
              ? 'border-primary/30 bg-white ring-1 ring-primary/25 dark:border-primary/40 dark:bg-gray-950/40'
              : 'border-gray-100 bg-white dark:border-gray-800 dark:bg-gray-950/40'
          : 'border-transparent bg-gray-50/60 dark:bg-gray-900/40'"
      >
        <div
          v-if="cell.day"
          class="flex items-start"
        >
          <span
            class="inline-flex size-7 shrink-0 items-center justify-center rounded-full text-sm font-bold tabular-nums"
            :class="isToday(cell.dateKey)
              ? 'bg-primary text-white shadow-sm'
              : 'text-gray-800 dark:text-gray-200'"
          >
            {{ cell.day }}
          </span>
        </div>

        <button
          v-if="cell.dateKey && taskCount(cell.dateKey)"
          type="button"
          class="mt-auto flex w-full items-center justify-center gap-1.5 rounded-lg bg-primary px-2 py-2 text-white shadow-sm transition hover:bg-primary/90 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary active:scale-[0.98]"
          :aria-label="t('tasks.calendar.openDay', { count: taskCount(cell.dateKey) })"
          @click="openDay(cell.dateKey)"
        >
          <UIcon
            name="i-lucide-list-todo"
            class="size-4 shrink-0 opacity-95"
          />
          <span class="text-sm font-bold leading-none tabular-nums">
            {{ taskCount(cell.dateKey) }}
          </span>
          <span class="text-xs font-semibold leading-none opacity-95">
            {{ t('tasks.calendar.taskCountLabel') }}
          </span>
        </button>

        <div
          v-else-if="cell.day"
          class="mt-auto min-h-9"
          aria-hidden="true"
        />
      </div>
    </div>

    <TasksCalendarDayDialog
      v-model:open="dayDialogOpen"
      :date-key="selectedDateKey"
      :tasks="selectedDayTasks"
      @select="emit('select', $event)"
    />
  </div>
</template>
