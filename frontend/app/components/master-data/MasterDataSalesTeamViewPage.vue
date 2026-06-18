<script setup lang="ts">
import type { SalesTeamProfileSummary } from '~/types/crm'
import {
  profileSummaryDisplayName,
  salesTeamDisplayLabel,
  salesTeamToFormInput
} from '~/utils/masterSalesTeam'

const props = defineProps<{
  teamId: string
}>()

const { t } = useI18n()
const { get, listActiveProfiles } = useSalesTeams()

const loading = ref(true)
const form = ref(salesTeamToFormInput({
  id: '',
  org_id: '',
  team_code: '',
  name: '',
  description: null,
  team_lead_id: null,
  sort_order: 0,
  status: 'active',
  notes: null,
  created_at: '',
  updated_at: ''
}))
const profileOptions = ref<SalesTeamProfileSummary[]>([])
const deleteOpen = ref(false)

try {
  const [row, profiles] = await Promise.all([
    get(props.teamId),
    listActiveProfiles()
  ])
  form.value = salesTeamToFormInput(row)
  profileOptions.value = profiles

  for (const member of row.sales_team_members ?? []) {
    const profile = member.profiles
    if (profile && !profileOptions.value.some(p => p.id === profile.id)) {
      profileOptions.value = [...profileOptions.value, profile]
    }
  }
  if (
    row.team_lead
    && !profileOptions.value.some(p => p.id === row.team_lead!.id)
  ) {
    profileOptions.value = [...profileOptions.value, row.team_lead]
  }
} catch (e) {
  console.error(e)
  await navigateTo('/app/sales-team')
} finally {
  loading.value = false
}

function onDeleted() {
  navigateTo('/app/sales-team')
}
</script>

<template>
  <div>
    <UButton
      to="/app/sales-team"
      variant="ghost"
      color="neutral"
      icon="i-lucide-arrow-left"
      size="sm"
      class="mb-4"
    >
      {{ t('common.back') }}
    </UButton>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <div
      v-else
      class="lg:grid lg:grid-cols-[minmax(0,1fr)_17rem] lg:items-start lg:gap-6"
    >
      <div class="min-w-0 space-y-6">
        <h1 class="text-2xl font-bold font-heading">
          {{ salesTeamDisplayLabel(form) }}
        </h1>
        <p class="text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.salesTeam.viewSubtitle') }}
        </p>

        <MasterDataSalesTeamForm
          v-model="form"
          :profile-options="profileOptions"
          readonly
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.salesTeam.actions') }}
          </p>
          <UButton
            block
            size="lg"
            icon="i-lucide-pencil"
            :to="`/app/sales-team/${teamId}/edit`"
          >
            {{ t('common.edit') }}
          </UButton>
          <UButton
            block
            class="mt-2"
            color="error"
            variant="soft"
            icon="i-lucide-trash-2"
            @click="deleteOpen = true"
          >
            {{ t('common.delete') }}
          </UButton>
        </UCard>
      </aside>
    </div>

    <MasterDataSalesTeamDeleteModal
      v-model:open="deleteOpen"
      :team-id="teamId"
      :team-name="salesTeamDisplayLabel(form)"
      @deleted="onDeleted"
    />
  </div>
</template>
