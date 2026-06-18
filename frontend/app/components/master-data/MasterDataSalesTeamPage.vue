<script setup lang="ts">
import type { SalesTeamProfileSummary } from '~/types/crm'
import { appFormErrorClass } from '~/config/appFormUi'
import {
  defaultMasterSalesTeamFormInput,
  salesTeamSaveErrorMessage,
  salesTeamToFormInput,
  validateMasterSalesTeamForm
} from '~/utils/masterSalesTeam'

const props = defineProps<{
  mode: 'new' | 'edit'
  teamId?: string | null
}>()

const { t } = useI18n()
const { get, create, update, listActiveProfiles } = useSalesTeams()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterSalesTeamFormInput())
const profileOptions = ref<SalesTeamProfileSummary[]>([])

const isEdit = computed(() => props.mode === 'edit')

const pageTitle = computed(() =>
  isEdit.value ? t('masterData.salesTeam.editTitle') : t('masterData.salesTeam.newTitle')
)
const pageSubtitle = computed(() =>
  isEdit.value ? t('masterData.salesTeam.editSubtitle') : t('masterData.salesTeam.newSubtitle')
)

try {
  profileOptions.value = await listActiveProfiles()
} catch (e) {
  console.error(e)
  profileOptions.value = []
}

if (isEdit.value && props.teamId) {
  try {
    const row = await get(props.teamId)
    form.value = salesTeamToFormInput(row)

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
  }
}

async function save() {
  const validationKey = validateMasterSalesTeamForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.salesTeam.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    if (isEdit.value && props.teamId) {
      await update(props.teamId, form.value)
      await navigateTo(`/app/sales-team/${props.teamId}`)
    } else {
      const row = await create(form.value)
      await navigateTo(`/app/sales-team/${row.id}`)
    }
  } catch (e: unknown) {
    errorMsg.value = salesTeamSaveErrorMessage(e, t)
  } finally {
    saving.value = false
  }
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

    <form
      class="lg:grid lg:grid-cols-[minmax(0,1fr)_17rem] lg:items-start lg:gap-6"
      @submit.prevent="save"
    >
      <div class="min-w-0 space-y-6">
        <div>
          <h1 class="text-2xl font-bold font-heading">
            {{ pageTitle }}
          </h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ pageSubtitle }}
          </p>
        </div>

        <p
          v-if="errorMsg"
          :class="appFormErrorClass"
        >
          {{ errorMsg }}
        </p>

        <MasterDataSalesTeamForm
          v-model="form"
          :profile-options="profileOptions"
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.salesTeam.actions') }}
          </p>
          <UButton
            type="button"
            block
            size="lg"
            icon="i-lucide-check"
            :loading="saving"
            @click="save"
          >
            {{ isEdit ? t('common.save') : t('masterData.salesTeam.create') }}
          </UButton>
          <UButton
            type="button"
            block
            class="mt-2"
            variant="outline"
            color="neutral"
            to="/app/sales-team"
          >
            {{ t('common.cancel') }}
          </UButton>
        </UCard>
      </aside>
    </form>
  </div>
</template>
