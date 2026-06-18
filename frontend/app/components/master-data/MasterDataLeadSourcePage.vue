<script setup lang="ts">
import { appFormErrorClass } from '~/config/appFormUi'
import {
  defaultMasterLeadSourceFormInput,
  leadSourceSaveErrorMessage,
  leadSourceToFormInput,
  validateMasterLeadSourceForm
} from '~/utils/masterLeadSource'

const props = defineProps<{
  mode: 'new' | 'edit'
  leadSourceId?: string | null
}>()

const { t } = useI18n()
const { get, create, update } = useLeadSources()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterLeadSourceFormInput())

const isEdit = computed(() => props.mode === 'edit')

const pageTitle = computed(() =>
  isEdit.value ? t('masterData.leadSource.editTitle') : t('masterData.leadSource.newTitle')
)
const pageSubtitle = computed(() =>
  isEdit.value ? t('masterData.leadSource.editSubtitle') : t('masterData.leadSource.newSubtitle')
)

if (isEdit.value && props.leadSourceId) {
  try {
    const row = await get(props.leadSourceId)
    form.value = leadSourceToFormInput(row)
  } catch (e) {
    console.error(e)
    await navigateTo('/app/lead-source')
  }
}

async function save() {
  const validationKey = validateMasterLeadSourceForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.leadSource.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    if (isEdit.value && props.leadSourceId) {
      await update(props.leadSourceId, form.value)
      await navigateTo(`/app/lead-source/${props.leadSourceId}`)
    } else {
      const row = await create(form.value)
      await navigateTo(`/app/lead-source/${row.id}`)
    }
  } catch (e: unknown) {
    errorMsg.value = leadSourceSaveErrorMessage(e, t)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div>
    <UButton
      to="/app/lead-source"
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

        <MasterDataLeadSourceForm v-model="form" />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.leadSource.actions') }}
          </p>
          <UButton
            type="button"
            block
            size="lg"
            icon="i-lucide-check"
            :loading="saving"
            @click="save"
          >
            {{ isEdit ? t('common.save') : t('masterData.leadSource.create') }}
          </UButton>
          <UButton
            type="button"
            block
            class="mt-2"
            variant="outline"
            color="neutral"
            to="/app/lead-source"
          >
            {{ t('common.cancel') }}
          </UButton>
        </UCard>
      </aside>
    </form>
  </div>
</template>
