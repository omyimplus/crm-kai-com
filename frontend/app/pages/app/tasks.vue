<script setup lang="ts">
import type { Company, Contact, ModuleStatus, SalesTeam, Task, TaskAssignee } from '~/types/crm'
import type { TaskType } from '~/config/masterTasks'
import { appTableGridViewOptions, type AppListCalendarViewMode, type AppTableGridViewMode } from '~/config/appViewMode'
import {
  TASK_TYPE_ICONS,
  TASK_TYPES
} from '~/config/masterTasks'
import {
  appFormFieldClass,
  appInputUi,
  appTableBadgeClass,
  appTableRowClass,
  appTableTextClass
} from '~/config/appFormUi'
import {
  resolveDefaultStatusCode,
  taskAssigneeDisplayName,
  taskDisplayName,
  taskMatchesDateRange,
  taskTypeChipStyle
} from '~/utils/masterTasks'
import { useTaskStatusLabel } from '~/composables/useTaskStatusLabel'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { taskStatusLabel } = useTaskStatusLabel()
const route = useRoute()
const router = useRouter()
const { formatDate } = useFormat()
const { ensureProfile } = useProfile()
const { ensurePermissions, canWriteModule } = usePermissions()
const { list, remove, listAssignees, ensureDefaults } = useTasks()
const { listByModule } = useModuleStatuses()
const { list: listCompanies } = useCompanies()
const { list: listContacts } = useContacts()
const { list: listSalesTeams } = useSalesTeams()

await ensureProfile()
await ensurePermissions()

type ViewMode = AppListCalendarViewMode

const listLayoutOptions = computed(() => appTableGridViewOptions(t))
const listLayout = ref<AppTableGridViewMode>('table')

const tasks = ref<Task[]>([])
const statuses = ref<ModuleStatus[]>([])
const assignees = ref<TaskAssignee[]>([])
const companies = ref<Company[]>([])
const contacts = ref<Contact[]>([])
const salesTeams = ref<SalesTeam[]>([])
const loading = ref(true)
const search = ref('')
const typeFilter = ref<TaskType | null>(null)
const defaultDateRange = currentMonthDateRange()
const scheduleFrom = ref(defaultDateRange.from)
const scheduleTo = ref(defaultDateRange.to)
const statusTab = ref('')
const calendarMonth = ref(new Date())
const formOpen = ref(false)
const editTarget = ref<Task | null>(null)
const deleteOpen = ref(false)
const deleteTarget = ref<Task | null>(null)
const customerInfoOpen = ref(false)
const customerInfoCompanyId = ref<string | null>(null)
const customerInfoContactId = ref<string | null>(null)
const statusChangeOpen = ref(false)
const statusChangeTarget = ref<Task | null>(null)

const canWrite = computed(() => canWriteModule('app.tasks'))

const viewMode = computed<ViewMode>({
  get() {
    return route.query.view === 'calendar' ? 'calendar' : 'list'
  },
  set(value) {
    const query = { ...route.query }
    if (value === 'calendar') {
      query.view = 'calendar'
    } else {
      delete query.view
    }
    router.replace({ query })
  }
})

const isCalendarView = computed(() => viewMode.value === 'calendar')

const activeStatusLabel = computed(() =>
  statusTab.value
    ? taskStatusLabel(statusTab.value)
    : t('tasks.emptyCell')
)

function syncStatusTab() {
  const defaultCode = resolveDefaultStatusCode(statuses.value)
  if (!defaultCode) {
    statusTab.value = ''
    return
  }
  const codes = statuses.value
    .filter(row => row.status === 'active')
    .map(row => row.status_code)
  if (statusTab.value && codes.includes(statusTab.value)) return
  statusTab.value = defaultCode
}

async function refresh() {
  loading.value = true
  try {
    await ensureDefaults()
    const [statusRows, assigneeRows, companyRows, contactRows, salesTeamRows] = await Promise.all([
      listByModule('task'),
      listAssignees(),
      listCompanies(),
      listContacts(),
      listSalesTeams()
    ])
    statuses.value = statusRows
    assignees.value = assigneeRows
    companies.value = companyRows
    contacts.value = contactRows
    salesTeams.value = salesTeamRows.filter(team => team.status === 'active')
    syncStatusTab()

    try {
      tasks.value = await list()
    } catch (error) {
      console.error(error)
      tasks.value = []
    }
  } catch (error) {
    console.error(error)
    tasks.value = []
    statuses.value = []
    statusTab.value = ''
  } finally {
    loading.value = false
  }
}

