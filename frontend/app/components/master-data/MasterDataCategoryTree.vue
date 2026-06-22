<script setup lang="ts">
import type { Category } from '~/types/crm'
import type { CategoryModuleKey } from '~/config/masterCategory'
import {
  collectCategoryTreeIds,
  type CategoryTreeNode
} from '~/utils/masterCategory'

const props = defineProps<{
  nodes: CategoryTreeNode[]
  categories: Category[]
  isActiveArchive: boolean
  canRestore: boolean
  showDeletedAt?: boolean
  moduleKey?: CategoryModuleKey
}>()

const emit = defineEmits<{
  delete: [category: Category]
  restore: [category: Category]
}>()

const { t } = useI18n()

const expanded = ref<Record<string, boolean>>({})

function syncExpanded(nodes: CategoryTreeNode[]) {
  const next: Record<string, boolean> = { ...expanded.value }
  for (const id of collectCategoryTreeIds(nodes)) {
    if (next[id] === undefined) next[id] = true
  }
  expanded.value = next
}

watch(
  () => props.nodes,
  nodes => syncExpanded(nodes),
  { immediate: true, deep: true }
)

function toggleExpand(id: string) {
  expanded.value = {
    ...expanded.value,
    [id]: !expanded.value[id]
  }
}

function expandAll() {
  const next: Record<string, boolean> = {}
  for (const id of collectCategoryTreeIds(props.nodes)) {
    next[id] = true
  }
  expanded.value = next
}

function collapseAll() {
  const next: Record<string, boolean> = {}
  for (const id of collectCategoryTreeIds(props.nodes)) {
    next[id] = false
  }
  expanded.value = next
}

const levelGuide = computed(() => ([
  { key: 'client', icon: 'i-lucide-building-2' },
  { key: 'type', icon: 'i-lucide-laptop' },
  { key: 'brand', icon: 'i-lucide-award' },
  { key: 'productHint', icon: 'i-lucide-package' }
] as const))
</script>

<template>
  <div class="space-y-4">
    <div class="rounded-2xl border border-violet-200 bg-violet-50/80 px-4 py-3 dark:border-violet-900/50 dark:bg-violet-950/20">
      <p class="text-sm font-medium text-violet-950 dark:text-violet-100">
        {{ t('masterData.category.tree.guideTitle') }}
      </p>
      <div class="mt-3 flex flex-wrap gap-2">
        <div
          v-for="item in levelGuide"
          :key="item.key"
          class="inline-flex items-center gap-1.5 rounded-full border border-violet-200 bg-white/80 px-3 py-1 text-xs text-violet-900 dark:border-violet-800 dark:bg-violet-950/40 dark:text-violet-100"
        >
          <UIcon
            :name="item.icon"
            class="size-3.5 shrink-0"
          />
          {{ t(`masterData.category.tree.guide.${item.key}`) }}
        </div>
      </div>
    </div>

    <div class="flex flex-wrap items-center gap-2">
      <UButton
        size="xs"
        variant="soft"
        color="neutral"
        icon="i-lucide-unfold-vertical"
        @click="expandAll"
      >
        {{ t('masterData.category.tree.expandAll') }}
      </UButton>
      <UButton
        size="xs"
        variant="soft"
        color="neutral"
        icon="i-lucide-fold-vertical"
        @click="collapseAll"
      >
        {{ t('masterData.category.tree.collapseAll') }}
      </UButton>
    </div>

    <div
      v-if="!nodes.length"
      class="rounded-xl border border-dashed border-gray-300 px-4 py-8 text-center text-sm text-gray-500 dark:border-gray-600 dark:text-gray-400"
    >
      {{ t('masterData.category.filters.noResults') }}
    </div>

    <div
      v-else
      class="rounded-2xl border border-gray-200 p-2 dark:border-gray-800"
    >
      <MasterDataCategoryTreeNode
        v-for="node in nodes"
        :key="node.category.id"
        :node="node"
        :categories="categories"
        :depth="0"
        :expanded="expanded"
        :is-active-archive="isActiveArchive"
        :can-restore="canRestore"
        :show-deleted-at="showDeletedAt"
        :module-key="moduleKey"
        @toggle="toggleExpand"
        @delete="emit('delete', $event)"
        @restore="emit('restore', $event)"
      />
    </div>
  </div>
</template>
