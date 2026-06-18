<script setup lang="ts">
import type { Company, Contact, ModuleStatus, SalesTeam, Task, TaskAssignee, TaskStatusHistoryInput } from '~/types/crm'
import type { TaskType } from '~/config/masterTasks'
import {
  TASK_PRIORITIES,
  TASK_TYPE_ICONS,
  TASK_TYPES
} from '~/config/masterTasks'
import {
  appFormErrorClass,
  appFormFieldClass,
  appFormHintClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import {
  defaultTaskFormInput,
  appendStatusChange,
  initialStatusHistoryEntry,
  resolveDefaultModuleStatus,
  statusHistoryEntriesToFormInput,
  taskFormModuleStatuses,
  taskToFormInput,
  taskTypeChipStyle
} from '~/utils/masterTasks'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'
import { salesTeamDisplayLabel } from '~/utils/masterSalesTeam'
import { useTaskStatusLabel } from '~/composables/useTaskStatusLabel'

type AssignTargetMode = 'team' | 'person'

const open = defineModel<boolean>('open', { required: true })

const props = defineProps<{
  task: Task | null
  statuses: ModuleStatus[]
  assignees: TaskAssignee[]
  salesTeams: SalesTeam[]
  companies: Company[]
  contacts: Contact[]
}>()

const emit = defineEmits<{ saved: [] }>()

const { t } = useI18n()
const { profile } = useProfile()
const { create, update, listStatusHistory } = useTasks()
const { moduleStatusLabel } = useTaskStatusLabel()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultTaskFormInput())
const statusHistory = ref<TaskStatusHistoryInput[]>([])
const historyLoading = ref(false)
const assignTargetMode = ref<AssignTargetMode>('person')

const isCreate = computed(() => !props.task)

const modalTitle = computed(() =>
  isCreate.value ? t('tasks.createTitle') : t('tasks.editTitle')
)

const modalDescription = computed(() =>
  isCreate.value ? t('tasks.createSubtitle') : t('tasks.editSubtitle')
)

const noneOption = computed(() => ({
  label: t('tasks.none'),
  value: null as string | null
}))

const typeOptions = computed(() =>
  TASK_TYPES.map(value => ({
    value,
    label: t(`tasks.options.type.${value}`),
    icon: TASK_TYPE_ICONS[value]
  }))
)

const statusOptions = computed(() =>
  taskFormModuleStatuses(props.statuses, props.task?.module_status_id).map(row => ({
    label: moduleStatusLabel(row),
    value: row.id
  }))
)

const hasStatusOptions = computed(() => statusOptions.value.length > 0)

const priorityOptions = computed(() =>
  TASK_PRIORITIES.map(value => ({
    label: t(`tasks.options.priority.${value}`),
    value
  }))
)

const allAssigneeOptions = computed(() => [
  noneOption.value,
  ...props.assignees.map(user => ({
    label: user.full_name?.trim() || user.username || user.id,
    value: user.id
  }))
])

const salesTeamOptions = computed(() => [
  noneOption.value,
  ...props.salesTeams.map(team => ({
    label: salesTeamDisplayLabel(team),
    value: team.id
  }))
])

const companyOptions = computed(() => [
  noneOption.value,
  ...props.companies.map(company => ({
    label: company.name,
    value: company.id
  }))
])

const contactOptions = computed(() => {
  let rows = props.contacts
  if (form.value.company_id) {
    rows = rows.filter(contact => contact.company_id === form.value.company_id)
  }
  return [
    noneOption.value,
    ...rows.map(contact => ({
      label: [contact.first_name, contact.last_name].filter(Boolean).join(' ').trim() || contact.id,
      value: contact.id
    }))
  ]
})

function resetAssignTargetMode() {
  if (props.task?.sales_team_id) {
    assignTargetMode.value = 'team'
    return
  }
  assignTargetMode.value = 'person'
}

function setAssignTargetMode(mode: AssignTargetMode) {
  if (assignTargetMode.value === mode) return
  assignTargetMode.value = mode
  if (mode === 'team') {
    form.value.assigned_to = null
  } else {
    form.value.sales_team_id = null
  }
}

function resetForm() {
  if (isCreate.value) {
    form.value = defaultTaskFormInput()
    form.value.module_status_id = resolveDefaultModuleStatus(props.statuses)?.id ?? null
    form.value.assigned_by = profile.value?.id ?? null
    assignTargetMode.value = 'person'
    statusHistory.value = form.value.module_status_id
      ? initialStatusHistoryEntry(form.value.module_status_id)
      : []
  } else if (props.task) {
    form.value = taskToFormInput(props.task)
    resetAssignTargetMode()
    statusHistory.value = []
    void loadStatusHistory()
  }
  errorMsg.value = ''
}

