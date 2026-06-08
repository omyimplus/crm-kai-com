<script setup lang="ts">
import type { Deal, PipelineStage } from '~/types/crm'

const props = defineProps<{
  stages: PipelineStage[]
  deals: Deal[]
}>()

const emit = defineEmits<{
  'update-stage': [dealId: string, stageId: string]
}>()

const { formatCurrency } = useFormat()
const { updateStage } = useDeals()
const draggingDealId = ref<string | null>(null)

function dealsForStage(stageId: string) {
  return props.deals.filter(d => d.stage_id === stageId)
}

function onDragStart(dealId: string) {
  draggingDealId.value = dealId
}

async function onDrop(stageId: string) {
  if (!draggingDealId.value) return
  const dealId = draggingDealId.value
  draggingDealId.value = null
  if (props.deals.find(d => d.id === dealId)?.stage_id === stageId) return
  await updateStage(dealId, stageId)
  emit('update-stage', dealId, stageId)
}
</script>

<template>
  <div class="flex gap-4 overflow-x-auto pb-4">
    <div
      v-for="stage in stages"
      :key="stage.id"
      class="min-w-[260px] flex-shrink-0 rounded-lg bg-gray-100 dark:bg-gray-900 p-3"
      @dragover.prevent
      @drop="onDrop(stage.id)"
    >
      <div class="flex items-center gap-2 mb-3">
        <span
          class="w-2 h-2 rounded-full"
          :style="{ backgroundColor: stage.color || '#94a3b8' }"
        />
        <h3 class="font-medium text-sm">
          {{ stage.name }}
        </h3>
        <UBadge
          size="xs"
          color="neutral"
          variant="subtle"
        >
          {{ dealsForStage(stage.id).length }}
        </UBadge>
      </div>
      <div class="space-y-2 min-h-[120px]">
        <div
          v-for="deal in dealsForStage(stage.id)"
          :key="deal.id"
          draggable="true"
          class="bg-white dark:bg-gray-800 rounded-md p-3 shadow-sm cursor-grab active:cursor-grabbing border border-gray-200 dark:border-gray-700"
          @dragstart="onDragStart(deal.id)"
        >
          <NuxtLink
            :to="`/app/deals/${deal.id}`"
            class="font-medium text-sm hover:underline"
            @click.stop
          >
            {{ deal.title }}
          </NuxtLink>
          <p class="text-xs text-gray-500 mt-1">
            {{ formatCurrency(Number(deal.amount), deal.currency) }}
          </p>
          <p
            v-if="deal.companies?.name"
            class="text-xs text-gray-400 mt-1 truncate"
          >
            {{ deal.companies.name }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
