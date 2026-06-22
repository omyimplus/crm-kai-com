<script setup lang="ts">
import type { Category } from '~/types/crm'
import type { CategoryTreeNode } from '~/utils/masterCategory'
import { categoryLevelKey } from '~/utils/masterCategory'
import type { CategoryModuleKey } from '~/config/masterCategory'
import { SERVICE_CATEGORY_MODULE_KEY } from '~/config/masterCategory'

const props = defineProps<{
  node: CategoryTreeNode
  categories: Category[]
  depth: number
  expanded: Record<string, boolean>
  isActiveArchive: boolean
  canRestore: boolean
  showDeletedAt?: boolean
  parentDeleted?: boolean
  moduleKey?: CategoryModuleKey
}>()

const emit = defineEmits<{
  toggle: [id: string]
  delete: [category: Category]
  restore: [category: Category]
}>()

const { t } = useI18n()
const { formatDateTime } = useFormat()

const category = computed(() => props.node.category)
const hasChildren = computed(() => props.node.children.length > 0)
const isExpanded = computed(() => props.expanded[category.value.id] ?? true)
const levelKey = computed(() => {
  if (props.moduleKey === SERVICE_CATEGORY_MODULE_KEY) {
    if (props.depth <= 0) return 'serviceRoot'
    if (props.depth === 1) return 'serviceMid'
    return 'serviceLeaf'
  }
  return categoryLevelKey(props.depth)
})
const levelLabel = computed(() => t(`masterData.category.levels.${levelKey.value}`))

function childParentDeleted(child: CategoryTreeNode) {
  if (!child.category.parent_id) return false
  const parent = props.categories.find(row => row.id === child.category.parent_id)
  return Boolean(parent?.deleted_at)
}
</script>

<template>
  <div>
    <div
      class="group flex flex-wrap items-center gap-2 rounded-xl border border-transparent px-2 py-2 hover:border-gray-200 hover:bg-gray-50/80 dark:hover:border-gray-800 dark:hover:bg-gray-900/40"
      :style="{ paddingInlineStart: `${depth * 1.25 + 0.5}rem` }"
    >
      <button
        type="button"
        class="flex size-7 shrink-0 items-center justify-center rounded-md text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-800"
        :class="hasChildren ? 'visible' : 'invisible'"
        :aria-label="isExpanded ? t('masterData.category.tree.collapse') : t('masterData.category.tree.expand')"
        @click="emit('toggle', category.id)"
      >
        <UIcon
          :name="isExpanded ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right'"
          class="size-4"
        />
      </button>

      <div
        class="flex size-9 shrink-0 items-center justify-center overflow-hidden rounded-lg border border-gray-200 bg-gray-50 dark:border-gray-700 dark:bg-gray-800/50"
      >
        <img
          v-if="category.image_url"
          :src="category.image_url"
          :alt="category.name"
          class="h-full w-full object-cover"
        >
        <UIcon
          v-else
          name="i-lucide-tags"
          class="size-4 text-gray-400"
        />
      </div>

      <div class="min-w-0 flex-1">
        <div class="flex flex-wrap items-center gap-2">
          <UBadge
            color="primary"
            variant="subtle"
            size="xs"
          >
            {{ levelLabel }}
          </UBadge>
          <span
            v-if="category.color && isActiveArchive"
            class="inline-block size-2.5 shrink-0 rounded-full"
            :style="{ backgroundColor: category.color }"
          />
          <NuxtLink
            v-if="isActiveArchive"
            :to="`/app/category/${category.id}`"
            class="font-semibold text-gray-900 hover:text-primary dark:text-gray-100"
          >
            {{ category.name }}
          </NuxtLink>
          <span
            v-else
            class="font-semibold text-gray-900 dark:text-gray-100"
          >
            {{ category.name }}
          </span>
          <span class="text-xs text-gray-500 dark:text-gray-400">
            {{ category.category_code }}
          </span>
          <UBadge
            v-if="isActiveArchive"
            :color="category.status === 'active' ? 'success' : 'neutral'"
            variant="subtle"
            size="xs"
          >
            {{ t(`masterData.category.options.status.${category.status}`) }}
          </UBadge>
          <UBadge
            v-if="parentDeleted"
            color="warning"
            variant="subtle"
            size="xs"
          >
            {{ t('masterData.category.filters.parentDeletedBadge') }}
          </UBadge>
        </div>
        <p
          v-if="showDeletedAt && category.deleted_at"
          class="mt-0.5 text-xs text-gray-500 dark:text-gray-400"
        >
          {{ t('masterData.category.filters.deletedAt') }}: {{ formatDateTime(category.deleted_at) }}
        </p>
      </div>

      <div class="flex shrink-0 items-center gap-1 opacity-100 sm:opacity-0 sm:group-hover:opacity-100 sm:focus-within:opacity-100">
        <template v-if="isActiveArchive">
          <AppIconButton
            icon="i-lucide-plus"
            color="primary"
            :aria-label="t('masterData.category.tree.addChild')"
            :to="`/app/category/new?parentId=${category.id}&moduleKey=${moduleKey ?? category.module_key}`"
          />
          <AppIconButton
            icon="i-lucide-eye"
            :aria-label="t('masterData.category.view')"
            :to="`/app/category/${category.id}`"
          />
          <AppIconButton
            icon="i-lucide-pencil"
            :aria-label="t('common.edit')"
            :to="`/app/category/${category.id}/edit`"
          />
          <AppIconButton
            icon="i-lucide-trash-2"
            color="error"
            :aria-label="t('common.delete')"
            @click="emit('delete', category)"
          />
        </template>
        <AppIconButton
          v-else-if="canRestore"
          icon="i-lucide-rotate-ccw"
          color="primary"
          :aria-label="t('common.restore')"
          @click="emit('restore', category)"
        />
      </div>
    </div>

    <div v-if="hasChildren && isExpanded">
      <MasterDataCategoryTreeNode
        v-for="child in node.children"
        :key="child.category.id"
        :node="child"
        :categories="categories"
        :depth="depth + 1"
        :expanded="expanded"
        :is-active-archive="isActiveArchive"
        :can-restore="canRestore"
        :show-deleted-at="showDeletedAt"
        :parent-deleted="childParentDeleted(child)"
        :module-key="moduleKey"
        @toggle="emit('toggle', $event)"
        @delete="emit('delete', $event)"
        @restore="emit('restore', $event)"
      />
    </div>
  </div>
</template>