async function loadStatusHistory() {
  if (!props.task) return
  historyLoading.value = true
  try {
    const rows = await listStatusHistory(props.task.id)
    statusHistory.value = statusHistoryEntriesToFormInput(rows)
  } catch (error) {
    console.error(error)
    statusHistory.value = []
  } finally {
    historyLoading.value = false
  }
}

watch(() => form.value.module_status_id, (statusId, prev) => {
  if (!statusId || statusId === prev) return
  statusHistory.value = appendStatusChange(statusHistory.value, statusId)
})

watch(open, (isOpen) => {
  if (isOpen) resetForm()
})

watch(() => form.value.company_id, (companyId, prev) => {
  if (prev && companyId !== prev && form.value.contact_id) {
    const contact = props.contacts.find(row => row.id === form.value.contact_id)
    if (contact?.company_id !== companyId) {
      form.value.contact_id = null
    }
  }
})

async function onSubmit() {
  errorMsg.value = ''
  if (!form.value.subject.trim()) {
    errorMsg.value = t('tasks.errors.subjectRequired')
    return
  }
  if (!form.value.module_status_id) {
    errorMsg.value = t('tasks.errors.statusRequired')
    return
  }

  saving.value = true
  try {
    const payload = { ...form.value, status_history: statusHistory.value }
    if (assignTargetMode.value === 'team') {
      payload.assigned_to = null
    } else {
      payload.sales_team_id = null
    }
    if (isCreate.value) {
      await create(payload)
    } else {
      await update(props.task!.id, payload)
    }
    open.value = false
    emit('saved')
  } catch (error) {
    errorMsg.value = getSupabaseErrorMessage(error, t('tasks.errors.saveFailed'))
  } finally {
    saving.value = false
  }
}

function selectType(value: TaskType) {
  form.value.task_type = value
}

const taskFormSectionClass
  = 'space-y-4 rounded-xl border border-gray-200 bg-gray-50/60 p-4 dark:border-gray-800 dark:bg-gray-900/30'
</script>

