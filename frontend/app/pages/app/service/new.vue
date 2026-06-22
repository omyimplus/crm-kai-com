<script setup lang="ts">
import type { Category } from '~/types/crm'
import { appFormErrorClass, appFormFieldClass, appInputUi, appSelectMenuUi } from '~/config/appFormUi'
import { SERVICE_CATEGORY_MODULE_KEY } from '~/config/masterCategory'
import { SERVICE_KINDS } from '~/config/masterService'
import {
  defaultMasterServiceFormInput,
  formToServicePayload,
  validateMasterServiceForm
} from '~/utils/masterService'
import { getSupabaseErrorMessage } from '~/utils/supabaseError'

definePageMeta({ middleware: 'auth', layout: 'app' })

const { t } = useI18n()
const { list: listCategories } = useCategories()
const { create } = useServices()

const saving = ref(false)
const errorMsg = ref('')
const form = ref(defaultMasterServiceFormInput())
const categories = ref<Category[]>([])

try {
  categories.value = await listCategories(SERVICE_CATEGORY_MODULE_KEY)
} catch (error) {
  console.error(error)
}

const categoryOptions = computed(() =>
  categories.value.map(row => ({
    label: row.name,
    value: row.id
  }))
)

const kindOptions = computed(() =>
  SERVICE_KINDS.map(value => ({
    value,
    label: t(`appMenu.service.options.kind.${value}`)
  }))
)

async function save() {
  errorMsg.value = ''
  const validationKey = validateMasterServiceForm(form.value)
  if (validationKey) {
    errorMsg.value = t(`masterData.service.validation.${validationKey}`)
    return
  }

  saving.value = true
  try {
    const row = await create(form.value)
    await navigateTo('/app/service')
  } catch (error) {
    errorMsg.value = getSupabaseErrorMessage(error, t('masterData.service.errors.saveFailed'))
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="mx-auto max-w-3xl">
    <UButton
      to="/app/service"
      variant="ghost"
      color="neutral"
      icon="i-lucide-arrow-left"
      size="sm"
      class="mb-4"
    >
      {{ t('common.back') }}
    </UButton>

    <h1 class="text-2xl font-bold font-heading">
      {{ t('appMenu.service.create') }}
    </h1>
    <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
      {{ t('appMenu.service.description') }}
    </p>

    <form
      class="mt-6 space-y-4"
      @submit.prevent="save"
    >
      <p
        v-if="errorMsg"
        :class="appFormErrorClass"
        role="alert"
      >
        {{ errorMsg }}
      </p>

      <UFormField
        :label="t('appMenu.service.fields.code')"
        required
      >
        <UInput
          v-model="form.service_code"
          :class="appFormFieldClass"
          :ui="appInputUi"
        />
      </UFormField>

      <UFormField
        :label="t('appMenu.service.fields.name')"
        required
      >
        <UInput
          v-model="form.name"
          :class="appFormFieldClass"
          :ui="appInputUi"
        />
      </UFormField>

      <UFormField :label="t('appMenu.service.fields.kind')">
        <USelectMenu
          v-model="form.service_kind"
          :items="kindOptions"
          value-key="value"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
        />
      </UFormField>

      <UFormField :label="t('masterData.category.fields.parent')">
        <USelectMenu
          v-model="form.category_id"
          :items="categoryOptions"
          value-key="value"
          :class="appFormFieldClass"
          :ui="appSelectMenuUi"
          :placeholder="t('masterData.category.fields.parentPlaceholder')"
        />
      </UFormField>

      <UFormField :label="t('appMenu.service.fields.listPrice')">
        <UInput
          v-model.number="form.list_price"
          type="number"
          min="0"
          :class="appFormFieldClass"
          :ui="appInputUi"
        />
      </UFormField>

      <UButton
        type="submit"
        color="primary"
        icon="i-lucide-check"
        :loading="saving"
      >
        {{ t('common.save') }}
      </UButton>
    </form>
  </div>
</template>
