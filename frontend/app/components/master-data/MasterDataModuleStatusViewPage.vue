<script setup lang="ts">
import type { ModuleStatusModuleKey } from '~/config/masterModuleStatus'
import {
  defaultMasterModuleStatusFormInput,
  isModuleStatusModuleKey,
  moduleStatusDisplayLabel,
  moduleStatusListPath,
  moduleStatusToFormInput
} from '~/utils/masterModuleStatus'

const props = defineProps<{
  moduleStatusId: string
}>()

const { t } = useI18n()
const { get } = useModuleStatuses()

const loading = ref(true)
const form = ref(defaultMasterModuleStatusFormInput())
const deleteOpen = ref(false)

try {
  const row = await get(props.moduleStatusId)
  form.value = moduleStatusToFormInput(row)
} catch (e) {
  console.error(e)
  await navigateTo('/app/module-status')
} finally {
  loading.value = false
}

const backPath = computed(() => {
  const key = form.value.module_key
  if (isModuleStatusModuleKey(key)) {
    return moduleStatusListPath(key as ModuleStatusModuleKey)
  }
  return '/app/module-status'
})

function onDeleted() {
  navigateTo(backPath.value)
}
</script>

<template>
  <div>
    <UButton
      :to="backPath"
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
          {{ moduleStatusDisplayLabel(form) }}
        </h1>
        <p class="text-sm text-gray-500 dark:text-gray-400">
          {{ t('masterData.moduleStatuses.viewSubtitle') }}
        </p>

        <MasterDataModuleStatusForm
          v-model="form"
          readonly
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.moduleStatuses.actions') }}
          </p>
          <UButton
            block
            size="lg"
            icon="i-lucide-pencil"
            :to="`/app/module-status/${moduleStatusId}/edit`"
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

    <MasterDataModuleStatusDeleteModal
      v-model:open="deleteOpen"
      :module-status-id="moduleStatusId"
      :module-status-name="moduleStatusDisplayLabel(form)"
      @deleted="onDeleted"
    />
  </div>
</template>