<template>
  <AppDialog
    v-model:open="open"
    :title="modalTitle"
    :description="modalDescription"
    size="xl"
  >
    <form
      id="tasks-form"
      class="space-y-6"
      @submit.prevent="onSubmit"
    >
      <p
        v-if="errorMsg"
        :class="appFormErrorClass"
        role="alert"
      >
        {{ errorMsg }}
      </p>

      <div
        v-if="!isCreate && task"
        class="flex flex-wrap items-center gap-x-2 gap-y-1 rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-sm dark:border-gray-700 dark:bg-gray-900/40"
      >
        <span class="text-gray-500 dark:text-gray-400">{{ t('tasks.fields.taskCode') }}</span>
        <span class="font-semibold text-gray-900 dark:text-gray-100">{{ task.task_code }}</span>
      </div>

      <div class="space-y-4">
        <UFormField
          :label="t('tasks.fields.activityType')"
          required
        >
          <div
            class="grid grid-cols-2 gap-2 sm:grid-cols-5"
            role="group"
            :aria-label="t('tasks.fields.activityType')"
          >
            <UButton
              v-for="option in typeOptions"
              :key="option.value"
              type="button"
              size="md"
              class="justify-center"
              variant="outline"
              color="neutral"
              :style="taskTypeChipStyle(option.value, form.task_type === option.value)"
              @click="selectType(option.value)"
            >
              <UIcon
                :name="option.icon"
                class="size-4 shrink-0"
              />
              {{ option.label }}
            </UButton>
          </div>
        </UFormField>

        <UFormField
          :label="t('tasks.fields.subject')"
          required
        >
          <UInput
            v-model="form.subject"
            size="lg"
            autofocus
            :class="appFormFieldClass"
            :ui="appInputUi"
            :placeholder="t('tasks.fields.subjectPlaceholder')"
          />
        </UFormField>
      </div>

      <section :class="taskFormSectionClass">
        <h3 class="text-sm font-semibold font-heading text-gray-900 dark:text-gray-100">
          {{ t('tasks.sections.schedule') }}
        </h3>

        <div class="grid gap-4 sm:grid-cols-2">
          <UFormField :label="t('tasks.fields.status')">
            <USelectMenu
              v-if="hasStatusOptions"
              v-model="form.module_status_id"
              size="lg"
              :items="statusOptions"
              value-key="value"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
            <p
              v-else
              :class="appFormHintClass"
            >
              {{ t('tasks.statusesMissing') }}
            </p>
          </UFormField>

          <UFormField :label="t('tasks.fields.priority')">
            <USelectMenu
              v-model="form.priority"
              size="lg"
              :items="priorityOptions"
              value-key="value"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
          </UFormField>

          <UFormField :label="t('tasks.fields.startDate')">
            <UInput
              v-model="form.start_at"
              type="date"
              size="lg"
              :class="appFormFieldClass"
              :ui="appInputUi"
            />
          </UFormField>

          <UFormField :label="t('tasks.fields.endDate')">
            <UInput
              v-model="form.end_at"
              type="date"
              size="lg"
              :class="appFormFieldClass"
              :ui="appInputUi"
            />
          </UFormField>
        </div>

        <div
          v-if="form.module_status_id"
          class="border-t border-gray-200 pt-4 dark:border-gray-700"
        >
          <div class="mb-3">
            <h4 class="text-sm font-semibold font-heading text-gray-900 dark:text-gray-100">
              {{ t('tasks.statusChangeLog.title') }}
            </h4>
            <p :class="appFormHintClass">
              {{ t('tasks.statusChangeLog.hint') }}
            </p>
          </div>

          <div
            v-if="historyLoading"
            class="py-4 text-sm text-gray-500 dark:text-gray-400"
          >
            {{ t('common.loading') }}
          </div>
          <TasksStatusChangeLog
            v-else
            v-model:history="statusHistory"
            :statuses="statuses"
          />
        </div>
      </section>

      <section :class="taskFormSectionClass">
        <div>
          <h3 class="text-sm font-semibold font-heading text-gray-900 dark:text-gray-100">
            {{ t('tasks.sections.related') }}
          </h3>
          <p :class="appFormHintClass">
            {{ t('tasks.sections.relatedHint') }}
          </p>
        </div>

        <div class="grid gap-4 sm:grid-cols-2">
          <div class="space-y-4 sm:col-span-2">
            <UFormField
              :label="t('tasks.fields.assignTarget')"
              :hint="t('tasks.fields.assignTargetHint')"
            >
              <div
                class="grid grid-cols-2 gap-2"
                role="group"
                :aria-label="t('tasks.fields.assignTarget')"
              >
                <UButton
                  type="button"
                  size="lg"
                  class="justify-center"
                  :variant="assignTargetMode === 'team' ? 'solid' : 'outline'"
                  color="primary"
                  @click="setAssignTargetMode('team')"
                >
                  {{ t('tasks.fields.assignTargetTeam') }}
                </UButton>
                <UButton
                  type="button"
                  size="lg"
                  class="justify-center"
                  :variant="assignTargetMode === 'person' ? 'solid' : 'outline'"
                  color="primary"
                  @click="setAssignTargetMode('person')"
                >
                  {{ t('tasks.fields.assignTargetPerson') }}
                </UButton>
              </div>
            </UFormField>

            <UFormField
              v-if="assignTargetMode === 'team'"
              :label="t('tasks.fields.salesTeam')"
            >
              <USelectMenu
                v-model="form.sales_team_id"
                size="lg"
                searchable
                :items="salesTeamOptions"
                value-key="value"
                :class="appFormFieldClass"
                :ui="appSelectMenuUi"
              />
            </UFormField>

            <UFormField
              v-else
              :label="t('tasks.fields.assignedTo')"
            >
              <USelectMenu
                v-model="form.assigned_to"
                size="lg"
                searchable
                :items="allAssigneeOptions"
                value-key="value"
                :class="appFormFieldClass"
                :ui="appSelectMenuUi"
              />
            </UFormField>
          </div>

          <UFormField :label="t('tasks.fields.assignedBy')">
            <USelectMenu
              v-model="form.assigned_by"
              size="lg"
              searchable
              :items="allAssigneeOptions"
              value-key="value"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
          </UFormField>

          <UFormField :label="t('tasks.fields.customer')">
            <USelectMenu
              v-model="form.company_id"
              size="lg"
              searchable
              :items="companyOptions"
              value-key="value"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
          </UFormField>

          <UFormField :label="t('tasks.fields.contact')">
            <USelectMenu
              v-model="form.contact_id"
              size="lg"
              searchable
              :items="contactOptions"
              value-key="value"
              :class="appFormFieldClass"
              :ui="appSelectMenuUi"
            />
          </UFormField>
        </div>
      </section>

      <UFormField :label="t('tasks.fields.description')">
        <UTextarea
          v-model="form.description"
          :rows="4"
          :class="appFormFieldClass"
          :ui="appTextareaUi"
          :placeholder="t('tasks.fields.descriptionPlaceholder')"
        />
      </UFormField>
    </form>

    <template #footer>
      <AppDialogFooter @cancel="open = false">
        <UButton
          class="w-full sm:w-auto"
          type="submit"
          form="tasks-form"
          color="primary"
          size="lg"
          :loading="saving"
        >
          {{ isCreate ? t('tasks.create') : t('tasks.save') }}
        </UButton>
      </AppDialogFooter>
    </template>
  </AppDialog>
</template>
