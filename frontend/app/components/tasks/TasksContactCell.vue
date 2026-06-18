<script setup lang="ts">
import type { Contact, Task } from '~/types/crm'
import {
  appTableCellLinkClass,
  appTableRowClass,
  appTableRowLinkClass,
  appTableTextClass
} from '~/config/appFormUi'
import { taskContactPhone } from '~/utils/masterTasks'

const props = defineProps<{
  task: Task
  contacts: Contact[]
  rowStyle?: boolean
}>()

const { t } = useI18n()

const phone = computed(() => taskContactPhone(props.task, props.contacts))
const textClass = computed(() => props.rowStyle ? appTableRowClass : appTableTextClass)
const linkClass = computed(() => props.rowStyle ? appTableRowLinkClass : appTableCellLinkClass)
</script>

<template>
  <div
    v-if="task.contact_name"
    class="min-w-0 overflow-hidden"
  >
    <div
      class="truncate text-gray-900 dark:text-gray-100"
      :class="textClass"
      :title="task.contact_name"
    >
      {{ task.contact_name }}
    </div>
    <a
      v-if="phone"
      :href="`tel:${phone}`"
      class="mt-0.5 inline-flex max-w-full truncate"
      :class="linkClass"
      :title="phone"
      @click.stop
    >
      {{ phone }}
    </a>
  </div>
  <span
    v-else
    class="text-gray-400 dark:text-gray-500"
    :class="textClass"
  >
    {{ t('tasks.emptyCell') }}
  </span>
</template>
