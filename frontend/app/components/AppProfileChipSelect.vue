<script setup lang="ts">
import type { SalesTeamProfileSummary } from '~/types/crm'
import { appFormFieldClass, appSelectMenuUi } from '~/config/appFormUi'
import { profileSummaryDisplayName } from '~/utils/masterSalesTeam'
import { normalizeSelectValue } from '~/utils/normalizeSelectValue'

const model = defineModel<string[]>({ required: true })

const props = withDefaults(defineProps<{
  options: SalesTeamProfileSummary[]
  disabled?: boolean
  readonly?: boolean
}>(), {
  disabled: false,
  readonly: false
})

const { t } = useI18n()

const pickerValue = ref<string | null>(null)

const optionsById = computed(() =>
  new Map(props.options.map(profile => [profile.id, profile]))
)

const selectedProfiles = computed(() =>
  model.value
    .map(id => optionsById.value.get(id))
    .filter((profile): profile is SalesTeamProfileSummary => Boolean(profile))
)

const availableOptions = computed(() =>
  [...props.options]
    .filter(profile => !model.value.includes(profile.id))
    .sort((a, b) =>
      profileSummaryDisplayName(a).localeCompare(profileSummaryDisplayName(b), 'th')
    )
    .map(profile => ({
      value: profile.id,
      label: profileSummaryDisplayName(profile)
    }))
)

const canEdit = computed(() => !props.disabled && !props.readonly)

function addMember(rawId: unknown) {
  const id = normalizeSelectValue(rawId)
  if (!id || !canEdit.value || model.value.includes(id)) return
  model.value = [...model.value, id]
  pickerValue.value = null
}

function removeMember(id: string) {
  if (!canEdit.value) return
  model.value = model.value.filter(profileId => profileId !== id)
}

watch(pickerValue, (value) => {
  if (value) addMember(value)
})
</script>

<template>
  <div class="space-y-3">
    <USelectMenu
      v-if="canEdit && options.length"
      v-model="pickerValue"
      :items="availableOptions"
      value-key="value"
      searchable
      size="lg"
      :placeholder="t('masterData.salesTeam.fields.addMemberPlaceholder')"
      :disabled="!availableOptions.length"
      :class="appFormFieldClass"
      :ui="appSelectMenuUi"
    />

    <p
      v-else-if="canEdit && !options.length"
      class="rounded-xl border border-dashed border-gray-200 px-4 py-3 text-sm text-gray-500 dark:border-gray-700"
    >
      {{ t('masterData.salesTeam.noProfilesAvailable') }}
    </p>

    <div
      v-if="selectedProfiles.length"
      class="flex flex-wrap gap-2"
      role="list"
      :aria-label="t('masterData.salesTeam.fields.members')"
    >
      <UBadge
        v-for="profile in selectedProfiles"
        :key="profile.id"
        color="primary"
        variant="subtle"
        size="lg"
        class="inline-flex items-center gap-1.5 rounded-full px-2 py-1.5"
        role="listitem"
      >
        <AppUserAvatar
          :src="profile.avatar_url"
          :alt="profileSummaryDisplayName(profile)"
          size="sm"
        />
        <span>{{ profileSummaryDisplayName(profile) }}</span>
        <button
          v-if="canEdit"
          type="button"
          class="ml-0.5 rounded-full p-0.5 text-primary/80 hover:bg-primary/10 hover:text-primary focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/50"
          :aria-label="t('masterData.salesTeam.fields.removeMember', { name: profileSummaryDisplayName(profile) })"
          @click="removeMember(profile.id)"
        >
          <UIcon
            name="i-lucide-x"
            class="size-3.5"
          />
        </button>
      </UBadge>
    </div>

    <p
      v-else-if="readonly"
      class="text-sm text-gray-500"
    >
      —
    </p>
    <p
      v-else-if="canEdit"
      class="text-sm text-gray-500"
    >
      {{ t('masterData.salesTeam.fields.noMembersSelected') }}
    </p>
  </div>
</template>
