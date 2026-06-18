<script setup lang="ts">
import { leadSourceDisplayLabel, leadSourceToFormInput } from '~/utils/masterLeadSource'

const props = defineProps<{
  leadSourceId: string
}>()

const { t } = useI18n()
const { get } = useLeadSources()

const loading = ref(true)
const form = ref(leadSourceToFormInput({
  id: '',
  org_id: '',
  source_code: '',
  name: '',
  description: null,
  sort_order: 0,
  status: 'active',
  notes: null,
  created_at: '',
  updated_at: ''
}))
const deleteOpen = ref(false)

try {
  const row = await get(props.leadSourceId)
  form.value = leadSourceToFormInput(row)
} catch (e) {
  console.error(e)
  await navigateTo('/app/lead-source')
} finally {
  loading.value = false
}

function onDeleted() {
  navigateTo('/app/lead-source')
}
</script>

<template>
  <div>
    <UButton
      to="/app/lead-source"
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
          {{ leadSourceDisplayLabel(form) }}
        </h1>
        <p class="text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.leadSource.viewSubtitle') }}
        </p>

        <MasterDataLeadSourceForm
          v-model="form"
          readonly
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.leadSource.actions') }}
          </p>
          <UButton
            block
            size="lg"
            icon="i-lucide-pencil"
            :to="`/app/lead-source/${leadSourceId}/edit`"
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

    <MasterDataLeadSourceDeleteModal
      v-model:open="deleteOpen"
      :leadSource-id="leadSourceId"
      :leadSource-name="leadSourceDisplayLabel(form)"
      @deleted="onDeleted"
    />
  </div>
</template>
