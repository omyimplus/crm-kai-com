<script setup lang="ts">
import { moduleStatusTintStyle } from '~/utils/masterModuleStatus'

const props = defineProps<{
  stageName: string
  stageColor?: string | null
  probability?: number | null
}>()

const { pipelineStageLabel } = usePipelineStageLabel()

const displayName = computed(() => pipelineStageLabel(props.stageName))
</script>

<template>
  <UBadge
    variant="subtle"
    color="neutral"
    class="inline-flex max-w-full items-center gap-1.5 font-normal"
  >
    <span
      class="size-2 shrink-0 rounded-full"
      :style="moduleStatusTintStyle(stageColor)"
    />
    <span class="truncate">
      {{ displayName }}
      <template v-if="probability != null">
        ({{ probability }}%)
      </template>
    </span>
  </UBadge>
</template>
