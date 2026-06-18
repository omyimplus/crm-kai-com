<script setup lang="ts">
import type { ArchiveTab } from '~/composables/useArchiveTabs'
import {
  appTableRoleTabActiveClass,
  appTableRoleTabBaseClass,
  appTableRoleTabInactiveClass,
  appTableTextClass
} from '~/config/appFormUi'

const archiveTab = defineModel<ArchiveTab>('archiveTab', { required: true })

defineProps<{
  canViewDeleted: boolean
  activeLabel: string
  deletedLabel: string
  ariaLabel: string
}>()
</script>

<template>
  <div
    v-if="canViewDeleted"
    class="mb-4 flex flex-wrap gap-2"
    role="tablist"
    :aria-label="ariaLabel"
  >
    <button
      type="button"
      role="tab"
      :aria-selected="archiveTab === 'active'"
      :class="[
        appTableRoleTabBaseClass,
        appTableTextClass,
        archiveTab === 'active' ? appTableRoleTabActiveClass : appTableRoleTabInactiveClass
      ]"
      @click="archiveTab = 'active'"
    >
      {{ activeLabel }}
    </button>
    <button
      type="button"
      role="tab"
      :aria-selected="archiveTab === 'deleted'"
      :class="[
        appTableRoleTabBaseClass,
        appTableTextClass,
        archiveTab === 'deleted' ? appTableRoleTabActiveClass : appTableRoleTabInactiveClass
      ]"
      @click="archiveTab = 'deleted'"
    >
      {{ deletedLabel }}
    </button>
  </div>
</template>
