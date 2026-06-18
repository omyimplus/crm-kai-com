<script setup lang="ts">
import { unitDisplayLabel, unitToFormInput } from '~/utils/masterUnit'

const props = defineProps<{
  unitId: string
}>()

const { t } = useI18n()
const { get } = useUnits()

const loading = ref(true)
const form = ref(unitToFormInput({
  id: '',
  org_id: '',
  unit_code: '',
  name: '',
  description: null,
  sort_order: 0,
  status: 'active',
  notes: null,
  created_at: ''
}))
const deleteOpen = ref(false)

try {
  const row = await get(props.unitId)
  form.value = unitToFormInput(row)
} catch (e) {
  console.error(e)
  await navigateTo('/app/unit')
} finally {
  loading.value = false
}

function onDeleted() {
  navigateTo('/app/unit')
}
</script>

<template>
  <div>
    <UButton
      to="/app/unit"
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
          {{ unitDisplayLabel(form) }}
        </h1>
        <p class="text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.unit.viewSubtitle') }}
        </p>

        <MasterDataUnitForm
          v-model="form"
          readonly
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.unit.actions') }}
          </p>
          <UButton
            block
            size="lg"
            icon="i-lucide-pencil"
            :to="`/app/unit/${unitId}/edit`"
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

    <MasterDataUnitDeleteModal
      v-model:open="deleteOpen"
      :unit-id="unitId"
      :unit-name="unitDisplayLabel(form)"
      @deleted="onDeleted"
    />
  </div>
</template>
