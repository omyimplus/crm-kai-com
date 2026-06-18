<script setup lang="ts">
import {
  appTableCellLinkClass,
  appTableRowClass,
  appTableRowLinkClass,
  appTableTextClass
} from '~/config/appFormUi'

const props = defineProps<{
  companyId: string | null | undefined
  name: string | null | undefined
  rowStyle?: boolean
}>()

const emit = defineEmits<{ open: [companyId: string] }>()

const { t } = useI18n()

const textClass = computed(() => props.rowStyle ? appTableRowClass : appTableTextClass)
const linkClass = computed(() => props.rowStyle ? appTableRowLinkClass : appTableCellLinkClass)

function onClick() {
  if (!props.companyId) return
  emit('open', props.companyId)
}
</script>

<template>
  <button
    v-if="companyId && name"
    type="button"
    class="max-w-full truncate text-start focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
    :class="linkClass"
    :aria-label="t('tasks.customerInfo.openFor', { name })"
    @click.stop="onClick"
  >
    {{ name }}
  </button>
  <span
    v-else-if="name"
    class="block truncate text-gray-900 dark:text-gray-100"
    :class="textClass"
    :title="name"
  >
    {{ name }}
  </span>
  <span
    v-else
    class="text-gray-400 dark:text-gray-500"
    :class="textClass"
  >
    {{ t('tasks.emptyCell') }}
  </span>
</template>
