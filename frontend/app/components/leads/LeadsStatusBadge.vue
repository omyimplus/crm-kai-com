<script setup lang="ts">
import { appTableBadgeClass } from '~/config/appFormUi'
import {
  moduleStatusAccentColor,
  moduleStatusTintStyle
} from '~/utils/masterModuleStatus'
import { useLeadStatusLabel } from '~/composables/useLeadStatusLabel'

const props = defineProps<{
  statusCode: string
  statusName?: string | null
  statusColor?: string | null
  compact?: boolean
}>()

const { leadStatusLabel } = useLeadStatusLabel()

const label = computed(() => leadStatusLabel(props.statusCode, props.statusName))
const tintStyle = computed(() => moduleStatusTintStyle(props.statusColor))
const accentColor = computed(() => moduleStatusAccentColor(props.statusColor))
</script>

<template>
  <UBadge
    variant="subtle"
    size="sm"
    :color="tintStyle ? undefined : 'neutral'"
    role="status"
    :title="label"
    :class="[
      appTableBadgeClass,
      'inline-flex max-w-full items-center gap-1.5 truncate',
      compact ? 'max-w-[6.5rem]' : 'max-w-[9rem]'
    ]"
    :style="tintStyle"
  >
    <span
      class="size-1.5 shrink-0 rounded-full ring-1 ring-black/5 dark:ring-white/10"
      :style="{ backgroundColor: accentColor }"
      aria-hidden="true"
    />
    <span class="truncate">
      {{ label }}
    </span>
  </UBadge>
</template>
