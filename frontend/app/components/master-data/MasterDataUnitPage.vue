<script setup lang="ts">
import { appFormErrorClass } from '~/config/appFormUi'
import {
  defaultMasterUnitFormInput,
  unitSaveErrorMessage,
  unitToFormInput,
  validateMasterUnitForm
} from '~/utils/masterUnit'

const props = defineProps<{
  mode: 'new' | 'edit'
  unitId?: string | null
}>()

const { t } = useI18n()
const { get, create, update } = useUnits()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterUnitFormInput())

const isEdit = computed(() => props.mode === 'edit')

const pageTitle = computed(() =>
  isEdit.value ? t('masterData.unit.editTitle') : t('masterData.unit.newTitle')
)
const pageSubtitle = computed(() =>
  isEdit.value ? t('masterData.unit.editSubtitle') : t('masterData.unit.newSubtitle')
)

if (isEdit.value && props.unitId) {
  try {
    const row = await get(props.unitId)
    form.value = unitToFormInput(row)
  } catch (e) {
    console.error(e)
    await navigateTo('/app/unit')
  }
}

async function save() {
  const validationKey = validateMasterUnitForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.unit.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    if (isEdit.value && props.unitId) {
      await update(props.unitId, form.value)
      await navigateTo(`/app/unit/${props.unitId}`)
    } else {
      const row = await create(form.value)
      await navigateTo(`/app/unit/${row.id}`)
    }
  } catch (e: unknown) {
    errorMsg.value = unitSaveErrorMessage(e, t)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div>
    <UButton
      to="/app/unit"
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

        <MasterDataUnitForm v-model="form" />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.unit.actions') }}
          </p>
          <UButton
            type="button"
            block
            size="lg"
            icon="i-lucide-check"
            :loading="saving"
            @click="save"
          >
            {{ isEdit ? t('common.save') : t('masterData.unit.create') }}
          </UButton>
          <UButton
            type="button"
            block
            class="mt-2"
            variant="outline"
            color="neutral"
            to="/app/unit"
          >
            {{ t('common.cancel') }}
          </UButton>
        </UCard>
      </aside>
    </form>
  </div>
</template>
