<script setup lang="ts">
import type { ModuleStatusModuleKey } from '~/config/masterModuleStatus'
import { appFormErrorClass } from '~/config/appFormUi'
import {
  defaultMasterModuleStatusFormInput,
  moduleStatusListPath,
  moduleStatusModuleLabel,
  moduleStatusSaveErrorMessage,
  moduleStatusToFormInput,
  validateMasterModuleStatusForm
} from '~/utils/masterModuleStatus'

const props = defineProps<{
  mode: 'new' | 'edit'
  moduleStatusId?: string | null
  initialModuleKey?: ModuleStatusModuleKey | null
}>()

const { t } = useI18n()
const { get, create, update } = useModuleStatuses()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterModuleStatusFormInput())

const isEdit = computed(() => props.mode === 'edit')

const lockModuleKey = computed<ModuleStatusModuleKey | null>(() => {
  if (!isEdit.value && props.initialModuleKey) {
    return props.initialModuleKey
  }
  return form.value.module_key
})

const backPath = computed(() => {
  const key = lockModuleKey.value ?? form.value.module_key
  return key ? moduleStatusListPath(key) : '/app/module-status'
})

const pageTitle = computed(() => {
  if (!isEdit.value && props.initialModuleKey) {
    return t('masterData.moduleStatuses.newTitleForModule', {
      module: moduleStatusModuleLabel(props.initialModuleKey, t)
    })
  }
  return isEdit.value
    ? t('masterData.moduleStatuses.editTitle')
    : t('masterData.moduleStatuses.newTitle')
})

const pageSubtitle = computed(() =>
  isEdit.value
    ? t('masterData.moduleStatuses.editSubtitle')
    : t('masterData.moduleStatuses.newSubtitle')
)

if (!isEdit.value && props.initialModuleKey) {
  form.value = {
    ...defaultMasterModuleStatusFormInput(),
    module_key: props.initialModuleKey
  }
}

if (isEdit.value && props.moduleStatusId) {
  try {
    const row = await get(props.moduleStatusId)
    form.value = moduleStatusToFormInput(row)
  } catch (e) {
    console.error(e)
    await navigateTo('/app/module-status')
  }
}

async function save() {
  const validationKey = validateMasterModuleStatusForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.moduleStatuses.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    if (isEdit.value && props.moduleStatusId) {
      await update(props.moduleStatusId, form.value)
      await navigateTo(`/app/module-status/${props.moduleStatusId}`)
    } else {
      const row = await create(form.value)
      await navigateTo(`/app/module-status/${row.id}`)
    }
  } catch (e: unknown) {
    errorMsg.value = moduleStatusSaveErrorMessage(e, t)
  } finally {
    saving.value = false
  }
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

    <form
      class="lg:grid lg:grid-cols-[minmax(0,1fr)_17rem] lg:items-start lg:gap-6"
      @submit.prevent="save"
    >
      <div class="min-w-0 space-y-6">
        <div>
          <h1 class="text-2xl font-bold font-heading">
            {{ pageTitle }}
          </h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ pageSubtitle }}
          </p>
        </div>

        <p
          v-if="errorMsg"
          :class="appFormErrorClass"
        >
          {{ errorMsg }}
        </p>

        <MasterDataModuleStatusForm
          v-model="form"
          :lock-module-key="lockModuleKey"
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.moduleStatuses.actions') }}
          </p>
          <UButton
            type="button"
            block
            size="lg"
            icon="i-lucide-check"
            :loading="saving"
            @click="save"
          >
            {{ isEdit ? t('common.save') : t('masterData.moduleStatuses.create') }}
          </UButton>
          <UButton
            type="button"
            block
            class="mt-2"
            variant="outline"
            color="neutral"
            :to="backPath"
          >
            {{ t('common.cancel') }}
          </UButton>
        </UCard>
      </aside>
    </form>
  </div>
</template>
