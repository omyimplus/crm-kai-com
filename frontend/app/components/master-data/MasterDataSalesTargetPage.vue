<script setup lang="ts">
import { appFormErrorClass } from '~/config/appFormUi'
import {
  defaultMasterSalesTargetFormInput,
  profileDisplayName,
  salesTargetSaveErrorMessage,
  salesTargetToFormInput,
  validateMasterSalesTargetForm
} from '~/utils/masterSalesTarget'

const props = defineProps<{
  mode: 'new' | 'edit'
  targetId?: string | null
}>()

const { t } = useI18n()
const { profile } = useProfile()
const { list: listUsers } = useSystemUsers()
const { get, create, update } = useSalesTargets()

const canManage = computed(() =>
  profile.value?.role === 'owner' || profile.value?.role === 'admin'
)

if (!canManage.value) {
  await navigateTo('/app/sales-target')
}

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterSalesTargetFormInput())
const assignees = ref<{ label: string, value: string }[]>([])

const isEdit = computed(() => props.mode === 'edit')

const pageTitle = computed(() =>
  isEdit.value ? t('masterData.salesTarget.editTitle') : t('masterData.salesTarget.newTitle')
)

try {
  const users = await listUsers()
  assignees.value = users
    .filter(u => u.is_active)
    .map(u => ({
      label: profileDisplayName(u),
      value: u.id
    }))
} catch (e) {
  console.error(e)
}

if (isEdit.value && props.targetId) {
  try {
    const row = await get(props.targetId)
    form.value = salesTargetToFormInput(row)
  } catch (e) {
    console.error(e)
    await navigateTo('/app/sales-target')
  }
}

async function save() {
  const validationKey = validateMasterSalesTargetForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.salesTarget.validation.${validationKey}`)
    return
  }

  saving.value = true
  errorMsg.value = ''
  try {
    if (isEdit.value && props.targetId) {
      await update(props.targetId, form.value)
      await navigateTo(`/app/sales-target/${props.targetId}`)
    } else {
      const row = await create(form.value)
      await navigateTo(`/app/sales-target/${row.id}`)
    }
  } catch (e: unknown) {
    errorMsg.value = salesTargetSaveErrorMessage(e, t, t('common.saveFailed'))
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div>
    <UButton
      to="/app/sales-target"
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
            {{ t('masterData.salesTarget.formSubtitle') }}
          </p>
        </div>

        <p
          v-if="errorMsg"
          :class="appFormErrorClass"
        >
          {{ errorMsg }}
        </p>

        <MasterDataSalesTargetForm
          v-model="form"
          :assignee-options="assignees"
        />
      </div>

      <aside class="mt-6 lg:sticky lg:top-6 lg:mt-0">
        <UCard class="rounded-2xl">
          <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-gray-500">
            {{ t('masterData.salesTarget.actions') }}
          </p>
          <UButton
            type="button"
            block
            size="lg"
            icon="i-lucide-check"
            :loading="saving"
            @click="save"
          >
            {{ isEdit ? t('common.save') : t('masterData.salesTarget.create') }}
          </UButton>
          <UButton
            type="button"
            block
            class="mt-2"
            variant="outline"
            color="neutral"
            to="/app/sales-target"
          >
            {{ t('common.cancel') }}
          </UButton>
        </UCard>
      </aside>
    </form>
  </div>
</template>
