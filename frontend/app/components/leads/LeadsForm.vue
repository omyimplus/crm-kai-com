<script setup lang="ts">
import type { LeadSource, ModuleStatus, TaskAssignee } from '~/types/crm'
import type { LeadFormInput } from '~/types/crm'
import {
  LEAD_PRIORITIES,
  LEAD_TYPES,
  leadsSectionThemes
} from '~/config/masterLeads'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import { leadFormModuleStatuses } from '~/utils/masterLeads'
import { useLeadStatusLabel } from '~/composables/useLeadStatusLabel'

const props = defineProps<{
  modelValue: LeadFormInput
  statuses: ModuleStatus[]
  assignees: TaskAssignee[]
  leadSources: LeadSource[]
  leadCode?: string | null
  readonly?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: LeadFormInput]
}>()

const { t } = useI18n()
const { moduleStatusLabel } = useLeadStatusLabel()

const form = computed({
  get: () => props.modelValue,
  set: value => emit('update:modelValue', value)
})

const noneOption = computed(() => ({
  label: t('leads.none'),
  value: null as string | null
}))

const leadTypeOptions = computed(() =>
  LEAD_TYPES.map(value => ({
    value,
    label: t(`leads.options.leadType.${value}`)
  }))
)

const statusOptions = computed(() =>
  leadFormModuleStatuses(props.statuses, form.value.module_status_id).map(row => ({
    label: moduleStatusLabel(row),
    value: row.id
  }))
)

const priorityOptions = computed(() =>
  LEAD_PRIORITIES.map(value => ({
    value,
    label: t(`leads.options.priority.${value}`)
  }))
)

const assigneeOptions = computed(() => [
  noneOption.value,
  ...props.assignees.map(user => ({
    label: user.full_name?.trim() || user.username || user.id,
    value: user.id
  }))
])

const leadSourceOptions = computed(() => [
  noneOption.value,
  ...props.leadSources.map(source => ({
    label: source.name,
    value: source.id
  }))
])
</script>

<template>
  <div class="space-y-6">
    <div
      v-if="leadCode"
      class="flex flex-wrap items-center gap-x-2 gap-y-1 rounded-xl border border-gray-200 bg-white px-4 py-2.5 text-sm dark:border-gray-700 dark:bg-gray-900/40"
    >
      <span class="text-gray-500 dark:text-gray-400">{{ t('leads.fields.leadCode') }}</span>
      <span class="font-semibold text-gray-900 dark:text-gray-100">{{ leadCode }}</span>
      <UBadge
        color="primary"
        variant="soft"
        size="sm"
      >
        {{ t('leads.badge') }}
      </UBadge>
    </div>

    <AppFormSection
      :title="t('leads.sections.general')"
      :icon="leadsSectionThemes.general.icon"
      :icon-class="leadsSectionThemes.general.iconClass"
    >
      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <UFormField :label="t('leads.fields.leadType')">
          <USelectMenu
            v-model="form.lead_type"
            size="lg"
            :disabled="readonly"
            :items="leadTypeOptions"
            value-key="value"
            :placeholder="t('leads.fields.leadTypePlaceholder')"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField :label="t('leads.fields.owner')">
          <USelectMenu
            v-model="form.owner_id"
            size="lg"
            searchable
            :disabled="readonly"
            :items="assigneeOptions"
            value-key="value"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField :label="t('leads.fields.teleSale')">
          <USelectMenu
            v-model="form.tele_sale_id"
            size="lg"
            searchable
            :disabled="readonly"
            :items="assigneeOptions"
            value-key="value"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField :label="t('leads.fields.fullName')">
          <UInput
            v-model="form.full_name"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
            :placeholder="t('leads.fields.fullNamePlaceholder')"
          />
        </UFormField>

        <UFormField :label="t('leads.fields.leadValue')">
          <UInput
            v-model="form.lead_value"
            type="number"
            min="0"
            step="0.01"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField :label="t('leads.fields.leadSource')">
          <USelectMenu
            v-model="form.lead_source_id"
            size="lg"
            searchable
            :disabled="readonly"
            :items="leadSourceOptions"
            value-key="value"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('leads.fields.status')"
          required
        >
          <USelectMenu
            v-model="form.module_status_id"
            size="lg"
            :disabled="readonly"
            :items="statusOptions"
            value-key="value"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField :label="t('leads.fields.priority')">
          <USelectMenu
            v-model="form.priority"
            size="lg"
            :disabled="readonly"
            :items="priorityOptions"
            value-key="value"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField :label="t('leads.fields.nextActionDate')">
          <UInput
            v-model="form.next_action_at"
            type="date"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField :label="t('leads.fields.nextAction')">
          <UInput
            v-model="form.next_action"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>
      </div>
    </AppFormSection>

    <slot />

    <AppFormSection
      :title="t('leads.sections.score')"
      :icon="leadsSectionThemes.score.icon"
      :icon-class="leadsSectionThemes.score.iconClass"
    >
      <LeadsScoreControl
        v-model="form.lead_score"
        :readonly="readonly"
      />
    </AppFormSection>

    <AppFormSection
      :title="t('leads.sections.requirement')"
      :icon="leadsSectionThemes.requirement.icon"
      :icon-class="leadsSectionThemes.requirement.iconClass"
    >
      <UFormField :label="t('leads.fields.requirement')">
        <UTextarea
          v-model="form.requirement"
          :rows="4"
          :disabled="readonly"
          :class="appFormFieldClass"
          :ui="appTextareaUi"
          :placeholder="t('leads.fields.requirementPlaceholder')"
        />
      </UFormField>
    </AppFormSection>
  </div>
</template>
