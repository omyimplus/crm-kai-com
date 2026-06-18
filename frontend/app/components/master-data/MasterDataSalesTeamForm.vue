<script setup lang="ts">
import type { SalesTeamProfileSummary } from '~/types/crm'
import type { MasterSalesTeamFormInput } from '~/utils/masterSalesTeam'
import {
  appFormFieldClass,
  appInputUi,
  appSelectMenuUi,
  appTextareaUi
} from '~/config/appFormUi'
import { SALES_TEAM_STATUSES, masterSalesTeamSectionThemes } from '~/config/masterSalesTeam'
import {
  profileSummaryDisplayName
} from '~/utils/masterSalesTeam'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'

const props = defineProps<{
  modelValue: MasterSalesTeamFormInput
  profileOptions: SalesTeamProfileSummary[]
  readonly?: boolean
}>()

const emit = defineEmits<{
  'update:modelValue': [value: MasterSalesTeamFormInput]
}>()

const { t } = useI18n()

const form = computed({
  get: () => props.modelValue,
  set: (value) => {
    emit('update:modelValue', {
      ...value,
      status: typeof value.status === 'string'
        ? value.status
        : normalizeSelectValue(value.status) ?? 'active',
      team_lead_id: normalizeSelectValue(value.team_lead_id)
    })
  }
})

const statusOptions = computed(() =>
  SALES_TEAM_STATUSES.map(value => ({
    value,
    label: t(`masterData.salesTeam.options.status.${value}`)
  }))
)

const teamLeadOptions = computed(() => {
  const selectedMembers = new Set(form.value.member_profile_ids)
  const candidates = props.profileOptions.filter(p => selectedMembers.has(p.id))

  return [
    { value: null, label: t('masterData.salesTeam.fields.teamLeadNone') },
    ...candidates.map(profile => ({
      value: profile.id,
      label: profileSummaryDisplayName(profile)
    }))
  ]
})

const showTeamLeadField = computed(() => form.value.member_profile_ids.length > 0)

watch(
  () => form.value.member_profile_ids,
  (memberIds) => {
    if (
      form.value.team_lead_id
      && !memberIds.includes(form.value.team_lead_id)
    ) {
      form.value = {
        ...form.value,
        team_lead_id: null
      }
    }
  }
)
</script>

<template>
  <div class="grid grid-cols-1 gap-6 xl:grid-cols-2">
    <AppFormSection
      :title="t('masterData.salesTeam.sections.basicInfo')"
      :icon="masterSalesTeamSectionThemes.basicInfo.icon"
      :icon-class="masterSalesTeamSectionThemes.basicInfo.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.salesTeam.fields.code')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.team_code"
            size="lg"
            :disabled="readonly"
            :placeholder="t('masterData.salesTeam.fields.codePlaceholder')"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.salesTeam.fields.name')"
          required
          :class="appFormFieldClass"
        >
          <UInput
            v-model="form.name"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.salesTeam.fields.description')"
          :class="appFormFieldClass"
        >
          <UTextarea
            v-model="form.description"
            :rows="3"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appTextareaUi"
          />
        </UFormField>
      </div>
    </AppFormSection>

    <AppFormSection
      :title="t('masterData.salesTeam.sections.settings')"
      :icon="masterSalesTeamSectionThemes.settings.icon"
      :icon-class="masterSalesTeamSectionThemes.settings.iconClass"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.salesTeam.fields.sortOrder')"
          :class="appFormFieldClass"
        >
          <UInput
            v-model.number="form.sort_order"
            type="number"
            min="0"
            step="1"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appInputUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.salesTeam.fields.status')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.status"
            :items="statusOptions"
            value-key="value"
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <UFormField
          :label="t('masterData.salesTeam.fields.notes')"
          :class="appFormFieldClass"
        >
          <UTextarea
            v-model="form.notes"
            :rows="4"
            :disabled="readonly"
            :placeholder="t('masterData.salesTeam.fields.notesPlaceholder')"
            :class="appFormFieldClass"
            :ui="appTextareaUi"
          />
        </UFormField>
      </div>
    </AppFormSection>

    <AppFormSection
      :title="t('masterData.salesTeam.sections.members')"
      :icon="masterSalesTeamSectionThemes.members.icon"
      :icon-class="masterSalesTeamSectionThemes.members.iconClass"
      class="xl:col-span-2"
    >
      <div class="space-y-5">
        <UFormField
          :label="t('masterData.salesTeam.fields.members')"
          required
          :hint="t('masterData.salesTeam.fields.membersHint')"
          :class="appFormFieldClass"
        >
          <AppProfileChipSelect
            v-model="form.member_profile_ids"
            :options="profileOptions"
            :disabled="readonly"
            :readonly="readonly"
          />
        </UFormField>

        <UFormField
          v-if="showTeamLeadField"
          :label="t('masterData.salesTeam.fields.teamLead')"
          :hint="t('masterData.salesTeam.fields.teamLeadHint')"
          :class="appFormFieldClass"
        >
          <USelectMenu
            v-model="form.team_lead_id"
            :items="teamLeadOptions"
            value-key="value"
            searchable
            size="lg"
            :disabled="readonly"
            :class="appFormFieldClass"
            :ui="appSelectMenuUi"
          />
        </UFormField>

        <p
          v-else-if="!readonly"
          class="text-sm text-gray-500 dark:text-gray-400"
        >
          {{ t('masterData.salesTeam.fields.teamLeadAfterMembers') }}
        </p>
      </div>
    </AppFormSection>
  </div>
</template>
