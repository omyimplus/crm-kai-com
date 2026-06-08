<script setup lang="ts">
import type { Deal, PipelineStage } from '~/types/crm'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { ensureProfile } = useProfile()
const { list, getDefaultPipeline } = useDeals()

await ensureProfile()

const deals = ref<Deal[]>([])
const stages = ref<PipelineStage[]>([])
const loading = ref(true)
const showNew = ref(false)

async function refresh() {
  loading.value = true
  const [{ stages: s }, d] = await Promise.all([getDefaultPipeline(), list()])
  stages.value = s
  deals.value = d
  loading.value = false
}

await refresh()

async function onStageUpdate() {
  await refresh()
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 class="text-2xl font-bold">
        {{ t('deals.title') }}
      </h1>
      <UButton
        icon="i-lucide-plus"
        @click="showNew = true"
      >
        {{ t('deals.new') }}
      </UButton>
    </div>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <CrmDealKanban
      v-else
      :stages="stages"
      :deals="deals"
      @update-stage="onStageUpdate"
    />

    <CrmDealFormModal
      v-model:open="showNew"
      :stages="stages"
      @saved="refresh"
    />
  </div>
</template>