await refresh()

const filteredTasks = computed(() => {
  let rows = tasks.value

  if (viewMode.value === 'list' && statusTab.value) {
    rows = rows.filter(task => task.status_code === statusTab.value)
  }

  if (typeFilter.value) {
    rows = rows.filter(task => task.task_type === typeFilter.value)
  }

  if (!isCalendarView.value) {
    rows = rows.filter(task => taskMatchesDateRange(task, {
      from: scheduleFrom.value,
      to: scheduleTo.value
    }))
  }

  const q = search.value.trim().toLowerCase()
  if (!q) return rows

  return rows.filter((task) => {
    const haystack = [
      task.task_code,
      task.subject,
      task.company_name,
      task.contact_name,
      task.assigned_to_name,
      task.sales_team_name,
      taskStatusLabel(task.status_code, task.status_name)
    ].filter(Boolean).join(' ').toLowerCase()
    return haystack.includes(q)
  })
})

function isDefaultDateRange(): boolean {
  const range = currentMonthDateRange()
  return scheduleFrom.value === range.from && scheduleTo.value === range.to
}

const hasActiveFilters = computed(() =>
  search.value.trim().length > 0
  || typeFilter.value !== null
  || !isDefaultDateRange()
)

const {
  page,
  pagedItems,
  totalItems: paginationTotal,
  totalPages,
  rangeStart,
  rangeEnd,
  pageSize,
  resetPage: resetPagination
} = usePagination(filteredTasks)

function selectStatus(code: string) {
  statusTab.value = code
  if (isCalendarView.value) {
    viewMode.value = 'list'
  }
  resetPagination()
}

function clearFilters() {
  search.value = ''
  typeFilter.value = null
  const range = currentMonthDateRange()
  scheduleFrom.value = range.from
  scheduleTo.value = range.to
  resetPagination()
}

function openCreate() {
  editTarget.value = null
  formOpen.value = true
}

function openEdit(task: Task) {
  editTarget.value = task
  formOpen.value = true
}

function openDelete(task: Task) {
  deleteTarget.value = task
  deleteOpen.value = true
}

function openCustomerInfo(task: Task) {
  if (!task.company_id) return
  customerInfoCompanyId.value = task.company_id
  customerInfoContactId.value = task.contact_id
  customerInfoContactName.value = task.contact_name
  customerInfoOpen.value = true
}

function openStatusChange(task: Task) {
  statusChangeTarget.value = task
  statusChangeOpen.value = true
}

async function onSaved() {
  editTarget.value = null
  await refresh()
  resetPagination()
}

async function confirmDelete() {
  if (!deleteTarget.value) return
  await remove(deleteTarget.value.id)
  deleteTarget.value = null
  deleteOpen.value = false
  await refresh()
  resetPagination()
}

watch([typeFilter, search, scheduleFrom, scheduleTo, viewMode, listLayout], () => {
  resetPagination()
})
</script>

