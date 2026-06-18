<script setup lang="ts">
import type { JobCodeModuleKey } from '~/config/masterJobCode'
import { appFormErrorClass } from '~/config/appFormUi'
import {
  defaultMasterJobCodeFormInput,
  jobCodeModuleLabel,
  jobCodeSaveErrorMessage,
  jobCodeToFormInput,
  validateMasterJobCodeForm
} from '~/utils/masterJobCode'

const props = withDefaults(defineProps<{
  moduleKey: JobCodeModuleKey
  embedded?: boolean
}>(), {
  embedded: false
})

const emit = defineEmits<{
  saved: [moduleKey: JobCodeModuleKey]
}>()

const { t } = useI18n()
const { getByModule, create, update } = useJobCodes()

const loading = ref(true)
const saving = ref(false)
const errorMsg = ref('')
const sequenceId = ref<string | null>(null)
const form = ref(defaultMasterJobCodeFormInput(props.moduleKey))

const isEdit = computed(() => Boolean(sequenceId.value))

const pageTitle = computed(() =>
  t('masterData.jobCode.moduleTitle', {
    module: jobCodeModuleLabel(props.moduleKey, t)
  })
)

async function loadModule(key: JobCodeModuleKey) {
  loading.value = true
  errorMsg.value = ''
  sequenceId.value = null
  form.value = defaultMasterJobCodeFormInput(key)
  try {
    const row = await getByModule(key)
    if (row) {
      sequenceId.value = row.id
      form.value = jobCodeToFormInput(row)
    }
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

watch(() => props.moduleKey, loadModule, { immediate: true })

async function save() {
  const validationKey = validateMasterJobCodeForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.jobCode.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    if (sequenceId.value) {
      await update(sequenceId.value, form.value)
    } else {
      const row = await create(form.value)
      sequenceId.value = row.id
      form.value = jobCodeToFormInput(row)
    }
    emit('saved', props.moduleKey)
  } catch (e: unknown) {
    errorMsg.value = jobCodeSaveErrorMessage(e, t)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div>
    <UButton
      v-if="!embedded"
      to="/app/job-code"
      variant="ghost"
      color="neutral"
      icon="i-lucide-arrow-left"
      size="sm"
      class="mb-4"
    >
      {{ t('masterData.jobCode.backToModules') }}
    </UButton>

    <UCard v-if="loading">
      <p class="text-gray-500">
        {{ t('common.loading') }}
      </p>
    </UCard>

    <form
      v-else
      class="lg:grid lg:grid-cols-[minmax(0,1fr)_17rem] lg:items-start lg:gap-6"
      @submit.prevent="save"
    >
      <div class="min-w-0 space-y-6">
        <div v-if="!embedded">
          <h1 class="text-2xl font-bold font-heading">
            {{ pageTitle }}
          </h1>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ t('masterData.jobCode.moduleSubtitle') }}
          </p>
        </div>
        <div v-else>
          <h2 class="text-lg font-semibold font-heading">
            {{ pageTitle }}
          </h2>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ t('masterData.jobCode.moduleSubtitle') }}
          </p>
        </div>

        <p
          v-if="errorMsg"
          :class="appFormErrorClass"
        >
          {{ errorMsg }}
        </p>

        <MasterDataJobCodeForm
          v-model="form"
          :lock-module-key="moduleKey"
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.jobCode.actions') }}
          </p>
          <UButton
            type="button"
            block
            size="lg"
            icon="i-lucide-check"
            :loading="saving"
            @click="save"
          >
            {{ isEdit ? t('common.save') : t('masterData.jobCode.create') }}
          </UButton>
        </UCard>
      </aside>
    </form>
  </div>
</template>
