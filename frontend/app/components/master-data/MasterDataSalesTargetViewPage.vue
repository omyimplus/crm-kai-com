<script setup lang="ts">
import {
  defaultMasterSalesTargetFormInput,
  profileDisplayName,
  salesTargetToFormInput
} from '~/utils/masterSalesTarget'

const props = defineProps<{
  targetId: string
}>()

const { t } = useI18n()
const { profile } = useProfile()
const { get } = useSalesTargets()
const { list: listUsers } = useSystemUsers()

const canManage = computed(() =>
  profile.value?.role === 'owner' || profile.value?.role === 'admin'
)

const loading = ref(true)
const form = ref(defaultMasterSalesTargetFormInput())
const assignees = ref<{ label: string, value: string }[]>([])
const achievementPct = ref<number | null>(null)
const assigneeFallbackName = ref('—')
const deleteOpen = ref(false)

try {
  const [row, users] = await Promise.all([
    get(props.targetId),
    listUsers()
  ])
  form.value = salesTargetToFormInput(row)
  achievementPct.value = row.achievement_pct ?? 0
  assigneeFallbackName.value = row.profiles
    ? profileDisplayName(row.profiles)
    : '—'
  assignees.value = users
    .filter(u => u.is_active)
    .map(u => ({
      label: profileDisplayName(u),
      value: u.id
    }))
  if (
    row.profile_id
    && !assignees.value.some(a => a.value === row.profile_id)
    && row.profiles
  ) {
    assignees.value.unshift({
      label: profileDisplayName(row.profiles),
      value: row.profile_id
    })
  }
} catch (e) {
  console.error(e)
  await navigateTo('/app/sales-target')
} finally {
  loading.value = false
}

const assigneeName = computed(() =>
  assignees.value.find(a => a.value === form.value.profile_id)?.label
  ?? assigneeFallbackName.value
)

function onRemoved() {
  navigateTo('/app/sales-target')
}
</script>

<template>
  <div>
    <UButton
      to="/app/sales-target"
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
        <div>
          <h1 class="text-2xl font-bold font-heading">
            {{ assigneeName }}
          </h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ t('masterData.salesTarget.viewSubtitle') }}
          </p>
        </div>

        <MasterDataSalesTargetForm
          v-model="form"
          :assignee-options="assignees"
          :achievement-pct="achievementPct"
          readonly
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.salesTarget.actions') }}
          </p>
          <UButton
            v-if="canManage"
            block
            size="lg"
            icon="i-lucide-pencil"
            :to="`/app/sales-target/${targetId}/edit`"
          >
            {{ t('common.edit') }}
          </UButton>
          <UButton
            v-if="canManage"
            block
            class="mt-2"
            variant="outline"
            color="error"
            icon="i-lucide-trash-2"
            @click="deleteOpen = true"
          >
            {{ t('common.delete') }}
          </UButton>
          <UButton
            block
            class="mt-2"
            variant="outline"
            color="neutral"
            to="/app/sales-target"
          >
            {{ t('common.back') }}
          </UButton>
        </UCard>
      </aside>
    </div>

    <MasterDataSalesTargetDeleteModal
      v-if="canManage"
      v-model:open="deleteOpen"
      :target-id="targetId"
      :label="assigneeName"
      @deleted="onRemoved"
    />
  </div>
</template>