<template>
  <div class="space-y-5">
    <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
      <div>
        <h1 class="text-2xl font-bold font-heading text-gray-900 dark:text-gray-100">
          {{ t('tasks.pageTitle') }}
        </h1>
        <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
          {{ t('tasks.pageHint') }}
        </p>
      </div>

      <UButton
        v-if="canWrite"
        color="primary"
        size="lg"
        icon="i-lucide-plus"
        @click="openCreate"
      >
        {{ t('tasks.newTask') }}
      </UButton>
    </div>

    <TasksSummaryCards
      :tasks="tasks"
      :statuses="statuses"
      :active-status="statusTab"
      @select="selectStatus"
    />

    <UCard>
      <div class="space-y-4">
        <div class="flex flex-col gap-3 lg:flex-row lg:items-center">
          <UInput
            v-model="search"
            icon="i-lucide-search"
            :placeholder="t('tasks.filters.search')"
            :class="[appFormFieldClass, 'min-w-0 flex-1']"
            :ui="appInputUi"
          />

          <AppDateRangeFilter
            v-if="!isCalendarView"
            v-model:from="scheduleFrom"
            v-model:to="scheduleTo"
          />

          <div class="flex flex-wrap items-center gap-2 lg:shrink-0">
            <AppViewModeToggle
              v-if="!isCalendarView"
              v-model="listLayout"
              :options="listLayoutOptions"
              :group-aria-label="t('common.viewMode.groupLabel')"
            />

            <UButton
              :variant="isCalendarView ? 'solid' : 'outline'"
              :color="isCalendarView ? 'primary' : 'neutral'"
              :icon="isCalendarView ? 'i-lucide-list' : 'i-lucide-calendar'"
              @click="viewMode = isCalendarView ? 'list' : 'calendar'"
            >
              {{ isCalendarView ? t('tasks.views.backToList') : t('tasks.views.openCalendar') }}
            </UButton>

            <UButton
              v-if="hasActiveFilters"
              variant="soft"
              color="neutral"
              icon="i-lucide-rotate-ccw"
              @click="clearFilters"
            >
              {{ t('tasks.filters.clear') }}
            </UButton>
          </div>
        </div>

        <div
          class="flex flex-wrap gap-2"
          role="group"
          :aria-label="t('tasks.filters.typeGroup')"
        >
          <UButton
            size="sm"
            :variant="typeFilter === null ? 'solid' : 'soft'"
            :color="typeFilter === null ? 'primary' : 'neutral'"
            @click="typeFilter = null"
          >
            {{ t('tasks.filters.allTypes') }}
          </UButton>
          <UButton
            v-for="taskType in TASK_TYPES"
            :key="taskType"
            size="sm"
            variant="outline"
            color="neutral"
            :icon="TASK_TYPE_ICONS[taskType]"
            :style="taskTypeChipStyle(taskType, typeFilter === taskType)"
            @click="typeFilter = taskType"
          >
            {{ t(`tasks.options.type.${taskType}`) }}
          </UButton>
        </div>
      </div>
    </UCard>

    <UCard v-if="loading">
      <p class="text-gray-500 dark:text-gray-400">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <UCard v-else-if="!tasks.length">
      <div class="py-8 text-center">
        <p class="text-gray-600 dark:text-gray-300">
          {{ t('tasks.emptyAll') }}
        </p>
        <UButton
          v-if="canWrite"
          class="mt-4"
          icon="i-lucide-plus"
          @click="openCreate"
        >
          {{ t('tasks.createFirst') }}
        </UButton>
      </div>
    </UCard>

    <div v-else>
      <div
        v-if="isCalendarView"
        class="mb-3 flex flex-wrap items-center justify-between gap-2 rounded-xl border border-primary/20 bg-primary/5 px-4 py-3 dark:border-primary/30 dark:bg-primary/10"
      >
        <p
          class="text-sm font-medium text-gray-800 dark:text-gray-200"
          :class="appTableTextClass"
        >
          {{ t('tasks.views.calendarMode') }}
        </p>
        <UButton
          size="sm"
          variant="soft"
          icon="i-lucide-list"
          @click="viewMode = 'list'"
        >
          {{ t('tasks.views.backToList') }}
        </UButton>
      </div>

      <p
        v-if="!isCalendarView"
        class="mb-3 text-gray-600 dark:text-gray-400"
        :class="appTableTextClass"
      >
        {{
          t('tasks.filters.displayCount', {
            count: paginationTotal,
            status: activeStatusLabel
          })
        }}
      </p>

      <TasksCalendar
        v-if="isCalendarView"
        v-model:month="calendarMonth"
        :tasks="filteredTasks"
        @select="openEdit"
      />

      <div
        v-else-if="!filteredTasks.length"
        class="rounded-2xl border border-gray-200 bg-white px-4 py-10 text-center dark:border-gray-800 dark:bg-gray-900"
      >
        <p class="text-gray-500 dark:text-gray-400">
          {{ t('tasks.filters.noResults') }}
        </p>
        <UButton
          class="mt-4"
          size="sm"
          variant="soft"
          icon="i-lucide-rotate-ccw"
          @click="clearFilters"
        >
          {{ t('tasks.filters.clear') }}
        </UButton>
      </div>

      <div v-else-if="listLayout === 'grid'">
        <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
          <TasksTaskCard
            v-for="task in pagedItems"
            :key="task.id"
            :task="task"
            :contacts="contacts"
            :can-write="canWrite"
            @edit="openEdit"
            @delete="openDelete"
            @customer="openCustomerInfo"
            @status-change="openStatusChange"
          />
        </div>

        <AppPagination
          v-model:page="page"
          class="mt-4"
          :total-items="paginationTotal"
          :total-pages="totalPages"
          :range-start="rangeStart"
          :range-end="rangeEnd"
          :page-size="pageSize"
        />
      </div>

      <div
        v-else
        class="overflow-hidden rounded-lg border border-gray-200 dark:border-gray-800"
      >
        <AppDataTable
          embedded
          table-class="table-fixed min-w-[72rem]"
        >
          <template #head>
            <AppDataTableRow>
              <AppDataTableTh class="w-[18rem] max-w-[18rem]">
                {{ t('tasks.columns.task') }}
              </AppDataTableTh>
              <AppDataTableTh class="hidden w-[10rem] max-w-[10rem] lg:table-cell">
                {{ t('tasks.columns.customer') }}
              </AppDataTableTh>
              <AppDataTableTh class="hidden w-[9rem] max-w-[9rem] md:table-cell">
                {{ t('tasks.columns.contact') }}
              </AppDataTableTh>
              <AppDataTableTh class="hidden w-[7.5rem] max-w-[7.5rem] lg:table-cell">
                {{ t('tasks.columns.assignedBy') }}
              </AppDataTableTh>
              <AppDataTableTh class="hidden w-[7.5rem] max-w-[7.5rem] md:table-cell">
                {{ t('tasks.columns.assignedTo') }}
              </AppDataTableTh>
              <AppDataTableTh class="w-[6.5rem] whitespace-nowrap">
                {{ t('tasks.columns.priority') }}
              </AppDataTableTh>
              <AppDataTableTh class="w-[6.5rem] whitespace-nowrap">
                {{ t('tasks.columns.startDate') }}
              </AppDataTableTh>
              <AppDataTableTh class="w-[6.5rem] whitespace-nowrap">
                {{ t('tasks.columns.endDate') }}
              </AppDataTableTh>
              <AppDataTableTh
                align="right"
                class="w-[7.5rem] whitespace-nowrap"
                :aria-label="t('tasks.columns.actions')"
              />
            </AppDataTableRow>
          </template>

          <AppDataTableRow
            v-for="task in pagedItems"
            :key="task.id"
            class="cursor-pointer"
            :class="appTableRowClass"
            @click="openEdit(task)"
          >
            <AppDataTableTd
              class="max-w-[18rem]"
              :class="appTableRowClass"
            >
              <div class="flex min-w-0 items-start gap-3">
                <TasksTypeIcon
                  :type="task.task_type"
                  size="sm"
                />
                <div class="min-w-0 flex-1 overflow-hidden">
                  <p
                    class="truncate text-gray-900 dark:text-gray-100"
                    :title="taskDisplayName(task)"
                  >
                    {{ taskDisplayName(task) }}
                  </p>
                  <div class="mt-0.5 flex min-w-0 items-center gap-2 overflow-hidden">
                    <TasksTypeBadge
                      :type="task.task_type"
                      row-style
                      class="shrink-0"
                    />
                    <span class="truncate text-gray-500 dark:text-gray-400">
                      {{ task.task_code }}
                    </span>
                  </div>
                  <div class="mt-1 lg:hidden">
                    <TasksCustomerLink
                      :company-id="task.company_id"
                      :name="task.company_name"
                      row-style
                      @open="openCustomerInfo(task)"
                    />
                  </div>
                </div>
              </div>
            </AppDataTableTd>
            <AppDataTableTd
              class="hidden max-w-[10rem] lg:table-cell"
              :class="appTableRowClass"
              @click.stop
            >
              <TasksCustomerLink
                :company-id="task.company_id"
                :name="task.company_name"
                row-style
                @open="openCustomerInfo(task)"
              />
            </AppDataTableTd>
            <AppDataTableTd
              class="hidden max-w-[9rem] md:table-cell"
              :class="appTableRowClass"
            >
              <TasksContactCell
                :task="task"
                :contacts="contacts"
                row-style
              />
            </AppDataTableTd>
            <AppDataTableTd
              muted
              class="hidden max-w-[7.5rem] truncate lg:table-cell"
              :class="appTableRowClass"
              :title="task.assigned_by_name ?? undefined"
            >
              {{ task.assigned_by_name || t('tasks.emptyCell') }}
            </AppDataTableTd>
            <AppDataTableTd
              muted
              class="hidden max-w-[7.5rem] truncate md:table-cell"
              :class="appTableRowClass"
              :title="taskAssigneeDisplayName(task, t('tasks.emptyCell'))"
            >
              {{ taskAssigneeDisplayName(task, t('tasks.emptyCell')) }}
            </AppDataTableTd>
            <AppDataTableTd class="w-[6.5rem] text-center whitespace-nowrap">
              <TasksPriorityBadge :priority="task.priority" />
            </AppDataTableTd>
            <AppDataTableTd
              muted
              class="w-[6.5rem] truncate whitespace-nowrap"
              :class="appTableRowClass"
            >
              {{ task.start_at ? formatDate(task.start_at) : t('tasks.emptyCell') }}
            </AppDataTableTd>
            <AppDataTableTd
              muted
              class="w-[6.5rem] truncate whitespace-nowrap"
              :class="appTableRowClass"
            >
              {{ task.end_at ? formatDate(task.end_at) : t('tasks.emptyCell') }}
            </AppDataTableTd>
            <AppDataTableTd
              align="right"
              class="w-[7.5rem] whitespace-nowrap"
              @click.stop
            >
              <div class="inline-flex items-center justify-end gap-1">
                <AppIconButton
                  v-if="canWrite"
                  icon="i-lucide-arrow-left-right"
                  :aria-label="t('tasks.changeStatus.action')"
                  color="primary"
                  @click="openStatusChange(task)"
                />
                <AppIconButton
                  v-if="canWrite"
                  icon="i-lucide-pencil"
                  :aria-label="t('common.edit')"
                  @click="openEdit(task)"
                />
                <AppIconButton
                  v-if="canWrite"
                  icon="i-lucide-trash-2"
                  :aria-label="t('common.delete')"
                  color="error"
                  @click="openDelete(task)"
                />
              </div>
            </AppDataTableTd>
          </AppDataTableRow>
        </AppDataTable>

        <AppPagination
          v-model:page="page"
          embedded
          :total-items="paginationTotal"
          :total-pages="totalPages"
          :range-start="rangeStart"
          :range-end="rangeEnd"
          :page-size="pageSize"
        />
      </div>
    </div>

    <TasksStatusChangeModal
      v-model:open="statusChangeOpen"
      :task="statusChangeTarget"
      :statuses="statuses"
      @saved="onSaved"
    />

    <TasksFormModal
      v-model:open="formOpen"
      :task="editTarget"
      :statuses="statuses"
      :assignees="assignees"
      :sales-teams="salesTeams"
      :companies="companies"
      :contacts="contacts"
      @saved="onSaved"
    />

    <TasksCustomerInfoDialog
      v-model:open="customerInfoOpen"
      :company-id="customerInfoCompanyId"
      :linked-contact-id="customerInfoContactId"
      :linked-contact-name="customerInfoContactName"
    />

    <AppDialog
      :title="t('tasks.deleteTitle')"
      size="sm"
    >
      <p class="text-sm text-gray-600 dark:text-gray-300">
        {{ t('tasks.deleteConfirm', { name: deleteTarget ? taskDisplayName(deleteTarget) : '' }) }}
      </p>
      <template #footer>
        <AppDialogFooter @cancel="deleteOpen = false">
          <UButton
            color="error"
            size="lg"
            @click="confirmDelete"
          >
            {{ t('common.delete') }}
          </UButton>
        </AppDialogFooter>
      </template>
    </AppDialog>
  </div>
</template>
